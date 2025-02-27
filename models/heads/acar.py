import math

import torch
import torch.nn as nn
import torchvision

__all__ = ["acar"]


class HR2O_NL(nn.Module):
    def __init__(self, hidden_dim=512, kernel_size=3):
        super().__init__()

        self.hidden_dim = hidden_dim

        padding = kernel_size // 2
        self.conv_q = nn.Conv2d(hidden_dim, hidden_dim, kernel_size, padding=padding, bias=False)
        self.conv_k = nn.Conv2d(hidden_dim, hidden_dim, kernel_size, padding=padding, bias=False)
        self.conv_v = nn.Conv2d(hidden_dim, hidden_dim, kernel_size, padding=padding, bias=False)

        self.conv = nn.Conv2d(hidden_dim, hidden_dim, kernel_size, padding=padding, bias=False)
        self.norm = nn.GroupNorm(1, hidden_dim, affine=True)
        self.dp = nn.Dropout(0.2)

    def forward(self, x):
        query = self.conv_q(x).unsqueeze(1)
        key = self.conv_k(x).unsqueeze(0)
        att = (query * key).sum(2) / (self.hidden_dim ** 0.5)
        att = nn.Softmax(dim=1)(att)
        value = self.conv_v(x)
        virt_feats = (att.unsqueeze(2) * value).sum(1)

        virt_feats = self.norm(virt_feats)
        virt_feats = nn.functional.relu(virt_feats)
        virt_feats = self.conv(virt_feats)
        virt_feats = self.dp(virt_feats)

        x = x + virt_feats
        return x


class ACARHead(nn.Module):
    def __init__(
        self,
        width,
        roi_spatial=7,
        num_classes=60,
        dropout=0.0,
        bias=False,
        reduce_dim=1024,
        hidden_dim=512,
        downsample="max2x2",
        depth=2,
        kernel_size=3,
    ):
        super().__init__()

        self.roi_spatial = roi_spatial
        self.roi_maxpool = nn.MaxPool2d(roi_spatial)

        # actor-context feature encoder
        self.conv_reduce = nn.Conv2d(width, reduce_dim, 1, bias=False)

        self.conv1 = nn.Conv2d(reduce_dim * 2, hidden_dim, 1, bias=False)
        self.conv2 = nn.Conv2d(hidden_dim, hidden_dim, 3, bias=False)

        # down-sampling before HR2O
        assert downsample in ["none", "max2x2"]
        if downsample == "none":
            self.downsample = nn.Identity()
        elif downsample == "max2x2":
            self.downsample = nn.MaxPool2d(kernel_size=3, stride=2, padding=1)

        # high-order relation reasoning operator (HR2O_NL)
        layers = []
        for _ in range(depth):
            layers.append(HR2O_NL(hidden_dim, kernel_size))
        self.hr2o = nn.Sequential(*layers)

        # classification
        self.gap = nn.AdaptiveAvgPool2d(1)
        self.fc1 = nn.Linear(reduce_dim, hidden_dim, bias=False)
        self.fc2 = nn.Linear(hidden_dim * 2, num_classes, bias=bias)

        if dropout > 0:
            self.dp = nn.Dropout(dropout)
        else:
            self.dp = None

    # data: features, rois, num_rois, roi_ids, sizes_before_padding
    # returns: outputs
    def forward(self, data):
        if not isinstance(data["features"], list):
            feats = [data["features"]]
        else:
            feats = data["features"]

        # temporal average pooling
        h, w = feats[0].shape[3:]
        # requires all features have the same spatial dimensions
        feats = [nn.AdaptiveAvgPool3d((1, h, w))(f).view(-1, f.shape[1], h, w) for f in feats]
        feats = torch.cat(feats, dim=1)

        feats = self.conv_reduce(feats)

        rois = data["rois"]
        rois[:, 1] = rois[:, 1] * w
        rois[:, 2] = rois[:, 2] * h
        rois[:, 3] = rois[:, 3] * w
        rois[:, 4] = rois[:, 4] * h
        rois = rois.detach()
        roi_feats = torchvision.ops.roi_align(feats, rois, (self.roi_spatial, self.roi_spatial))
        roi_feats = self.roi_maxpool(roi_feats).view(data["num_rois"], -1)

        roi_ids = data["roi_ids"]
        sizes_before_padding = data["sizes_before_padding"]
        high_order_feats = []
        for idx in range(feats.shape[0]):  # iterate over mini-batch
            n_rois = roi_ids[idx + 1] - roi_ids[idx]
            if n_rois == 0:
                continue

            eff_h, eff_w = math.ceil(h * sizes_before_padding[idx][1]), math.ceil(w * sizes_before_padding[idx][0])
            bg_feats = feats[idx][:, :eff_h, :eff_w]
            bg_feats = bg_feats.unsqueeze(0).repeat((n_rois, 1, 1, 1))
            actor_feats = roi_feats[roi_ids[idx] : roi_ids[idx + 1]]
            tiled_actor_feats = actor_feats.unsqueeze(2).unsqueeze(2).expand_as(bg_feats)
            interact_feats = torch.cat([bg_feats, tiled_actor_feats], dim=1)

            interact_feats = self.conv1(interact_feats)
            interact_feats = nn.functional.relu(interact_feats)
            interact_feats = self.conv2(interact_feats)
            interact_feats = nn.functional.relu(interact_feats)

            interact_feats = self.downsample(interact_feats)

            interact_feats = self.hr2o(interact_feats)
            interact_feats = self.gap(interact_feats)
            high_order_feats.append(interact_feats)

        high_order_feats = torch.cat(high_order_feats, dim=0).view(data["num_rois"], -1)

        outputs = self.fc1(roi_feats)
        outputs = nn.functional.relu(outputs)
        outputs = torch.cat([outputs, high_order_feats], dim=1)

        if self.dp is not None:
            outputs = self.dp(outputs)
        outputs = self.fc2(outputs)

        return {"outputs": outputs}


def acar(**kwargs):
    model = ACARHead(**kwargs)
    return model

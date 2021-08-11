import torch.nn as nn

from .acar import *
from .linear import *


def model_entry(config):
    return globals()[config["type"]](**config["kwargs"])


class AVA_head(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.module = model_entry(config)

    def forward(self, data):
        return self.module(data)

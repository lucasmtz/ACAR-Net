# Annotations

Annotation files in this folder should include [official AVA v2.2 annotations](https://research.google.com/ava/download.html#ava_actions_download), and our annotations listed in the table below. All our annotations are provided in the Google drive folder [`annotations`](https://drive.google.com/drive/folders/1h9ccKEF8hkS6MUCKNY1kwG-906eeTgFv?usp=sharing).

Name | Dataset | Split | Ground Truth | Detection
--- | :---: | :---: | :---: | :---:
[`ava_train_v2.2.pkl`](https://drive.google.com/file/d/1teKrNNnErHPsnORJNJCZaA_U_q0tor93/view?usp=sharing) | AVA v2.2 | train | YES | None
[`ava_train_v2.2_with_fair_0.9.pkl`](https://drive.google.com/file/d/1JcHn6S8KTvOI6igbpwnU5Yf_KnSdz2x_/view?usp=sharing) | AVA v2.2 | train | YES | [LFB](https://github.com/facebookresearch/video-long-term-feature-banks/blob/master/GETTING_STARTED.md#ava-person-detector)
[`ava_val_v2.2_gt.pkl`](https://drive.google.com/file/d/1aVUTot9N1zp6zsKiwjNx3ZxfTQPU8krg/view?usp=sharing) | AVA v2.2 | val | YES | None
[`ava_val_v2.2_fair_0.85.pkl`](https://drive.google.com/file/d/1HLg6tMIBv81vQrgrrAOpE2tSAuSBqjNC/view?usp=sharing) | AVA v2.2 | val | NO | [LFB](https://github.com/facebookresearch/video-long-term-feature-banks/blob/master/GETTING_STARTED.md#ava-person-detector)


The final structure should be as the following:
```
annotations
|_ [official AVA v2.2 annotation files]
|_ ava_train_v2.2.pkl
|_ ava_train_v2.2_with_fair_0.9.pkl
|_ ava_val_v2.2_fair_0.85.pkl
|_ ava_val_v2.2_gt.pkl
```

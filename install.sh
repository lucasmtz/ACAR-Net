#!/bin/bash

# Create enviroment
conda create -y --prefix ./env python=3.9
conda activate ./env
conda install -y --file requirements.txt
conda install -y -c conda-forge pre-commit easydict tensorboardx ffmpeg gdown
conda install -y pytorch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 cudatoolkit=10.1 -c pytorch


# Download pre-trained model
MODEL="SLOWFAST_R50_K400.pth.tar"
GDRIVE_ID="1kQO_dnM9JjV3sBtvowXqQa6d0xcxn5rs"

if [[ ! -f "pretrained/${MODEL}" ]]; then
    gdown --id ${GDRIVE_ID} --output "pretrained/${MODEL}"
fi


# Download AVA
DATA_DIR="data/ava/videos"

if [[ ! -d "${DATA_DIR}" ]]; then
    echo "${DATA_DIR} doesn't exist. Creating it.";
    mkdir -p ${DATA_DIR}
fi

wget -nc https://s3.amazonaws.com/ava-dataset/annotations/ava_file_names_trainval_v2.1.txt -P data/

awk '{print "https://s3.amazonaws.com/ava-dataset/trainval/" $0}' data/ava_file_names_trainval_v2.1.txt | \
    xargs -n 15 -P 20 wget -q -R "index.html*" -nc -P ${DATA_DIR} https://s3.amazonaws.com/ava-dataset/trainval/

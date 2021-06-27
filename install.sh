#!/bin/bash

# Create enviroment
conda create -y --prefix ./env python=3.9
conda activate ./env
conda install -y --file requirements.txt
conda install -y -c conda-forge pre-commit easydict tensorboardx ffmpeg gdown
conda install -y pytorch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 cudatoolkit=10.1 -c pytorch


# Download annotations
ANNOT_DIR="annotations"

if [[ ! -d "${ANNOT_DIR}" ]]; then
    echo "${ANNOT_DIR} doesn't exist. Creating it.";
    mkdir -p ${ANNOT_DIR}
fi

wget https://storage.googleapis.com/deepmind-media/Datasets/ava_kinetics_v1_0.tar.gz -P ${ANNOT_DIR}
tar -xzvf ${ANNOT_DIR}/ava_kinetics_v1_0.tar.gz -C ${ANNOT_DIR}
rm ${ANNOT_DIR}/ava_kinetics_v1_0.tar.gz

gdown --id 1teKrNNnErHPsnORJNJCZaA_U_q0tor93 --output "${ANNOT_DIR}/ava_train_v2.2.pkl"
gdown --id 1JcHn6S8KTvOI6igbpwnU5Yf_KnSdz2x_ --output "${ANNOT_DIR}/ava_train_v2.2_with_fair_0.9.pkl"
gdown --id 1aVUTot9N1zp6zsKiwjNx3ZxfTQPU8krg --output "${ANNOT_DIR}/ava_val_v2.2_gt.pkl"
gdown --id 1HLg6tMIBv81vQrgrrAOpE2tSAuSBqjNC --output "${ANNOT_DIR}/ava_val_v2.2_fair_0.85.pkl"


# Download pre-trained model
PRETRAINED_DIR="pretrained"
MODEL="SLOWFAST_R50_K400.pth.tar"
GDRIVE_ID="1kQO_dnM9JjV3sBtvowXqQa6d0xcxn5rs"

if [[ ! -f "${PRETRAINED_DIR}/${MODEL}" ]]; then
    gdown --id ${GDRIVE_ID} --output "${PRETRAINED_DIR}/${MODEL}"
fi


# Download AVA
DATA_DIR="data"
AVA_DIR="${DATA_DIR}/ava/videos"

if [[ ! -d "${AVA_DIR}" ]]; then
    echo "${AVA_DIR} doesn't exist. Creating it.";
    mkdir -p ${AVA_DIR}
fi

wget -nc https://s3.amazonaws.com/ava-dataset/annotations/ava_file_names_trainval_v2.1.txt -P ${DATA_DIR}

awk '{print "https://s3.amazonaws.com/ava-dataset/trainval/" $0}' "data/ava_file_names_trainval_v2.1.txt" | \
    xargs -n 34 -P 9 wget -R "index.html*" -nc -P ${AVA_DIR}

# Download Kinetics
KINETICS_DIR="${DATA_DIR}/kinetics/videos"

if [[ ! -d "${KINETICS_DIR}" ]]; then
    echo "${KINETICS_DIR} doesn't exist. Creating it.";
    mkdir -p ${KINETICS_DIR}
fi

wget -nc https://s3.amazonaws.com/kinetics/700_2020/train/k700_2020_train_path.txt -P ${DATA_DIR}
wget -nc https://s3.amazonaws.com/kinetics/700_2020/val/k700_2020_val_path.txt -P ${DATA_DIR}
wget -nc https://s3.amazonaws.com/kinetics/700_2020/test/k700_2020_test_path.txt -P ${DATA_DIR}

cat "${DATA_DIR}/k700_2020_train_path.txt" | xargs -n 80 -P 9 wget -q -R "index.html*" -nc -P "${DATA_DIR}/tmp"
cat "${DATA_DIR}/k700_2020_val_path.txt" | xargs -n 80 -P 9 wget -q -R "index.html*" -nc -P "${DATA_DIR}/tmp"
cat "${DATA_DIR}/k700_2020_test_path.txt" | xargs -n 6 -P 9 wget -q -R "index.html*" -nc -P "${DATA_DIR}/tmp"

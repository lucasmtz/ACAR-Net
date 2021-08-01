#!/bin/bash

# ---------------------------------------------------------------------------------------------------------------------
# Create enviroment
# ---------------------------------------------------------------------------------------------------------------------
SECONDS=0

conda create -y --prefix ./env python=3.9
conda activate ./env
conda install -y --file requirements.txt
conda install -y -c conda-forge pre-commit easydict tensorboardx ffmpeg gdown types-pyyaml
conda install -y pytorch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 cudatoolkit=10.1 -c pytorch

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo '1) Create enviroment time '$ELAPSED >> time_log.txt

# ---------------------------------------------------------------------------------------------------------------------
# Download annotations
# ---------------------------------------------------------------------------------------------------------------------
SECONDS=0

ANNOT_DIR="annotations"

if [[ ! -d "${ANNOT_DIR}" ]]; then
    echo "${ANNOT_DIR} doesn't exist. Creating it.";
    mkdir -p ${ANNOT_DIR}
fi

wget https://storage.googleapis.com/deepmind-media/Datasets/ava_kinetics_v1_0.tar.gz -P ${ANNOT_DIR}
tar -C ${ANNOT_DIR} -xzvf ${ANNOT_DIR}/ava_kinetics_v1_0.tar.gz
rm ${ANNOT_DIR}/ava_kinetics_v1_0.tar.gz

gdown --id 1teKrNNnErHPsnORJNJCZaA_U_q0tor93 --output "${ANNOT_DIR}/ava_train_v2.2.pkl"
gdown --id 1JcHn6S8KTvOI6igbpwnU5Yf_KnSdz2x_ --output "${ANNOT_DIR}/ava_train_v2.2_with_fair_0.9.pkl"
gdown --id 1aVUTot9N1zp6zsKiwjNx3ZxfTQPU8krg --output "${ANNOT_DIR}/ava_val_v2.2_gt.pkl"
gdown --id 1HLg6tMIBv81vQrgrrAOpE2tSAuSBqjNC --output "${ANNOT_DIR}/ava_val_v2.2_fair_0.85.pkl"

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo '2) Download annotations time '$ELAPSED >> time_log.txt

# ---------------------------------------------------------------------------------------------------------------------
# Download pre-trained model
# ---------------------------------------------------------------------------------------------------------------------
SECONDS=0

PRETRAINED_DIR="pretrained"
MODEL="SLOWFAST_R50_K400.pth.tar"
GDRIVE_ID="1kQO_dnM9JjV3sBtvowXqQa6d0xcxn5rs"

if [[ ! -f "${PRETRAINED_DIR}/${MODEL}" ]]; then
    gdown --id ${GDRIVE_ID} --output "${PRETRAINED_DIR}/${MODEL}"
fi

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo '3) Download pre-trained model time '$ELAPSED >> time_log.txt

# ---------------------------------------------------------------------------------------------------------------------
# Download AVA
# ---------------------------------------------------------------------------------------------------------------------
SECONDS=0

DATA_DIR="data"
AVA_DIR="${DATA_DIR}/ava/videos"

if [[ ! -d "${AVA_DIR}" ]]; then
    echo "${AVA_DIR} doesn't exist. Creating it.";
    mkdir -p ${AVA_DIR}
fi

wget -nc https://s3.amazonaws.com/ava-dataset/annotations/ava_file_names_trainval_v2.1.txt -P ${DATA_DIR}

awk '{print "https://s3.amazonaws.com/ava-dataset/trainval/" $0}' "data/ava_file_names_trainval_v2.1.txt" | \
    xargs -n 34 -P 9 wget --reject-regex "index.html*" -nc -P ${AVA_DIR}

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo '4) Download AVA time '$ELAPSED >> time_log.txt

# ---------------------------------------------------------------------------------------------------------------------
# Download Kinetics
# ---------------------------------------------------------------------------------------------------------------------
SECONDS=0

KINETICS_DIR="${DATA_DIR}/kinetics/videos"

if [[ ! -d "${KINETICS_DIR}" ]]; then
    echo "${KINETICS_DIR} doesn't exist. Creating it.";
    mkdir -p ${KINETICS_DIR}
fi

wget -nc https://s3.amazonaws.com/kinetics/700_2020/train/k700_2020_train_path.txt -P ${DATA_DIR}
wget -nc https://s3.amazonaws.com/kinetics/700_2020/val/k700_2020_val_path.txt -P ${DATA_DIR}
wget -nc https://s3.amazonaws.com/kinetics/700_2020/test/k700_2020_test_path.txt -P ${DATA_DIR}

cat "${DATA_DIR}/k700_2020_train_path.txt" | xargs -n 80 -P 9 wget -q --reject-regex "index.html*" -nc -P "${DATA_DIR}/tmp"
cat "${DATA_DIR}/k700_2020_val_path.txt" | xargs -n 80 -P 9 wget -q --reject-regex "index.html*" -nc -P "${DATA_DIR}/tmp"
cat "${DATA_DIR}/k700_2020_test_path.txt" | xargs -n 6 -P 9 wget --reject-regex "index.html*" -nc -P "${DATA_DIR}/tmp"

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo '5) Download Kinetics time '$ELAPSED >> time_log.txt

# ---------------------------------------------------------------------------------------------------------------------
# Untar Kinetics
# ---------------------------------------------------------------------------------------------------------------------

# tar -tvf data/tmp/k700_test_050.tar.gz > test.txt ## save files in tar to list
# get last column as list and filter this list with files in cat ${ANNOT_DIR}/ava_kinetics_v1_0/kinetics_test_v1.0.csv |  awk -F "," '{print $1}'

# use this final list in --files-from param of tar when extracting


# pat_test="$(cat ${ANNOT_DIR}/ava_kinetics_v1_0/kinetics_test_v1.0.csv |  awk -F"," '{print $1 "*"}')"
# ls ${DATA_DIR}/tmp/*_test_* -1 | xargs -n 1 -P 15 tar -C ${KINETICS_DIR} -xzkf



# tar -tvf data/tmp/k700_test_007.tar.gz | awk '{print $NF}' > file1
# cat ${ANNOT_DIR}/ava_kinetics_v1_0/kinetics_test_v1.0.csv |  awk -F "," '{print $1}' > file2
# Update the Apt repository cache 
sudo apt -y update && sudo apt -y upgrade && sudo apt -y autoremove
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y autoremove

# ---------------------------------------------------------------------------------------------------------------------
# CUDA SETUP
# ---------------------------------------------------------------------------------------------------------------------

# Install Third-party Libraries
sudo apt-get install g++ freeglut3-dev build-essential libx11-dev \
    libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev

# Install latest nvidia driver
sudo ubuntu-drivers install

# Install kernel headers and development packages for the currently running kernel 
sudo apt-get install linux-headers-$(uname -r)

# Download latest CUDA toolkit from https://developer.nvidia.com/cuda-downloads
wget https://developer.download.nvidia.com/compute/cuda/11.4.1/local_installers/cuda_11.4.1_470.57.02_linux.run
# Install the .run file. DO NOT check the option of installing the driver.
sudo sh cuda_11.4.1_470.57.02_linux.run

# Environment Setup
echo 'export PATH=/usr/local/cuda-11.4/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.4/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
echo 'export CUDA_HOME=/usr/local/cuda' >> ~/.bashrc

# Optional steps
/usr/bin/nvidia-persistenced --verbose
# Check driver version
cat /proc/driver/nvidia/version
# Check CUDA toolkit version
nvcc -V

# Run samples
# Install Writable Samples
cuda-install-samples-11.4.sh .
# Compile them
cd ~/NVIDIA_CUDA-11.4_Samples
make
# Test 
sudo ~/NVIDIA_CUDA-11.4_Samples/bin/x86_64/linux/release/deviceQuery
sudo ~/NVIDIA_CUDA-11.4_Samples/bin/x86_64/linux/release/bandwidthTest

# ---------------------------------------------------------------------------------------------------------------------
# Install miniconda
# ---------------------------------------------------------------------------------------------------------------------
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod +x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh

# ---------------------------------------------------------------------------------------------------------------------
# Install git
# ---------------------------------------------------------------------------------------------------------------------
sudo apt install git -y

# ---------------------------------------------------------------------------------------------------------------------
# Install vscode
# ---------------------------------------------------------------------------------------------------------------------
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update -y
sudo apt install code


# ---------------------------------------------------------------------------------------------------------------------
# Clone the project
# ---------------------------------------------------------------------------------------------------------------------
mkdir ~/GitProjects
cd ~/GitProjects
git clone https://github.com/lucasmtz/ACAR-Net.git


# ---------------------------------------------------------------------------------------------------------------------
# Install the project
# ---------------------------------------------------------------------------------------------------------------------
cd ~/GitProjects/ACAR-Net
bash -i install.sh


# ---------------------------------------------------------------------------------------------------------------------
# Install google chrome
# ---------------------------------------------------------------------------------------------------------------------
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb
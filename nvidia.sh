  # Download the repository signing key and install it to the keyring directory
 curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub | gpg --dearmor --yes --output /usr/share/keyrings/nvidia-drivers.gpg
 echo "deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" >> /etc/apt/sources.list.d/nvidia-drivers.list
 echo "deb http://deb.debian.org/debian bookworm main non-free non-free-firmware contrib" >> /etc/apt/sources.list
# Install Jellyfin and nvidia using the metapackage (which will fetch jellyfin-server, jellyfin-web, and jellyfin-ffmpeg5)
apt-get update
apt-get install -y build-essential gcc dirmngr ca-certificates software-properties-common apt-transport-https dkms curl
apt-get install -y nvidia-driver
apt-get install -y cuda-driver
apt-get install -y cuda
apt-get install -y jellyfin
apt-get -y --with-new-pkgs upgrade jellyfin jellyfin-server

#!/bin/bash

set -e  # Exit on error

# Define root directory and Google Drive file IDs
ROOT_DIR="$HOME/Documents/drone"
QGROUND_CONTROL_ID="1i7bTphxp1nTKliYOknPK-8sS0kDPrX-R"
OMNIVERSE_APPIMAGE_ID="13D4dIyjEOET8Qpz3zdlI8_NpO3uUi351"
ISAAC_SIM_ZIP_ID="1-Hmt-FGNviP6mIsP3jNxUjQ5Q6-UUiqD"
CONDA_ENV_ID="1Xol9W6EeXwk-RfjQNzxZbuAYzP5zUftZ"

# Create root directory
mkdir -p $ROOT_DIR
cd $ROOT_DIR

# Install system dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y locales curl git unzip

# Check if Anaconda is already installed
if [ -d "$ROOT_DIR/anaconda3" ]; then
    echo "Anaconda already installed in $ROOT_DIR/anaconda3"
else
    # Install Anaconda if not already installed
    echo "Installing Anaconda..."
    wget https://repo.anaconda.com/archive/Anaconda3-2023.07-1-Linux-x86_64.sh -O $ROOT_DIR/anaconda.sh
    bash $ROOT_DIR/anaconda.sh -b -p $ROOT_DIR/anaconda3

    # Initialize Conda
    export PATH="$ROOT_DIR/anaconda3/bin:$PATH"
    echo "export PATH=\"$ROOT_DIR/anaconda3/bin:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
    $ROOT_DIR/anaconda3/bin/conda init bash
    source ~/.bashrc
fi

# Ensure Conda is available
source $ROOT_DIR/anaconda3/bin/activate

# Ensure pip uses the Conda environment
pip install --upgrade pip

# Install gdown for Google Drive file downloads
pip install --upgrade gdown

# Download all required files using gdown if not already downloaded
if [ ! -f "$ROOT_DIR/QGroundControl.AppImage" ]; then
    gdown --id $QGROUND_CONTROL_ID -O $ROOT_DIR/QGroundControl.AppImage
fi
if [ ! -f "$ROOT_DIR/Omniverse.AppImage" ]; then
    gdown --id $OMNIVERSE_APPIMAGE_ID -O $ROOT_DIR/Omniverse.AppImage
fi
if [ ! -f "$ROOT_DIR/isaac_sim.zip" ]; then
    gdown --id $ISAAC_SIM_ZIP_ID -O $ROOT_DIR/isaac_sim.zip
fi
if [ ! -f "$ROOT_DIR/drone_env.tar.gz" ]; then
    gdown --id $CONDA_ENV_ID -O $ROOT_DIR/drone_env.tar.gz
fi
# Import Conda environment
mkdir -p $ROOT_DIR/conda_envs
mv $ROOT_DIR/drone_env.tar.gz $ROOT_DIR/conda_envs/
cd $ROOT_DIR/conda_envs
tar -xzf drone_env.tar.gz
conda env create -f drone_env.yaml
conda activate drone

# Install Python3 Colcon Extensions
sudo apt install -y python3-colcon-common-extensions

# Set system locale
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# Add ROS 2 repository
sudo apt install -y software-properties-common
sudo add-apt-repository universe
sudo apt update && sudo apt install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS 2 Humble and tools
sudo apt update && sudo apt install -y ros-humble-desktop ros-dev-tools ros-humble-eigen3-cmake-module ros-humble-vision-msgs ros-humble-ackermann-msgs

echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc

# Install QGroundControl dependencies
sudo usermod -a -G dialout $USER
sudo apt-get remove modemmanager -y
sudo apt install -y gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl
sudo apt install -y libfuse2 libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor-dev

# Extract Isaac Sim
unzip $ROOT_DIR/isaac_sim.zip -d $ROOT_DIR
export ISAACSIM_PATH="$ROOT_DIR/isaac_sim"
echo "export ISAACSIM_PATH=\"$ROOT_DIR/isaac_sim\"" >> ~/.bashrc
echo "alias ISAACSIM_PYTHON=\"\$ISAACSIM_PATH/python.sh\"" >> ~/.bashrc
echo "alias ISAACSIM=\"\$ISAACSIM_PATH/isaac-sim.sh\"" >> ~/.bashrc

# Install Isaac Sim in the drone environment
pip install isaacsim==4.2.0.2 --extra-index-url https://pypi.nvidia.com
pip install isaacsim-extscache-physics==4.2.0.2 isaacsim-extscache-kit==4.2.0.2 isaacsim-extscache-kit-sdk==4.2.0.2 --extra-index-url https://pypi.nvidia.com

# Install PX4 development environment
git clone --recursive https://github.com/PX4/PX4-Autopilot.git $ROOT_DIR/PX4-Autopilot
cd $ROOT_DIR/PX4-Autopilot
git checkout v1.14.3
git submodule update --init --recursive
bash Tools/setup/ubuntu.sh
make px4_sitl_default none

# Install Micro XRCE-DDS Agent
git clone -b 2.4.2 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git $ROOT_DIR/Micro-XRCE-DDS-Agent
cd $ROOT_DIR/Micro-XRCE-DDS-Agent
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
sudo ldconfig /usr/local/lib/

# Create and build ROS 2 workspace
mkdir -p $ROOT_DIR/ws_sensor_combined/src && cd $ROOT_DIR/ws_sensor_combined/src
git clone https://github.com/PX4/px4_msgs.git
git clone https://github.com/PX4/px4_ros_com.git

cd $ROOT_DIR/ws_sensor_combined
source /opt/ros/humble/setup.bash
colcon build

echo "source $ROOT_DIR/ws_sensor_combined/install/local_setup.bash" >> ~/.bashrc
source ~/.bashrc

# Install ROS-Gazebo bridge for Humble
sudo apt install -y ros-humble-ros-gzharmonic

# Install Pegasus Simulator
git clone https://github.com/PegasusSimulator/PegasusSimulator.git $ROOT_DIR/PegasusSimulator

# Install Pegasus Simulator as a Python package
cd $ROOT_DIR/PegasusSimulator/extensions
pip install --editable pegasus.simulator

# Finish
echo "Setup complete. Please logout and log back in to apply user permission changes."

# ROS2 & PX4 Setup Script

This repository contains a shell script to automate the setup of **ROS 2 Humble**, **PX4**, **Isaac Sim**, and required dependencies on **Ubuntu 22.04**.

## Features
- Installs ROS 2 Humble and essential tools.
- Sets up PX4 Autopilot (v1.14.3).
- Configures **Anaconda** and imports the required Conda environment.
- Downloads and sets up **Isaac Sim** & **Omniverse**.
- Installs **QGroundControl** and its dependencies.

## Installation Instructions
### **1. Clone the Repository**
```bash
git clone https://github.com/Silicon-Melter/Auto-Drone-Setup.git
cd Auto-Drone-Setup
```

### **2. Give permission to setup.sh**
```bash
chmod +x setup.sh
```

### **3. Execute setup.sh**
```bash
chmod ./setup.sh
```

### **4. Setup Pegasus Simulator on Isaac Sim**
[Follow this link](https://pegasussimulator.github.io/PegasusSimulator/source/setup/installation.html)
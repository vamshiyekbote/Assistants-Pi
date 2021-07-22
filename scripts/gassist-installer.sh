#!/bin/bash
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -o errexit

scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
GIT_DIR="$(realpath $(dirname ${BASH_SOURCE[0]})/..)"

# make sure we're running as the owner of the checkout directory
RUN_AS="$(ls -ld "$scripts_dir" | awk 'NR==1 {print $3}')"
if [ "$USER" != "$RUN_AS" ]
then
    echo "This script must run as $RUN_AS, trying to change user..."
    exec sudo -u $RUN_AS $0
fi
clear
echo ""
read -r -p "Enter the your full credential file name including the path and .json extension: " credname
echo ""
read -r -p "Enter the your Google Cloud Console Project-Id: " projid
echo ""
read -r -p "Enter the modelid that was generated in the actions console: " modelid
echo ""
echo "Your Model-Id: $modelid Project-Id: $projid used for this project" >> /home/${USER}/modelid.txt

sudo apt-get update -y
sed 's/#.*//' ${GIT_DIR}/Google-Assistant/Requirements/Google-Assistant-system-requirements.txt | xargs sudo apt-get install -y
sudo pip install pyaudio

#Check OS Version
echo ""
echo "Checking OS Compatability"
echo ""
if [[ $(cat /etc/os-release|grep "raspbian") ]]; then
  if [[ $(cat /etc/os-release|grep "stretch") ]]; then
    osversion="Raspbian Stretch"
    echo ""
    echo "You are running the installer on Stretch="
    echo ""
  elif [[ $(cat /etc/os-release|grep "buster") ]]; then
    osversion="Raspbian Buster"
    echo ""
    echo "You are running the installer on Buster"
    echo ""
  else
    osversion="Other Raspbian"
    echo ""
    echo "You are advised to use the Stretch or Buster version of the OS"
    echo "Exiting the installer="
    echo ""
    exit 1
  fi
elif [[ $(cat /etc/os-release|grep "armbian") ]]; then
  if [[ $(cat /etc/os-release|grep "stretch") ]]; then
    osversion="Armbian Stretch"
    echo ""
    echo "You are running the installer on Stretch"
    echo ""
  else
    osversion="Other Armbian"
    echo ""
    echo "You are advised to use the Stretch version of the OS"
    echo "Exiting the installer="
    echo ""
    exit 1
  fi
elif [[ $(cat /etc/os-release|grep "osmc") ]]; then
  osmcversion=$(grep VERSION_ID /etc/os-release)
  osmcversion=${osmcversion//VERSION_ID=/""}
  osmcversion=${osmcversion//'"'/""}
  osmcversion=${osmcversion//./-}
  osmcversiondate=$(date -d $osmcversion +%s)
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8
  if (($osmcversiondate > 1512086400)); then
    osversion="OSMC Stretch"
    echo ""
    echo "You are running the installer on Stretch="
    echo ""
  else
    osversion="Other OSMC"
    echo ""
    echo "You are advised to use the Stretch version of the OS"
    echo "Exiting the installer="
    echo ""
    exit 1
  fi
elif [[ $(cat /etc/os-release|grep "ubuntu") ]]; then
  if [[ $(cat /etc/os-release|grep "bionic") ]]; then
    osversion="Ubuntu Bionic"
    echo ""
    echo "You are running the installer on Bionic"
    echo ""
  else
    osversion="Other Ubuntu"
    echo ""
    echo "You are advised to use the Bionic version of the OS"
    echo "Exiting the installer="
    echo ""
    exit 1
  fi
fi


#Copy snowboy wrappers for Stretch or Buster and create new ones for other OSes.
echo "Copying Snowboy files to Google Assistant directory"
echo ""
if [[ $osversion = "Raspbian Buster" ]]; then
  sudo \cp -f ${GIT_DIR}/Google-Assistant/src/resources/Buster-wrapper/_snowboydetect.so ${GIT_DIR}/Google-Assistant/src/_snowboydetect.so
  sudo \cp -f ${GIT_DIR}/Google-Assistant/src/resources/Buster-wrapper/snowboydetect.py ${GIT_DIR}/Google-Assistant/src/snowboydetect.py
elif [[ $osversion = "Raspbian Stretch" ]]; then
  sudo \cp -f ${GIT_DIR}/Google-Assistant/src/resources/Stretch-wrapper/_snowboydetect.so ${GIT_DIR}/Google-Assistant/src/_snowboydetect.so
  sudo \cp -f ${GIT_DIR}/Google-Assistant/src/resources/Stretch-wrapper/snowboydetect.py ${GIT_DIR}/Google-Assistant/src/snowboydetect.py
fi

if [[ $osversion != "Raspbian Stretch" ]] && [[ $osversion != "Raspbian Buster" ]]; then
  echo "Snowboy wrappers provied with the project are for Raspberry Pi boards running Raspbian Stretch or Buster. Custom snowboy wrappers need to be compiled for your setup. Grab a coffee or a beer this will take quite a while."
  echo ""
  echo "Installing Swig"
  echo ""
  if [ ! -d /home/${USER}/programs/libraries/swig/ ]; then
    sudo mkdir -p programs/libraries/ && cd programs/libraries
    sudo git clone https://github.com/swig/swig.git
  fi
  cd /home/${USER}/programs/libraries/swig/
  sudo ./autogen.sh
  sudo ./configure
  sudo make
  sudo make install
  echo ""
  echo "Compiling custom Snowboy Python3 wrapper"
  echo ""
  cd ~/programs
  if [ ! -d /home/${USER}/programs/snowboy/ ]; then
    sudo git clone https://github.com/Kitt-AI/snowboy.git
  fi
  cd /home/${USER}/programs/snowboy/swig/Python3
  sudo make

  if [ -e /home/${USER}/programs/snowboy/swig/Python3/_snowboydetect.so ]; then
    echo "Copying Snowboy files to Google Assistant directory"
    sudo \cp -f ./_snowboydetect.so ${GIT_DIR}/Google-Assistant/src/_snowboydetect.so
    sudo \cp -f ./snowboydetect.py ${GIT_DIR}/Google-Assistant/src/snowboydetect.py
  else
    echo "Something has gone wrong while compiling the wrappers. Try again or go through the errors above"
  fi
fi

cd /home/${USER}/
echo ""
echo ""
echo "Changing particulars in service files"
sed -i 's/created-project-id/'$projid'/g' ${GIT_DIR}/systemd/google-assistant.service
sed -i 's/saved-model-id/'$modelid'/g' ${GIT_DIR}/systemd/google-assistant.service
sed -i 's/__USER__/'${USER}'/g' ${GIT_DIR}/systemd/google-assistant.service

python3 -m venv env
env/bin/python -m pip install --upgrade pip setuptools wheel
source env/bin/activate

pip install -r ${GIT_DIR}/Google-Assistant/Requirements/Google-Assistant-pip-requirements.txt

if [[ $osversion != "OSMC Stretch" ]];then
	pip install RPi.GPIO
fi

sudo sed -i -e "s/^autospawn=no/#\0/" /etc/pulse/client.conf.d/00-disable-autospawn.conf
if [ -f /lib/udev/rules.d/91-pulseaudio-rpi.rules ] ; then
    sudo rm /lib/udev/rules.d/91-pulseaudio-rpi.rules
fi
  
pip install google-assistant-library==1.1.0
pip install google-assistant-grpc==0.3.0
pip install google-assistant-sdk==0.6.0
pip install google-assistant-sdk[samples]==0.6.0
google-oauthlib-tool --scope https://www.googleapis.com/auth/assistant-sdk-prototype \
          --scope https://www.googleapis.com/auth/gcm \
          --save --headless --client-secrets $credname
echo ""

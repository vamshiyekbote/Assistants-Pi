# Assistants-Pi
# Simultaneously run Google Assistant and Alexa on Raspberry Pi
Before Starting the setup

# For Google Assistant

Create a project in the Google's Action Console.
Download credentials--->.json file (refer to this doc for creating credentials https://developers.google.com/assistant/sdk/develop/python/config-dev-project-and-account)
For Amazon Alexa

Create a security profile for alexa-avs-sample-app if you already have one.
Download the "config.json" file.

# Setup Amazon Alexa, Google Assistant or Both
Clone the git using:https://github.com/vamshiyekbote/Assistants-Pi.git
DO NOT RENAME THE CREDENTIALS FILEs
Place the Alexa config.json in file in the /home/pi/Assistants-Pi/Alexa directory.
Place the Google client_secret.....json file in the /home/pi/ directory.

# Make the installers executable using:
sudo chmod +x /home/pi/Assistants-Pi/scripts/prep-system.sh    
sudo chmod +x /home/pi/Assistants-Pi/scripts/audio-test.sh   
sudo chmod +x /home/pi/Assistants-Pi/scripts/installer.sh  
Prepare the system for installing assistants by updating, upgrading and setting up audio using:
sudo /home/pi/Assistants-Pi/scripts/prep-system.sh
Restart the Pi using:
sudo reboot
Make sure that contents of asoundrc match the contents of asound.conf
Open a terminal and type:
sudo nano /etc/asound.conf
Open a second terminal and type:

sudo nano ~/.asoundrc
If the contents of .asoundrc are not same as asound.conf, copy the contents from asound.conf to .asoundrc, save using ctrl+x and y

Bonus Script - Test the audio setup using the following code (optional). Dont panic if the test does not go through successfully, proceed with the installation:
sudo /home/pi/Assistants-Pi/scripts/audio-test.sh  
Restart the Pi using:
sudo reboot
Install the assistant/assistants using the following. This is an interactive script, so just follow the onscreen instructions:
sudo /home/pi/Assistants-Pi/scripts/installer.sh  

# If you get a fatal error: curl/curl.h: No such file or directory that means you need to install curl. In your Terminal enter:

"sudo apt-get install libcurl4-openssl-dev"
"sudo apt-get install libcurl4-gnutls-dev"

After verification of the assistants, to make them auto start on boot:
Open a terminal and run the following commands:

sudo chmod +x /home/pi/Assistants-Pi/scripts/service-installer.sh
sudo /home/pi/Assistants-Pi/scripts/service-installer.sh  
For Alexa:
sudo systemctl enable alexa.service  

For Google Assistant:
sudo systemctl enable google-assistant.service  
Authorize Alexa before restarting
sudo /home/pi/Assistants-Pi/Alexa/startsample.sh  
Manually Start The Alexa Assistant
Double click start.sh file in the /home/pi/Assistants-Pi/Alexa folder and choose to "Execute in the Terminal".

Manually Start The Google Assistant
Open a terminal and execute the following:

/home/pi/env/bin/python -u /home/pi/Assistants-Pi/Google-Assistant/src/main.py --project_id 'replace this with the project id '--device_model_id 'replace this with the model id'
If you have issues with the Assistants strating on boot, you may have to setup PulseAudio as a system wide service.


I have also faced a similar issue this week. As we are using Raspberry Pi 3 Model, it has only 1 gb of ram memory and some of the object building processes (like [ 93%] Building CXX object Application Utilities/DefaultClient/src/CMakeFiles/DefaultClient.dir/DefaultClient.cpp.o) from recent avs-device-sdk version requires more memory for object building task.

To solve this issue I increased my swap memory size from 100 mb (default) to 512 mb. After this only, my AVS Build process completed. It is not much efficient, as it takes a lot of time but it is better than a terminated build process.

To increase the swap memory:

Open the terminal, and run

sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
After the second command, dphys-swapfile file will open and you will need to modify

CONF_SWAPSIZE=100

to

CONF_SWAPSIZE=1024

After changing swap size value from 100 to 1024
Press CTRL+O then Enter Key then CTRL+X
(To save the changes made in the file)

Then run
3) sudo dphys-swapfile swapon

Now, reboot or shutdown and start your raspberry pi again and you can see your swap memory size will be increased to 512 mb
(You can check this by running command "free -h" before and after changing the swapsize)

Now, you can run your BUILD AVS process without any error or termination.

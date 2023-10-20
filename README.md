# Neurotech2023
Neurotechnology, Brains and Machines at Olin College of Engineering

## Setting up the Pison Pipeline

The following are the dependencies for the Pison pipeline app:
1. MATLAB (with app designer available)
2. Python 3.5 or > (tested with Python 3.9 but should have no issues with a few versions earlier/later)
3. scipy.io (install with `pip install scipy` or `conda install scipy` if using a conda environment)
4. pylsl

### Installing pylsl

PyLSL is the communication protocol used to stream data from the device to the computer. Installing pylsl differs based on platform.

**Windows**

You'll also need version 3.9, 3.10, or 3.11 of python that is not the Windows default install version (but instead one downloaded from Python directly or a repository that still supplies a binary for what you need: https://github.com/adang1345/PythonWindows/blob/master/3.10.12/python-3.10.12-amd64-full.exe).

You'll need to make sure that this version of python is on your path above other version of python. You can do this by opening up the environmental variables in windows (type it into the search). Click on the button to edit them. Select the systems (or personal) PATH variable and edit it. Add two new paths:one to wherever python is installed and one to that installation folder followed by \Scripts\

Then you may also need to set your python version in matlab:
pyversion('C:\Users\YOUR_USER_NAME\AppData\Local\Programs\Python\Python310\python.exe')
or a path to wherever you installed this new python.
You can check that this is correct from the Matlab command window by:
!python -V
Then, you can install pylsl from the same Matlab command window by:
!python -m pip install pylsl
You may also need to install other dependencies for this version:
!python -m pip install scipy
!python -m pip install numpy

More generally (and if you already have a non-default Windows python installed), you can install pylsl on windows, by simply running `pip install pylsl`. This will install the python package and all backend libraries needed. 

**Linux/MacOS**

There are two methods to install on Linux.

1. Installation with conda
If you have a conda environment on your linux/macOS machine, the library can simply be installed with `conda install -c conda-forge liblsl`.
2. Installation without conda
If you do not have a conda environment, first run the `pip install pylsl` command. This will install the python bindings, but not the lsl library.


On MacOS, if you have homebrew installed, you can install the lsl library using `brew install labstreaminglayer/tap/lsl`.

If using Linux or MacOS without homebrew, the following instructions apply:
To install liblsl, go to the [releases](https://github.com/sccn/liblsl/releases) page.
From here, choose the one corresponding to your version (focal is 20.04/20.10, jammy is 22.04/22.10, bionic is 18.04/18.10).
Install the package with `sudo dpkg -i <name of the deb file you downloaded>` from the path you downloaded the deb file to.

To install on other linux platforms (non ubuntu-based), you can [build from source](https://labstreaminglayer.readthedocs.io/dev/lib_dev.html).

## Using the Data Collection App

To use the data collection app, clone the repository. From the `Neurotech_Pison_Pipeline` folder, run `recorddata` in the MATLAB command line.
This should start up the data collection app, which looks like the following:
<img width="639" alt="Image of the neurotech pison data collection app" src="https://github.com/smichalka/Neurotech2023/assets/30906272/ba820a2f-311f-4f40-a50b-417231930335">

On the Pison phone, open the `vulcan_flutter` app and turn on the Vulcan (turn on is two short vibrations and one long vibration, turn off is one long vibration then two short vibrations). 
From the flutter app on the phone, go to the 'Devices' tab, and you should see the device show up. Click the name of the device to connect. You'll know that you connect because the Pison wristband
will vibrate twice. 
<img width="200" alt="Screenshot of devices in Pison vulcan flutter app" src=https://github.com/smichalka/Neurotech2023/assets/30906272/9415e534-e4a8-41aa-b46e-ba778952f724>

To make sure that everything connected properly, go back to the 'Realtime' tab and check the visuals. If everything is set up right, you should see some graphs under 'FFT' and 'ADC'. If you
see a loading animation, the device likely has not connected properly. I honestly haven't figured out exactly how to fix this, but some combination of fully exiting matlab, force quitting
the flutter app, and restarting the Pison phone can fix this (you may just have to wait for a few minutes for it to get fixed).

Once the device is properly connected, type the device name into the app (just the number, so in the example from above the device name is 50A0A170). Once you hit connect, you should
see a message like 'Connected to device'. From here, you can start recording!

### Processing Data
After a session of data collection (30 gestures or however many you specify), you will have one important file named `lsl_data_<timestamp>.mat`. This should contain 3 variables: lsl_data, marker_data, and recording_info (coming soon!). The lsl_data file contains a first column of timestamps and then the four channels of EMG data (the last column should be all zeros, and you should ignore it). The marker_data file contains timestamps and markers for when each gesture started and ended (usually zeros, but sometimes 99 if you chose to re-record this trial... we will throw out the ones that go with the 99 markers).  For the markers, 1 is rock, 2 is paper, 3 is scissors.

The preprocessData() function takes in lsl_data and marker_data and returns an "epoched" and filtered form of this that is ready for analysis. As a sanity check, each gesture's lsl data should be about 1400 samples by 4 channels, as the sensor samples at 1000hz and each gesture lasts 1.4 seconds. The data are high pass filtered at 5Hz.

### Common issues

There is a log area for any errors that Python throws. Note that this doesn't auto clear, so it may be showing an earlier error. Pretty much all errors that show up
there are a result of the data not being received properly, which is usually due to an older lsl stream lingering and transmitting no data. In this case, restarting
the MATLAB app, phone, and pison armband may help. At the end of each data collection session, the size of the resulting lsl data list. If the list length is small,
this is a good sign that something went wrong in the data collection process.

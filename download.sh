#!/bin/bash

driver_path="/data/etc"
driver_name="dbus-homewizard-energy-p1"

echo ""
echo ""

# fetch version numbers for different versions
echo -n "Fetch current version numbers..."

# latest release
latest_release_stable=$(curl -s https://api.github.com/repos/tomvanacker85/${driver_name}/releases/latest | grep "tag_name" | cut -d : -f 2,3 | tr -d "\ " | tr -d \" | tr -d \,)

echo "> Latest release: $latest_release_stable"
echo ""

driver_name_instance=${driver_name}

echo ""
if [ -d ${driver_path}/${driver_name_instance} ]; then
    echo "Updating driver '$driver_name' as '$driver_name_instance'..."
else
    echo "Installing driver '$driver_name' as '$driver_name_instance'..."
fi


# change to temp folder
cd /tmp


# download driver
echo ""
echo "Downloading driver..."


url=$(curl -s https://api.github.com/repos/tomvanacker85/${driver_name}/releases/latest | grep "zipball_url" | sed -n 's/.*"zipball_url": "\([^"]*\)".*/\1/p')
echo "Downloading from: $url"
wget -O /tmp/${driver_name}.zip "$url"

# check if download was successful
if [ ! -f /tmp/${driver_name}.zip ]; then
    echo ""
    echo "Download failed. Exiting..."
    exit 1
fi


# If updating: cleanup old folder
if [ -d /tmp/${driver_name}-master ]; then
    rm -rf /tmp/${driver_name}-master
fi


# unzip folder
echo "Unzipping driver..."
unzip ${driver_name}.zip

# Find and rename the extracted folder to be always the same
extracted_folder=$(find /tmp/ -maxdepth 1 -type d -name "*${driver_name}-*")

# Desired folder name
desired_folder="/tmp/${driver_name}-master"

# Check if the extracted folder exists and does not already have the desired name
if [ -n "$extracted_folder" ]; then
    if [ "$extracted_folder" != "$desired_folder" ]; then
        mv "$extracted_folder" "$desired_folder"
    else
        echo "Folder already has the desired name: $desired_folder"
    fi
else
    echo "Error: Could not find extracted folder. Exiting..."
    exit 1
fi


# If updating: backup existing config file
if [ -f ${driver_path}/${driver_name_instance}/config.ini ]; then
    echo ""
    echo "Backing up existing config file..."
    mv ${driver_path}/${driver_name_instance}/config.ini ${driver_path}/${driver_name_instance}_config.ini
fi


# If updating: cleanup existing driver
if [ -d ${driver_path}/${driver_name_instance} ]; then
    echo ""
    echo "Cleaning up existing driver..."
    rm -rf ${driver_path:?}/${driver_name_instance}
fi


# copy files
echo ""
echo "Copying new driver files..."
cp -R /tmp/${driver_name}-master/${driver_name}/ ${driver_path}/${driver_name_instance}/

# remove temp files
echo ""
echo "Cleaning up temp files..."
rm -rf /tmp/${driver_name}.zip
rm -rf /tmp/${driver_name}-master


# check if driver_name is not equal to driver_name_instance
if [ "$driver_name" != "$driver_name_instance" ]; then
    echo ""
    echo "Renaming internal driver files..."
    # rename the driver_name.py file to driver_name_instance.py
    mv ${driver_path}/${driver_name_instance}/${driver_name}.py ${driver_path}/${driver_name_instance}/${driver_name_instance}.py
    # rename the driver_name in the run file to driver_name_instance
    sed -i 's:'${driver_name}':'${driver_name_instance}':g' ${driver_path}/${driver_name_instance}/service/run
    # rename the driver_name in the log run file to driver_name_instance
    sed -i 's:'${driver_name}':'${driver_name_instance}':g' ${driver_path}/${driver_name_instance}/service/log/run

    # add device_instance to the end of the line where device_name is found in the config sample file
    sed -i '/device_name/s/$/ '${driver_instance}'/' ${driver_path}/${driver_name_instance}/config.sample.ini

    # change the device_instance from 100 to 100 + device_instance in the config sample file
    config_file_device_instance=$(grep 'device_instance = ' ${driver_path}/${driver_name_instance}/config.sample.ini | awk -F' = ' '{print $2}')
    new_device_instance=$((config_file_device_instance + driver_instance))
    sed -i 's/device_instance = 100/device_instance = '${new_device_instance}'/' ${driver_path}/${driver_name_instance}/config.sample.ini

fi


# If updating: restore existing config file
if [ -f ${driver_path}/${driver_name_instance}_config.ini ]; then
    echo ""
    echo "Restoring existing config file..."
    mv ${driver_path}/${driver_name_instance}_config.ini ${driver_path}/${driver_name_instance}/config.ini
fi


# set permissions for files
echo ""
echo "Setting permissions for files..."
chmod 755 ${driver_path}/${driver_name_instance}/${driver_name_instance}.py
chmod 755 ${driver_path}/${driver_name_instance}/install.sh
chmod 755 ${driver_path}/${driver_name_instance}/restart.sh
chmod 755 ${driver_path}/${driver_name_instance}/uninstall.sh
chmod 755 ${driver_path}/${driver_name_instance}/service/run
chmod 755 ${driver_path}/${driver_name_instance}/service/log/run


# copy default config file
if [ ! -f ${driver_path}/${driver_name_instance}/config.ini ]; then
    echo ""
    echo ""
    echo "First installation detected. Copying default config file..."
    echo ""
    echo "** Do not forget to edit the config file with your settings! **"
    echo "You can edit the config file with the following command:"
    echo "nano ${driver_path}/${driver_name_instance}/config.ini"
    cp ${driver_path}/${driver_name_instance}/config.sample.ini ${driver_path}/${driver_name_instance}/config.ini
    echo ""
    echo "** Execute the install.sh script after you have edited the config file! **"
    echo "You can execute the install.sh script with the following command:"
    echo "bash ${driver_path}/${driver_name_instance}/install.sh"
    echo ""
else
    echo ""
    echo "Restart driver to apply new version..."
    /bin/bash ${driver_path}/${driver_name_instance}/restart.sh
fi


echo
echo "Done."
echo
echo

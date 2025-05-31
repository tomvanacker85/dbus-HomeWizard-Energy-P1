# dbus-homewizard-energy-p1
Integrate HomeWizard Energy P1 meter into [Victron Energies Venus OS](https://github.com/victronenergy/venus)

## Purpose
With the scripts in this repo it should be easy possible to install, uninstall, restart a service that connects the HomeWizard Energy P1 to the VenusOS and GX devices from Victron.
Idea is pasend on @RalfZim project linked below.



## Inspiration
Forked from https://github.com/back2basic/dbus-Home-Wizzard-Energy-P1

## How it works
### My setup
- HomeWizard Energy P1 with latest firmware 
  - 3-phase installation
  - Connected to Wifi network "A"
  - IP 192.168.1.42
- Victron Energy Cerbo GX with Venus OS - Firmware v3.11
  - Connected to Wifi network "A"
  - IP 192.168.1.60

### Details / Process
So what is the script doing:
- Runs as a service
- Connects to DBus of the Venus OS `com.victronenergy.grid.http_40`
- After successful DBus connection, HomeWizard P1 is accessed via REST-API - simply http://[ip]/api/v1/data is called and a JSON is returned with all details. A sample JSON file from HomeWizard Energy P1 can be found [here](docs/homewizard-energy-p1.json)
- Serial is taken from the response as device serial
- Paths are added to the DBus with default value 0 - including some settings like name, etc
- After that a "loop" is started which pulls HomeWizard P1 data every 750ms from the REST-API and updates the values in the DBus

That's it 😄

### Pictures
![Tile Overview](img/VenusOs_Overview.png)
![Remote Console - Overview](img/VenusOs_DeviceList.png) 
![SmartMeter - Values](img/VenusOs_P1.png)
![SmartMeter - Device Details](img/VenusOs_Service.png)


## Install / Update
1. Login to your Venus OS device via SSH. See Venus OS:Root Access for more details.

2. Execute this commands to download and copy the files:

```
wget -O /tmp/download_dbus-homewizard-energy-p1.sh https://raw.githubusercontent.com/tomvanacker85/dbus-homewizard-energy-p1/master/download.sh
bash /tmp/download_dbus-homewizard-energy-p1.sh
```

### Extra steps for your first installation
3. Edit the config file to fit your needs. The correct command for your installation is shown after the installation.
```nano /data/etc/dbus-mqtt-grid/config.ini```

4. Install the driver as a service. The correct command for your installation is shown after the installation.
```bash /data/etc/dbus-mqtt-grid/install.sh```
The daemon-tools should start this service automatically within seconds.

## Config
Copy or rename the config.sample.ini to config.ini in the ``/data/etc/dbus-mqtt-grid/`` folder and change it as you need it.

### JSON structure

## Uninstall
To uninstall the service:

```bash /data/etc/dbus-mqtt-grid/uninstall.sh```

## Restart
To restart the service:
```bash /data/etc/dbus-mqtt-grid/restart.sh```

## Debugging
To check the logs of the default instance:
```
tail -n 100 -F /data/log/dbus-homewizard-energy-p1/current | tai64nlocal
```

The service status can be checked with svstat: ```svstat /service/dbus-mqtt-grid```

This will output somethink like ```/service/dbus-homewizard-energy-p1: up (pid 26270) 1133 seconds```

If the seconds are under 5 then the service crashes and gets restarted all the time. If you do not see anything in the logs you can increase the log level in /data/etc/dbus-homewizard-energy-p1/config.ini by changing level=logging.WARNING to level=logging.INFO or level=logging.DEBUG and restarting the service. For available log values: see https://docs.python.org/3/library/logging.html#levels.

If the script stops with the message dbus.exceptions.NameExistsException: Bus name already exists: com.victronenergy.grid.homewizard_energy_p1" it means that the service is still running or another service is using that bus name.

## Compatibility
This software supports the latest three stable versions of Venus OS. It may also work on older versions, but this is not guaranteed.


### Change config.ini
Within the project there is a file `/data/dbus-Home-Wizzard-Energy-P1/config.ini` - just change the values - most important is the host, username and password in section "ONPREMISE". More details below:

| Section  | Config vlaue | Explanation |
| ------------- | ------------- | ------------- |
| DEFAULT  | AccessType | Fixed value 'OnPremise' |
| DEFAULT  | SignOfLifeLog  | Time in minutes how often a status is added to the log-file `current.log` with log-level INFO |
| DEFAULT  | CustomName  | Name of your device - usefull if you want to run multiple versions of the script |
| DEFAULT  | DeviceInstance  | DeviceInstanceNumber e.g. 40 |
| DEFAULT  | Role | Fixed value:  'GRID' |
| DEFAULT  | Position | Fixed value: 0 = AC|
| DEFAULT  | LogLevel  | Define the level of logging - lookup: https://docs.python.org/3/library/logging.html#levels |
| DEFAULT  | Phases  | 1 for 1 phase system / 3 for 3 phase system |
| ONPREMISE  | Host | IP or hostname of on-premise HomeWizard Energy P1 web-interface |
<!-- | ONPREMISE  | Username | Username for htaccess login - leave blank if no username/password required |
| ONPREMISE  | Password | Password for htaccess login - leave blank if no username/password required |
| ONPREMISE  | L1Position | Which input on the Shelly in 3-phase grid is supplying a single Multi | -->


<!-- ### Remapping L1
In a 3-phase grid with a single Multi, Venus OS expects L1 to be supplying the only Multi. This is not always the case. If for example your Multi is supplied by L3 (Input `C` on the Shelly) your GX device will show AC Loads as consuming from both L1 and L3. Setting `L1Position` to the appropriate Shelly input allows for remapping the phases and showing correct data on the GX device.

If your single Multi is connected to the Input `A` on the Shelly you don't need to change this setting. Setting `L1Position` to `2` would swap the `B` CT & Voltage sensors data on the Shelly with the `A` CT & Voltage sensors data on the Shelly. Respectively, setting `L1Position` to `3` would swap `A` and `C` inputs. -->

## Used documentation
- https://github.com/victronenergy/venus/wiki/dbus#grid   DBus paths for Victron namespace GRID
- https://github.com/victronenergy/venus/wiki/dbus#pv-inverters   DBus paths for Victron namespace PVINVERTER
- https://github.com/victronenergy/venus/wiki/dbus-api   DBus API from Victron
- https://www.victronenergy.com/live/ccgx:root_access   How to get root access on GX device/Venus OS

## Discussions on the web
This module/repository has been posted on the following threads:
- https://community.victronenergy.com/questions/238117/home-wizzard-energy-p1-meter-in-venusos.html

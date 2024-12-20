# Windows deployment for custom device config 

This project was specifically made for Adoro d.o.o in order to speed up the repetitive process of device preparations for end-users. It contains few scripts that are deployed and executed in following order:

* system-setup
    * create local admin without password for auto-login
    * remove bloatware
    * deploy files 

* system-first-boot
    * set installation type
    * prepare system for second boot
    * set hostname

* system-second-boot
    * change local admin password
    * perform system changes
    * perform language and time setup
    * join domain

* install
    * install programs provided in config.ps1
        * config
            * functions and variables

* startup
    * perform UI changes
    * clean deployment files
    * perform internal program installations


# How to use this project with Provisioning Packages

1. open Windows Configuration Manager
2. advanced provisioning
    * create new project called deployment-v(version)
    * all Windows desktop editions
    * finish
3. runtime settings
    * Accounts
       * ComputerName: v(version)
    * OOBE
       * HideOobe: TRUE
    * ProvisioningCommands
       * DeviceContext
       * CommandFiles: import scripts, installation and deployment files
       * CommandLine: powershell.exe -ExecutionPolicy Bypass -File system-setup.ps1
4. File - Save
5. Export - Provisioning Package
6. Copy .ppkg file to USB stick
7. Insert USB when Windows installation hits Is this right country or region? screen

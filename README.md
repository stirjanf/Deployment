# Windows deployment for custom device config project


# Various scripts that deploy via Microsoft Provisioning Packages

This project was specifically made for Adoro d.o.o in order to speed up the repetitive process of device preparations for end-users. It contains few scripts that are deployed and executed in following order:

* system-setup
    - create local admin without password for auto-login
    - remove bloatware
    - deploy files 

* system-first-boot
    - set installation type
    - prepare system for second boot
    - set hostname

* system-second-boot
    - change local admin password
    - perform system changes
    - perform language and time setup
    - join domain

* install
    - install programs provided in config.ps1
        * config
            - functions and variables

* startup
    - perform UI changes
    - clean deployment files
    - perform internal program installations


# How to use this project with Provisioning Packages

Watch the quick video guide:
<a href="https://www.youtube.com/" target="_blank"> </a>
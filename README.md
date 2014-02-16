laraUp
======

Laravel development in Vagrant virtualbox


This Script will install Laravel PHP Framework in Local machine which is also shared with Vagrant virtual machine. When the process finishes the newly created project can be tested via browser at http://localhost:8088

## Prerequesites
* Vagrant
* Virtualbox
* Git
* Ruby

## Installation
* Clone the repository
* Go the the cloned Directory
* make the Bash script executable
* > chmod +x laraUp.sh
* and run it
* > ./laraUp.sh

## What does it install?
* Debian Wheezy (Only Supported machine at the moment)
* PHP
* MySQL
* Nginx
* Git
 
## Advantage ?
* Vagrant
* No Need to configure virtual hosts for Nginx
* Single project can be tested in different environment without losing anything
* No need to create a project in web root, create the project anywhere you like and test it via web browser.
* And lots more

## Roadmap
Support for Other Vagrant boxes and Operating systems
Apache Vhost Config
Some More Open Ports or ask for user Input

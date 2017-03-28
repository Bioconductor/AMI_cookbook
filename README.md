Description
===========
This cookbook installs / configures R and a select number of Bioconductor
packages on an Amazon EC2 instance.

Requirements
============

This recipe was written for an Ubuntu 16.04 AWS EC2 instance with 4 cores, 
16 GB RAM and 100 GB disk space.

Attributes
==========

TBD

Usage
=====
Prior to running this recipe:
* Launch an Ubuntu EC2 instance enabled with SSH, http and https
* Modify package versions and / or urls in attributes/default.rb

Description
===========
This cookbook installs / configures R and a select number of Bioconductor
packages on an Amazon EC2 instance. Installed packages are those identified
on the download stats at http://www.bioconductor.org/packages/stats/ and
as of version 0.1.11 include the top 75 software, 30 annotation and 15 
experimental data packages. The full install (system dependencies and 
Bioconductor packages) occupies 19GB of disk space.

Requirements
============

This recipe was written for an Ubuntu 16.04 AWS EC2 instance with 4 cores, 
16 GB RAM and 100 GB disk space.

Usage
=====
See instructions at https://github.com/Bioconductor/AWS_management/blob/master/docs/Create_AMI_from_Chef.md

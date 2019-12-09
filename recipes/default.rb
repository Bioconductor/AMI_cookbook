## Any Ubuntu 16.04 image brought up from EC2 Quickstart or AWS Marketplace
## after March 29, 2017 will running on the AWS-tuned kernel:
## https://insights.ubuntu.com/2017/04/05/ubuntu-on-aws-gets-serious-performance-boost-with-aws-tuned-kernel/
## grub update:
## Old grub config is different from new - dpkg pulls up GUI to select
## options. Pass flag to accept new config.

execute "system updates" do
  command "apt-get update"
  action :run
end

execute "system upgrades" do
  command 'DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade'
  action :run
end

## The node attribute node["reldev"] is defined in the code that creates
## the roles: AMI_release_linux and AMI_devel_linux.
if node["reldev"] == "devel"
  reldev = :dev
elsif node["reldev"] == "release"
  reldev = :rel
else
  raise "are the AMI_devel and AMI_release roles defined?"
end
bioc_version = node['bioc_version'][reldev]
r_version = node['r_version'][reldev]

## --------------------------------------------------------------------------- 
## Repo packages 
## --------------------------------------------------------------------------- 

## NOTE: If apache is installed some configuration must be done to
##       play nice with RStudio which is running on port 80. 
pkgs = %w(ack-grep libnetcdf-dev libhdf5-serial-dev sqlite libfftw3-dev 
          libfftw3-doc libopenbabel-dev fftw3 fftw3-dev pkg-config 
          xfonts-100dpi xfonts-75dpi
          libopenmpi-dev openmpi-bin mpi-default-bin openmpi-common
          libexempi3 openmpi-doc texlive-science python-mpi4py
          texlive-bibtex-extra texlive-fonts-extra fortran77-compiler gfortran
          libreadline-dev libx11-dev libxt-dev texinfo libxml2-dev
          libcurl4-openssl-dev xvfb  libpng-dev
          libjpeg-dev libcairo2-dev libtiff5-dev
          tcl8.5-dev tk8.5-dev libicu-dev libgsl0-dev
          libgtk2.0-dev gcc-4.8 default-jre openjdk-8-jdk texlive-latex-extra
          texlive-fonts-recommended libgl1-mesa-dev libglu1-mesa-dev
          htop libgmp3-dev imagemagick unzip libncurses-dev 
          libbz2-dev libxpm-dev liblapack-dev libv8-3.14-dev libperl-dev
          libarchive-extract-perl libfile-copy-recursive-perl libcgi-pm-perl 
          tabix libdbi-perl libdbd-mysql-perl ggobi libgtkmm-2.4-dev 
          libssl-dev byacc
          automake libmysqlclient-dev postgresql-server-dev-all
          firefox graphviz python-pip libxml-simple-perl texlive-lang-european
          libmpfr-dev libudunits2-dev tree python-yaml libmodule-build-perl 
          gdb biber git python-sklearn python-numpy python-pandas python-h5py
          libprotoc-dev libprotobuf-dev protobuf-compiler libapparmor-dev 
          libgeos-dev libmagick++-dev libsasl2-dev
          gdebi-core)
package pkgs do
  action :install
end

## --------------------------------------------------------------------------- 
## Non-repo packages

## pandoc: newer version than available from the Ubuntu package repo
pandoc_deb = node['pandoc_url'].split("/").last

remote_file "/tmp/#{pandoc_deb}" do
  source node['pandoc_url']
end

dpkg_package "pandoc" do
  source "/tmp/#{pandoc_deb}"
end

## Python

execute "update pip" do
  command "pip install --upgrade pip"
end

execute "install jupyter" do
  command "pip install jupyter"
  not_if "which jupyter | grep -q jupyter"
end

execute "install ipython" do
  command "pip install ipython==4.1.2"
  not_if "pip freeze | grep -q ipython"
end

execute "install nbconvert" do
  command "pip install nbconvert==4.1.0"
  not_if "pip freeze | grep -q nbconvert"
end

## Clustal Omega: multiple sequence alignment

# required for clustalo 
argtable_tarball = node['argtable_url'].split('/').last
argtable_dir = argtable_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{argtable_tarball}" do
  source node['argtable_url']
end

execute "build argtable" do
  command "tar zxf #{argtable_tarball.split('/').last} && cd #{argtable_dir} && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{argtable_dir}/config.log"}
end

clustalo_tarball = node['clustalo_url'].split('/').last
clustalo_dir = clustalo_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{clustalo_tarball}" do
  source node['clustalo_url']
end

execute "build clustalo" do
  command "tar zxf #{clustalo_tarball} && cd #{clustalo_dir} && ./configure && make && make install"
  not_if "which clustalo | grep -q clustalo"
  cwd "/tmp"
end


## JAGS

remote_file "/tmp/#{node['jags_url'][reldev].split('/').last}" do
  source node['jags_url'][reldev]
end

execute "build jags" do
  command "tar zxf #{node['jags_url'][reldev].split('/').last} && cd #{node['jags_dir'][reldev]} && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['jags_dir'][reldev]}/config.log"}
end

## libsbml

remote_file "/tmp/#{node['libsbml_url'].split('/').last}" do
  source node['libsbml_url']
end

execute "build libsbml" do
  command "tar zxf #{node['libsbml_url'].split('/').last} && cd #{node['libsbml_dir']} && ./configure --enable-layout && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['libsbml_dir']}/config.log"}
end

## Vienna RNA

remote_file "/tmp/#{node['vienna_rna_dir']}.tar.gz" do
  source node["vienna_rna_url"]
end

execute "build ViennaRNA" do
  command "tar zxf #{node['vienna_rna_dir']}.tar.gz && cd #{node['vienna_rna_dir']}/ && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['vienna_rna_dir']}/config.log"}
end

## --------------------------------------------------------------------------- 
## Install R as root without recommended packages:
## AFAICT rstudio server must run R as root because it calls setuid when a 
## user's session starts. The server assumes root right before it calls setuid 
## for a new session and at all other times runs as rstudio-server. If R
## is installed as ubuntu PATHs must be manipulated so rstudio-server can
## find R when necessary. Here R is installed as root but all (non-base)
## packages are installed as the ubuntu user.

directory "/downloads" do
  owner "root"
  mode "0755"
  action :create
  not_if {Dir.exists? "/downloads"}
end

remote_file "/downloads/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner 'root'
end

execute "untar R" do
  command "tar zxf #{node['r_url'][reldev].split("/").last}"
  user "root"
  cwd "/downloads"
  not_if {File.exists? "/downloads/#{node['r_src_dir'][reldev]}"}
end

execute "configure R" do
  command "./configure --without-recommended-packages --enable-R-shlib --prefix=/usr/local"
  user "root"
  cwd "/downloads/#{node['r_src_dir'][reldev]}"
  not_if {File.exists? "/downloads/#{node['r_src_dir'][reldev]}/config.log"}
end

execute "make R" do
  command "make > /downloads/R-make.out 2>&1"
  user "root"
  cwd "/downloads/#{node['r_src_dir'][reldev]}"
  not_if {File.exists? "/usr/local/bin/R"}
end

execute "install R" do
    command "make install"
    user "root"
    cwd "/downloads/#{node['r_src_dir'][reldev]}"
    not_if {File.exists? "/usr/local/bin/R"}
end

execute "install BiocManager as root" do
  user "root"
  command %Q(R -e "install.packages('BiocManager', repos = 'http://cran.us.r-project.org')" > /tmp/BiocManagerInstall.log)
  not_if {File.exists? "/usr/local/lib/R/library/BiocManager"}
end

if reldev == :dev
  execute "make devel if necessary" do
    command %Q(R -e "BiocManager::install(version='devel', ask=FALSE)" >> /tmp/BiocManagerInstall.log)
    user "root"
    not_if %Q(R --slave -q -e "!BiocManager:::isDevel()" | grep -q FALSE)
  end
end

## Install Bioconductor packages as ubuntu:

ubuntu_dir = "/home/ubuntu"

%w(bin tmp).each do |dir|
    directory "#{ubuntu_dir}/#{dir}" do
        owner "ubuntu"
        group "ubuntu"
        mode "0755"
        action :create
    end
end


## variables for persistent hub caching
execute "persistent ah cache" do
  user "ubuntu"
  command "echo 'export ANNOTATION_HUB_ASK=FALSE' >> /home/ubuntu/.bashrc"
end
execute "persistent eh cache" do
  user "ubuntu"
  command "echo 'export EXPERIMENT_HUB_ASK=FALSE' >> /home/ubuntu/.bashrc"
end

## directories for default hub/bfc caching
caching_dir = "home/ubuntu/.cache"
%w(AnnotationHub ExperimentHub BiocFileCache).each do |dir|
    directory "#{caching_dir}/#{dir}" do
        owner "ubuntu"
        group "ubuntu"
        mode "0775"
        action :create
    end
end


## Install base, software, data experiment and annotation packages

cookbook_file "/tmp/basePackages.R" do
  source "basePackages.R"
  mode 0755
end

execute "install base Bioconductor packages" do
  command %q(R -e "source('/tmp/basePackages.R')" > /tmp/basePackages.log)
  user "ubuntu"
  group "ubuntu"
end

## FIXME: Not clean; does not remove dependencies
execute "remove root BiocManager" do
  only_if {File.exists? "/usr/local/lib/R/library/BiocManager"}
  command %q(R --slave -q -e "remove.packages('BiocManager', lib='/usr/local/lib/R/library')")
end

cookbook_file "/tmp/softwarePackages.R" do
  source "softwarePackages.R"
  mode 0755
end

execute "install software Bioconductor packages" do
  command %q(R -e "source('/tmp/softwarePackages.R')" > /tmp/softwarePackages.log)
  user "ubuntu"
  group "ubuntu"
  timeout 7200
  not_if {File.exists? "/usr/local/lib/R/library/BiocGenerics"}
end

cookbook_file "/tmp/dataExperimentPackages.R" do
  source "dataExperimentPackages.R"
  mode 0755
end

execute "install data experiment Bioconductor packages" do
  command %q(R -e "source('/tmp/dataExperimentPackages.R')" > /tmp/dataExperimentPackages.log)
  user "ubuntu"
  group "ubuntu"
end

cookbook_file "/tmp/annotationPackages.R" do
  source "annotationPackages.R"
  mode 0755
end

execute "install annotation Bioconductor packages" do
  command %q(R -e "source('/tmp/annotationPackages.R')" > /tmp/annotationPackages.log)
  user "ubuntu"
  group "ubuntu"
end

## latex settings

file "/etc/texmf/texmf.d/01bioc.cnf" do
    content "shell_escape=t"
    owner "root"
    group "root"
    mode "0644"
end

execute "update-texmf" do
    action :run
    user "root"
    command "update-texmf"
end

## --------------------------------------------------------------------------- 
## rstudio server

execute "disable password lock in cloud.cfg" do
    command %Q(sed -i.bak "s/lock_passwd: True/lock_passwd: False/" cloud.cfg)
    user "root"
    cwd "/etc/cloud"
    not_if "grep -q 'lock_passwd: False' /etc/cloud/cloud.cfg"
end

## set ubuntu user password 'bioc' for rstudio
user "ubuntu" do
    action :modify
    password "$6$K48WcQTl$j.DAQ7gxSEOP.VJoJXBlb.xn8GZ/wNHrLXvppMYsca/LsorkWrTYp13FEvNLJ/ghW6QIZdospdU9KilUtkBaX0"
end

## download, install rstudio-server
rstudio_file = node['rstudio_url'].split('/').last
remote_file "/tmp/#{rstudio_file}" do
  source node['rstudio_url']
end

dpkg = `dpkg -s rstudio-server`
execute "install rstudio" do
  command "sudo gdebi -n #{rstudio_file}"
  cwd "/tmp"
  only_if {dpkg.empty?}
end

execute "verify rstudio-server installation" do
    command "rstudio-server verify-installation"
end

execute "switch rstudio-server to port 80" do
    user "root"
    not_if "grep -q www-port /etc/rstudio/rserver.conf"
    command "echo 'www-port=80' > /etc/rstudio/rserver.conf"
end

execute "restart rstudio server" do
    user "root"
    command "rstudio-server restart"
    ignore_failure true
end

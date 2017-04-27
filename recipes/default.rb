execute "update-upgrade" do
  command "apt-get update && apt-get upgrade -y"
  action :run
end

## The node attribute node["reldev"] is defined by the roles 
## AMI_release_linux and AMI_devel_linux. Here a local reldev variable
## is defined and used to drive values of other local variables.
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

pkgs = %w(ack-grep libnetcdf-dev libhdf5-serial-dev sqlite libfftw3-dev 
          libfftw3-doc libopenbabel-dev libfftw3-3 pkg-config xfonts-100dpi 
          xfonts-75dpi libopenmpi-dev openmpi-bin mpi-default-bin 
          openmpi-common libexempi3 openmpi-doc texlive-science python-mpi4py 
          texlive-bibtex-extra texlive-fonts-extra fort77 gfortran 
          libreadline-dev libx11-dev libxt-dev texinfo libxml2-dev 
          libcurl4-openssl-dev xvfb  libpng12-dev libjpeg-dev libcairo2-dev 
          libtiff5-dev tcl8.5-dev tk8.5-dev libicu-dev libgsl2 libgsl-dev 
          libgtk2.0-dev gcj-4.8 openjdk-8-jdk texlive-latex-extra 
          texlive-fonts-recommended libgl1-mesa-dev libglu1-mesa-dev htop 
          libgmp3-dev imagemagick unzip libhdf5-dev libncurses5-dev libbz2-dev 
          libxpm-dev liblapack-dev libv8-3.14-dev libperl-dev 
          libarchive-extract-perl libfile-copy-recursive-perl libcgi-pm-perl 
          tabix libdbi-perl libdbd-mysql-perl ggobi libgtkmm-2.4-dev libssl-dev 
          byacc automake libmysqlclient-dev postgresql-server-dev-all 
          firefox graphviz python-pip libxml-simple-perl texlive-lang-european 
          libmpfr-dev tree python-yaml libmodule-build-perl gdb biber git
          gdebi-core build-essential texlive-full)
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

## ROOT: data analysis framework

remote_file "/tmp/#{node['root_url'][reldev].split("/").last}" do
  source node['root_url'][reldev]
end

directory "/tmp/rootbuild" do
  action :create
end

execute "build root" do
  cwd "/tmp/rootbuild"
  command "tar zxf /tmp/#{node['root_url'][reldev].split("/").last} && cd root && ./configure --prefix=/usr/local/root && make && make install"
  not_if {File.exists? "/tmp/rootbuild/root"}
end

file "/etc/ld.so.conf.d/ROOT.conf" do
  content "/usr/local/root/lib/root"
end

execute "ldconfig" do
  command "ldconfig"
end

execute "add root to path" do
  command "echo 'export PATH=$PATH:/usr/local/root/bin' >> /etc/profile"
  not_if "grep -q /usr/local/root/bin /etc/profile"
end

execute "add rootsys" do
  command "echo 'export ROOTSYS=/usr/local/root' >> /etc/profile"
  not_if "grep -q ROOTSYS /etc/profile"
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

# Ensembl VEP tool

remote_file "/tmp/#{node['vep_dir'][reldev]}.zip" do
  source node['vep_url'][reldev]
end

execute "install VEP" do
  command "unzip #{node['vep_dir'][reldev]} && cd #{node['vep_dir'][reldev]}/scripts && mv variant_effect_predictor /usr/local/ && cd /usr/local/variant_effect_predictor && perl INSTALL.pl --NO_HTSLIB -a a"
  cwd "/tmp"
  not_if {File.exists? "/usr/local/variant_effect_predictor"}
end

# add /usr/local/variant_effect_predictor to path
execute "add vep to path" do
  command "echo 'export PATH=$PATH:/usr/local/variant_effect_predictor' >> /etc/profile"
  not_if "grep -q variant_effect_predictor /etc/profile"
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

execute "install BiocInstaller as root" do
  user "root"
  command %Q(R -e "source('https://bioconductor.org/biocLite.R')")
  not_if {File.exists? "/usr/local/lib/R/library/BiocInstaller"}
end

if reldev == :dev
  execute "run useDevel()" do
    command %Q(R -e "BiocInstaller::useDevel()")
    user "root"
    not_if %Q(R --slave -q -e "BiocInstaller:::IS_USER" | grep -q FALSE)
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

cookbook_file "/tmp/base.R" do
  source "baseBioconductorPackages.R"
  mode 0755
end

execute "install base Bioconductor packages" do
  command %q(R -e "source('/tmp/base.R')")
  user "ubuntu"
  group "ubuntu"
end

## FIXME: Not clean; does not remove dependencies
execute "remove root BiocInstaller" do
  only_if {File.exists? "/usr/local/lib/R/library/BiocInstaller"}
  command %q(R --slave -q -e "remove.packages('BiocInstaller', lib='/usr/local/lib/R/library')")
end

cookbook_file "/tmp/loaded.R" do
  source "loadedBioconductorPackages.R"
  mode 0755
end

execute "install software and annotation Bioconductor packages" do
  command %q(R -e "source('/tmp/loaded.R')")
  user "ubuntu"
  group "ubuntu"
  not_if {File.exists? "/usr/local/lib/R/library/GenomicFeatures"}
end

## latex settings

file "/etc/texmf/texmf.d/01bioc.cnf" do
    content "shell_escape=t"
    owner "root"
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

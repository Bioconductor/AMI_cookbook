default['time_zone'] = "America/New_York"

## At release time these 4 need to be modified:
## 'r_version', 'bioc_version', 'r_url' and 'r_src_dir'
default['r_version'] = {rel: '3.4', dev: '3.5'}
default['bioc_version'] = {rel: '3.6', dev: '3.7'}
default['r_url'] = {rel: 'https://cran.rstudio.com/src/base/R-3/R-3.4.3.tar.gz',
  dev: 'https://stat.ethz.ch/R/daily/R-devel.tar.gz'}
default['r_src_dir'] = {rel: 'R-3.4.3', dev: 'R-devel'}

## System dependencies for R / BioC packages
default['root_url'] = {dev: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz",
  rel: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz"}
default['jags_url'] = {dev: "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz/download",
  rel: "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz/download"}
default['jags_dir'] = {dev: "JAGS-4.2.0", rel: "JAGS-4.2.0"}
default['libsbml_url']  = "https://s3.amazonaws.com/linux-provisioning/libSBML-5.10.2-core-src.tar.gz"
default['libsbml_dir'] = "libsbml-5.10.2"
default['vienna_rna_url'] = "https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_2_x/ViennaRNA-2.2.7.tar.gz"
default['vienna_rna_dir'] = "ViennaRNA-2.2.7"
default['argtable_url'] = "http://prdownloads.sourceforge.net/argtable/argtable2-13.tar.gz"
default['clustalo_url'] = "http://www.clustal.org/omega/clustal-omega-1.2.1.tar.gz"

## vignettes and rstudio
default['pandoc_url'] = "https://github.com/jgm/pandoc/releases/download/1.19.1/pandoc-1.19.1-1-amd64.deb"
default['rstudio_url'] = "https://download2.rstudio.org/rstudio-server-1.1.383-amd64.deb"

## ubuntu writable library
dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE)
lib <- Sys.getenv("R_LIBS_USER")

## ubuntu copy of BiocInstaller
library(BiocInstaller)
biocLite("BiocInstaller", lib=lib, lib.loc=lib, ask=FALSE)

## base packages
library(BiocInstaller, lib.loc=lib)
biocLite(lib=lib, lib.loc=lib, ask=FALSE)

## ubuntu writable library
lib <- gsub(Sys.getenv("R_LIBS_USER"), pattern="~", replacement="/home/ubuntu")
dir.create(lib, recursive=TRUE)

## ubuntu copy of BiocManager
library(BiocManager)
install("BiocManager", lib=lib, lib.loc=lib, ask=FALSE)

## base packages
library(BiocManager, lib.loc=lib)
install(lib=lib, lib.loc=lib, ask=FALSE)

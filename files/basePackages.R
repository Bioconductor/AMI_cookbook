## ubuntu writable library
dir.create(Sys.getenv("R_LIBS_USER"), recursive=TRUE)
lib <- Sys.getenv("R_LIBS_USER")

## ubuntu copy of BiocManager
library(BiocManager)
install("BiocManager", lib=lib, lib.loc=lib, ask=FALSE)

## base packages
library(BiocManager, lib.loc=lib)
install(lib=lib, lib.loc=lib, ask=FALSE)

library(BiocInstaller)

ubuntu_lib <- .libPaths()[1]

## Top 75 software downloads:
url <- "http://www.bioconductor.org/packages/stats/bioc/bioc_pkg_scores.tab"
tbl <- read.table(url, header=TRUE, stringsAsFactors=FALSE)
sorted <- tbl[with(tbl, order(-Download_score, Package)), ]
software <- sorted[1:75, "Package"] 

## Top 30 annotation downloads:
url <- "http://www.bioconductor.org/packages/stats/data-annotation/annotation_pkg_scores.tab"
tbl <- read.table(url, header=TRUE, stringsAsFactors=FALSE)
sorted <- tbl[with(tbl, order(-Download_score, Package)), ]
annotation <- sorted[1:30, "Package"] 

## Top 15 experiment data downloads:
url <- "http://www.bioconductor.org/packages/stats/data-experiment/experiment_pkg_scores.tab"
tbl <- read.table(url, header=TRUE, stringsAsFactors=FALSE)
sorted <- tbl[with(tbl, order(-Download_score, Package)), ]
expdata <- sorted[1:15, "Package"] 

all <- c(software, annotation, expdata)
installed <- rownames(installed.packages(lib.loc=ubuntu_lib))
try <- setdiff(all, installed) 
biocLite(try, lib=ubuntu_lib, lib.loc=ubuntu_lib, ask=FALSE)
success <- rownames(installed.packages(lib.loc=ubuntu_lib))
if (!all(try %in% success)) {
    failed <- try[!try %in% installed]
    msg <- strwrap(paste0("'", failed, "'", collapse=", "))
    stop("packages not installed:\n", paste(msg, collapse="\n"))
}

library(BiocInstaller)
ubuntu_lib <- .libPaths()[1]

## Top 15 experiment data downloads:
url <- "http://www.bioconductor.org/packages/stats/data-experiment/experiment_pkg_scores.tab"
tbl <- read.table(url, header=TRUE, stringsAsFactors=FALSE)
sorted <- tbl[with(tbl, order(-Download_score, Package)), ]
pkgs <- sorted[1:15, "Package"] 

installed <- rownames(installed.packages(lib.loc=ubuntu_lib))
try <- setdiff(pkgs, installed)

for (xx in try) {
   print(paste0("TRYING: ", xx))
   tryCatch({
       biocLite(xx, lib=ubuntu_lib, lib.loc=ubuntu_lib, ask=FALSE)
       print(paste0("INSTALLED: ", xx))
    }, error=function(err) {
        print(paste0("FAILED: ", xx))
    })
}

success <- rownames(installed.packages(lib.loc=ubuntu_lib))
if (!all(try %in% success)) {
    failed <- try[!try %in% installed]
    msg <- strwrap(paste0("'", failed, "'", collapse=", "))
    print(paste0("Data experiment package NOT installed: ", msg))
} else {
    print("All data experiment packages were installed.")
    return
}

library(BiocManager)
ubuntu_lib <- .libPaths()[1]

## Top 75 software downloads:
url <- "http://www.bioconductor.org/packages/stats/bioc/bioc_pkg_scores.tab"
tbl <- read.table(url, header=TRUE, stringsAsFactors=FALSE)
sorted <- tbl[with(tbl, order(-Download_score, Package)), ]
pkgs <- unique(c(sorted[1:75, "Package"],
          "devtools", "knitr", "caTools", "rmarkdown", "BiocStyle"))

installed <- rownames(installed.packages(lib.loc=ubuntu_lib))
try <- setdiff(pkgs, c(installed, "BiocInstaller", "xps", "DESeq"))

for (xx in try) {
   print(paste0("TRYING: ", xx))
   tryCatch({
       BiocManager::install(xx, lib=ubuntu_lib, lib.loc=ubuntu_lib, ask=FALSE)
       print(paste0("INSTALLED: ", xx))
    }, error=function(err) {
        print(paste0("FAILED: ", xx))
    })
}

success <- rownames(installed.packages(lib.loc=ubuntu_lib))
if (!all(try %in% success)) {
    failed <- try[!try %in% installed]
    msg <- strwrap(paste0("'", failed, "'", collapse=", "))
    print(paste0("Software package NOT installed: ", msg))
} else {
    print("All software packages were installed.")
    return
}

install.packages(c('httr', 'plotly', 'png', 'reticulate'), dependencies=TRUE, repos='http://cran.rstudio.com/', Ncpus=20)
install.packages('Seurat', dependencies=TRUE, repos='http://cran.rstudio.com/', Ncpus=20)
library(Seurat)

BiocManager::install("BiocGenerics")
library(BiocGenerics)

install.packages('abind', dependencies=True, repos='http://cran.rstudio.com/', Ncpus=20)
BiocManager::install("S4Vectors")
library(S4Vectors)
BiocManager::install("IRanges")
library(IRanges)

BiocManager::install("S4Arrays")
library(S4Arrays)
BiocManager::install("MatrixGenerics")
library(MatrixGenerics)
BiocManager::install("SparseArray")
library(SparseArray)


BiocManager::install("DelayedArray")
BiocManager::install("SummarizedExperiment")
BiocManager::install("SingleCellExperiment")
BiocManager::install('infercnv', ask=FALSE, update=TRUE)
library(infercnv)
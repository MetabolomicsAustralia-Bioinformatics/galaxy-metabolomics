#!/usr/bin/env Rscript

suppressWarnings(library("tidyverse"))
suppressWarnings(library("MetaboAnalystR"))
suppressWarnings(library("KEGGREST"))
suppressWarnings(library("pathview"))
suppressWarnings(library("httr"))


# Example proc:
# $ Rscript --vanilla metab-de.R /Users/don/Documents/galaxy/test_data/test_dme_data.csv 0.01 0.05 treatment control /Users/don/Documents/galaxy/planemo-test/test-de-out.csv

# TO DO:
# Write out csv
# --help flag


# ========== Function definitions ==========
# Does pathway analysis based on a single column of logFC values (i.e. 2-way by default)


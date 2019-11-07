#!/usr/bin/env Rscript

suppressWarnings(library("tidyverse"))
suppressWarnings(library("MetaboAnalystR"))
suppressWarnings(library("KEGGREST"))

# Example proc:
# $ Rscript --vanilla metab-de.R /Users/don/Documents/galaxy/test_data/test_dme_data.csv 0.01 0.05 treatment control /Users/don/Documents/galaxy/planemo-test/test-de-out.csv

# TO DO:
# Write out csv
# --help flag


# ========== Function definitions ==========
# Does 2-way differential abundance analysis

call_maca_normalization <- function(fn_auc_csv) {
    "Using MetaboAnalystR, does, in the following order: 
    1. Missing value imputation (replaces all zeros with half of the smallest nonzero value)
    2. Row-wise median normalization
    3. Log2-transformation data
    Implemented because I can't be bothered to re-write median normalization from scratch.

    PARAMS
    ------
    fn_auc_csv: str; path to input csv

    RETURNS
    -------
    tbl0: tibble of normalized data, where first column are sample names and second column are groups. 

    Validated against the metaboanalyst.ca output with sepsis data (10 csvs), with an elementwise error of <10e15. 
    "
    mSet<-InitDataObjects("conc", "stat", FALSE)
    mSet<-Read.TextData(mSet, fn_auc_csv, "rowu", "disc");
    mSet<-SanityCheckData(mSet)
    mSet<-ReplaceMin(mSet);
    mSet<-PreparePrenormData(mSet)
    mSet<-Normalization(mSet, "MedianNorm", "LogNorm", "NULL", ratio=FALSE, ratioNum=20)

    # Load and merge the groups column, which mSet annoyingly doesn't have
    tbl0 <- as_tibble(mSet$dataSet$norm, rownames = "Sample")

    tbl_m <- suppressMessages(read_csv(fn_auc_csv))
    sample_colname <- colnames(tbl_m[,1])
    group_colname <- colnames(tbl_m[,2])
    tbl_m <-  tbl_m %>% dplyr::select(c(!!sample_colname, !!group_colname)) %>% dplyr::rename("Sample"=!!sample_colname)
    tbl0 <- inner_join(tbl_m, tbl0, by=eval(sample_colname))

    return(tbl0)
}


lookup_chem_id <- function(cpd_names_vec) {
    "Look up various IDs on KEGG, through MetaboAnalystR.
    Keeps only KEGG and HMDB IDs.
    Cleans up output so that blank or <NA> cells become 'undef'
    Requirements: MetaboAnalystR
    
    PARAMS
    ------
    cpd_names_vec: vector of characters; common chemical names of compounds
    
    RETURNS
    -------
    cpd_names_tbl: tibble of IDs.
    "
    # Call to Kegg
    mset <- InitDataObjects("NA", "utils", FALSE)
    mset <- Setup.MapData(mset, cpd_names_vec)
    mset <- CrossReferencing(mset, "name", T, T, T, T, T)
    mset <- CreateMappingResultTable(mset)
    
    # print warnings
    print(mset$msgset$nmcheck.msg[2])
    cpd_names_tbl <- as_tibble(mset$dataSet$map.table)
    cpd_names_tbl <- cpd_names_tbl %>% dplyr::rename("Sample"="Query")
    cpd_names_tbl <- cpd_names_tbl %>% dplyr::select("Sample", "KEGG", "HMDB")

    # replace NA, string "NA", or empty cell with string "undef"
    cpd_names_tbl[cpd_names_tbl == ""] <- "undef"
    cpd_names_tbl[cpd_names_tbl == "NA"] <- "undef"
    cpd_names_tbl <- cpd_names_tbl %>% replace(., is.na(.), "undef")
    
    return(cpd_names_tbl)
}


get_de_metabs <- function(tbl, input_alpha, grp_numerator, grp_denominator, input_fdr) {
    "Takes a tibble of cleaned, transformed values as input, and does:
    1. t-tests at input_alpha
    2. BH correction at input_fdr
    3. Computes FC of averages. Assumes log2 abundances as input, so this is computed as mu1 - mu2. 
    4. Gets FC colours

    PARAMS
    ------
    tbl: input tibble of metabolite abundances, with sample names in col1 and group names in col2. 
    input_alpha: float; alpha at which t-tests are applied.
    grp_numerator: numerator of class/group for fold change calculations
    grp_denominator: denominator of class/group for fold change calculations
    input_fdr: float; threshold p-value at which the benjamini-hochberg method is applied. All results are returned; only affects FC colour assigned. 

    OUTPUT
    ------
    tbl: tibble with the following column names:
        'Sample': str; compound name
        'fc': float; fold change of log2-abundances. 
        'KEGG': str; KEGG Id, retrieved through MetaboAnalystR. 
        'HMDB': str; HMDB Id, retrieved through MetaboAnalystR.
        'raw_p_val': float; raw p-value, output through the t-test.
        'adj_p_val': float; adjusted p-value, computed through the Benjamini-Hochberg procedure.
        'fc_colour': str; colour of fold changes, in hex colour code. 

    NOTES
    -----
     * Unknown KEGG and HMDB Ids get replaced with string `undef`. 
     * Doesn't actually matter if the input tbl has more than 2 groups; groups that are not required do not get
     picked up by %>% filter() anyway. 
     * In FC computations, assumes that the input tibble already has log-abundances, therefore FC = log(x) - log(y), 
     s.t. FC = log(x/y) 
     * Thresholding occurs at >log2(1.25) and <log2(0.75). 
    "
    group.name.col <- names(tbl[,2])
    metab_names <- colnames(tbl)[3:length(colnames(tbl))]
    # Init vec of t.stats p-vals, and FCs
    # Compute t-stats
    p.vals.ls <- vector(mode="numeric", length = length(metab_names))
    fc.ls <- vector(mode="numeric", length = length(metab_names))
    for (i in 1:length(metab_names)) {
        g1.vec <- as.vector(unlist(tbl %>% filter(!!sym(group.name.col)==grp_numerator) %>% select(metab_names[i])))
        g2.vec <- as.vector(unlist(tbl %>% filter(!!sym(group.name.col)==grp_denominator) %>% select(metab_names[i])))

        x <- t.test(g1.vec, g2.vec, conf.level=1-input_alpha)
        p.vals.ls[i] <- x$p.value

        mu1 <- mean(g1.vec)
        mu2 <- mean(g2.vec)
        fc.ls[i] <- mu1 - mu2
    }
    
    names(p.vals.ls) <- metab_names
    names(fc.ls) <- metab_names

    # adjust: BH correction
    adj.p.vals.ls <- p.adjust(p.vals.ls, method = "hochberg", n = length(p.vals.ls))

    # Compute ipath colours: non-significant, FC-up, FC-down, FC-neutral
    fc.colour.ls <- rep("#ACACAC", ncol(tbl)) # default gray (non-significant)
    names(fc.colour.ls) <- metab_names
    for (nm in metab_names) {
        if (adj.p.vals.ls[nm] < input_fdr) {
            if (fc.ls[nm] > 0.22314) {
                fc.colour.ls[nm] <- "#0571b0" #blue
            } else if (fc.ls[nm] < -0.28768) {
                fc.colour.ls[nm] <- "#ca0020" #red
            } else {
                fc.colour.ls[nm] <- "#000000" #black
            }
        }
    }

    # Get all KEGG IDs
    chem.id.tbl <- lookup_chem_id(metab_names)
    kegg.id.vec <- as.vector(unlist(chem.id.tbl %>% select("KEGG")))
    
    # enframe and merge all named lists
    fc.tbl <- tibble::enframe(fc.ls) %>% rename("log2_fc"=value, "Sample"=name)
    p.val.tbl <- tibble::enframe(p.vals.ls) %>% rename("raw_p_val"=value, "Sample"=name)
    adj.p.val.tbl <- tibble::enframe(adj.p.vals.ls) %>% rename("adj_p_val"=value, "Sample"=name)
    fc.colour.tbl <- tibble::enframe(fc.colour.ls) %>% rename("fc_colour"=value, "Sample"=name)
    tbl <- list(fc.tbl, chem.id.tbl, p.val.tbl, adj.p.val.tbl, fc.colour.tbl) %>% reduce(inner_join, by = "Sample")
    
    return(tbl)
}

# ========== run ==========

args = commandArgs(trailingOnly=TRUE)

input_fn <- args[1] # absolute path of input csv
p_val <- as.numeric(args[2]) # p-value for t-tests
q_val <- as.numeric(args[3]) # FDR value
grp_num <- args[4] # name of numerator
grp_denom <- args[5] # name of denom
out_fn <- args[6] # output filename

#write(meta_fn, stderr())
normalized_data_tbl <- call_maca_normalization(input_fn)
de_tbl <- get_de_metabs(normalized_data_tbl, p_val, "treatment", "control", q_val)
print(head(de_tbl))

write.csv(de_tbl, out_fn, row.names=FALSE)


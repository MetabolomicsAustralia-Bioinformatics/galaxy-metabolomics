#!/usr/bin/env Rscript

suppressMessages(library("xcms"))
suppressMessages(library("plotly"))
suppressMessages(library("RColorBrewer"))
suppressMessages(library("tidyverse"))

args = commandArgs(trailingOnly=TRUE)

project_path <- args[1]
meta_fn <- args[2]
write(meta_fn, stderr())
output_plot_fn <- args[3]

# Read all mzXML files in specified dir from first argument
fn.ls <- list.files(path = project_path, pattern="\\.mzXML")
write("\nRead the following .mzXML files as input:", stderr())
write(paste0(paste(rep("-", 30), collapse=""), "\n"), stderr())
write(paste0(fn.ls, collapse="\n"), stderr())

# Read metadata csv from second argument
tbl.m <- suppressMessages(read_csv(meta_fn))
write(paste("Read ", args[2], " as metadata"), stderr())


# "Acquisition Parameters" - Parameters relating to the acquisition -------
# ========== Chromatography parameters ==========
# Tuned to faahKO data (Agilent 1100 400 bar HPLC)
rtStart <- 1    # Start region of interest (in seconds)
rtEnd <- "max"  # End region of interest (in seconds). "max" for RT full range
FWHM_min <- 10  # FWHM in seconds of narrowest peak
FWHM_max <- 90  # FWHM in seconds of broadest peak
rtDelta <- 3705-3673   # Max observed difference in retention time (s) across all
# samples (peak-apex to peak-apex).

# ========== MS parameters ==========
# Tuned for faahKO data (Agilent MSD SL ion trap)
mzPol <- "negative" # Set to "positive" or "negative" ion mode
mzStart <- 100  # Start of m/z region of interest
mzEnd <- 1650   # End of m/z region of interest
mzErrAbs <- 0.01 # Max m/z delta expected for the same feature across all samples
mzZmax <- 3     # Max charge state expected
EICsMax <- 30   # Max number of chrom. peaks expected for a single EIC
sens <- 1      # Factor (between 0 and 1) for peak extraction sensitivity
# Impacts peak picking thresholds, RAM & CPU utilisation.
# Start with ~0.5.
fileType <- "mzXML" # MS data file type e.g. "mzData", "mzML", "mzXML", "CDF"


# ======================================== QC of all files ========================================
# Get group colours
group.colours <- brewer.pal(3, "Set1")
names(group.colours) <- unique(unlist(as.vector(tbl.m["sample_group"])))

# Allocate colour to each sample, coloured by group
group.vec <- as.vector(unlist(tbl.m[,"sample_group"]))
sample.colours.ls <- vector(mode="character", length=nrow(tbl.m))
for (i in 1:length(group.vec)) {
  colour <- unlist(as.vector(group.colours[group.vec[i]]))
  sample.colours.ls[i] <- colour
}

# read all data files
write("Reading data...", stderr())
raw_data <- readMSData(files = paste0(project_path, fn.ls), pdata = new("NAnnotatedDataFrame", tbl.m), mode = "onDisk")
write("Done.\n", stderr())

## Get the base peak chromatograms. This reads data from the files.
#png("./overlaid_BPSchromatograms.png", width = 1024, height = 768, units = "px")
write("Init chromatogram()...", stderr())
bpis <- chromatogram(raw_data, aggregationFun = "max")
write("Done.\n", stderr())

# Plot
png(output_plot_fn, width = 1024, height = 768, units = "px")
plot(bpis, col = sample.colours.ls)
legend("topright", box.lwd = 2, 
       legend=c(tbl.m$sample_group), 
       pch=c(15, 15,15, 16, 16,16,17,17,17),
       col = sample.colours.ls, xpd=FALSE)

dev.off()
write(paste0("Output plot to ", output_plot_fn), stderr())




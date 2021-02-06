library(tidyverse)
library(glue)

args <- commandArgs(T)

id <- args[1]
datadir <- args[2]

load("dl.rdata")

dat <- subset(uniquelist, newid == id)
pops <- str_split(dat$pop, ",")[[1]]

outfile <- file.path(datadir, paste0(dat$newid, "_", pop, ".gz"))

outfile <- paste0(dat$newid, "_", pop, ".gz")

format_file <- function(infile, pop, outfile, cols)
{
	con <- gzfile(infile, "r")
	a <- readLines(con, n=1) %>% str_split(., "\t")
	close(con)

	low_confidence <- which(cols == paste0("low_confidence_", pop))
	beta <- which(cols == paste0("beta_", pop))
	se <- which(cols == paste0("se_", pop))
	pval <- which(cols == paste0("pval_", pop))

	chr <- which(cols == paste0("chr"))
	pos <- which(cols == paste0("pos"))
	ref <- which(cols == paste0("ref"))
	alt <- which(cols == paste0("alt"))

	if(any(grepl("af_controls", a)))
	{
		af <- which(cols == paste0("af_controls_", pop))
	} else {
		af <- which(cols == paste0("af_", pop))
	}

	tempoutfile <- gsub(".gz", "", outfile)

	cmd <- glue(
		"zcat {infile} | awk '{{ if(${low_confidence} == \"false\" && ${af} > 0.01 && ${af} < 0.99) {{ print ${chr}, ${pos}, ${ref}, ${alt}, ${af}, ${beta}, ${se}, ${pval} }} }}' > {tempoutfile}"
	)
	system(cmd)
	nsnpfile <- paste0(tempoutfile, ".nsnp")
	system(glue("cat {tempoutfile} | wc -l > {nsnpfile}"))
	system(glue("gzip {tempoutfile}"))
}


library(tidyverse)
library(glue)

format_file <- function(infile, pop, outfile)
{
	con <- gzfile(infile, "r")
	cols <- readLines(con, n=1) %>% str_split(., "\t") %>% {.[[1]]}
	close(con)

	low_confidence <- which(cols == paste0("low_confidence_", pop))
	beta <- which(cols == paste0("beta_", pop))
	se <- which(cols == paste0("se_", pop))
	pval <- which(cols == paste0("pval_", pop))

	chr <- which(cols == paste0("chr"))
	pos <- which(cols == paste0("pos"))
	ref <- which(cols == paste0("ref"))
	alt <- which(cols == paste0("alt"))

	if(any(grepl("af_controls", cols)))
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

args <- commandArgs(T)

id <- args[1]
datadir <- args[2]

load("dl.rdata")

dat <- subset(uniquelist, newid == id)
pops <- str_split(dat$pop, ",")[[1]]

print(str(dat))
message(paste(pops, collapse=", "))

lapply(pops, function(pop)
{
	message(pop)
	outfile <- file.path(datadir, "ready", paste0(dat$newid, "_", pop, ".gz"))
	format_file(
		infile=file.path(datadir, "raw", paste0(dat$newid, ".bgz")),
		pop=pop,
		outfile
	)
})


library(tidyverse)
library(glue)
library(stringr)

format_file <- function(infile, pop, outfile)
{
	message("Getting columns")
	con <- gzfile(infile, "r")
	cols <- readLines(con, n=1) %>% str_split(., "\t") %>% {.[[1]]}
	close(con)

	message("Matching columns")
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

	message("Parsing input file")
	cmd <- glue(
		"zcat {infile} | awk '{{ if(${low_confidence} == \"false\" && ${af} > 0.01 && ${af} < 0.99) {{ print ${chr}, ${pos}, ${ref}, ${alt}, ${af}, ${beta}, ${se}, ${pval} }} }}' > {tempoutfile}"
	)
	system(cmd)
	message("SNP count")
	nsnpfile <- paste0(tempoutfile, ".nsnp")
	system(glue("cat {tempoutfile} | wc -l > {nsnpfile}"))
	message("gzipping")
	system(glue("gzip -f {tempoutfile}"))
}

args <- commandArgs(T)

id <- args[1]
datadir <- args[2]

# expect id to be <fileid>_<pop>
fileid <- str_sub(id, 1, -5)
pop <- str_sub(id, -3, -1)

message(id)
message(fileid)
message(pop)

format_file(
	infile=file.path(datadir, "raw", paste0(fileid, ".bgz")),
	pop=pop,
	outfile=file.path(datadir, "ready", paste0(id, ".gz"))
)


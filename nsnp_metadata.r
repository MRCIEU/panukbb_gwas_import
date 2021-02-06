library(tidyverse)
library(magrittr)
library(jsonlite)

datadir <- read_json("config.json")

nsnp <- tibble(
	nsnpfiles = list.files(".", "*.nsnp"),
	nsnp = sapply(seq_along(nsnpfiles), function(i)
	{
		scan(nsnpfiles[i], what="numeric")
	})
)

nrow(nsnp)

load("dl.rdata")
nrow(keeplist)

b <- keeplist %$% tibble(
	id=paste0("ukbb-e-", id)),
	pmid=NA,
	year=2020,
	filename=file.path(datadir),
	mr=1,
	trait=description,
	category=case_when(
		n_controls == 0 ~ "Continuous",
		TRUE ~ "Binary"
	),
	subcategory="NA",
	population=case_when(
		pop == "AFR" ~ "Sub-Saharan African",
		pop == "MID" ~ "Greater Middle Eastern (Middle Eastern, North African, or Persian)",
		pop == "EAS" ~ "East Asian",
		pop == "CSA" ~ "South Asian",
		pop == "AMR" ~ "Hispanic or Latin American"
	),
	sex=case_when(
		pheno_sex == "both_sexes" ~ "Males and Females",
		pheno_sex == "females" ~ "Females",
		pheno_sex == "males" ~ "Males"
	),
	ncase=n_cases,
	ncontrol=n_controls,
	sample_size=n_total,
	group_name="public",
	access="public",
	build="HG19/GRCh37",
	author="Pan-UKB team",
	chr_col=0,
	pos_col=1,
	ea_col=2,
	oa_col=3,
	eaf_col=4,
	beta_col=5,
	se_col=6,
	pval_col=7,
	delimiter="space",
	header=FALSE
)

b <- inner_join(b, nsnp, by="id")

str(b)
write.csv(b, file.path(datadir, "ready", "input.csv"))
write.csv(b, "input.csv")

library(tidyverse)
library(readxl)
library(jsonlite)

datadir <- read_json("config.json")$datadir

# read in 
fulllist <- readxl::read_xlsx("Pan-UK Biobank phenotype manifest.xlsx", sheet=1)
fulllist <- subset(fulllist, !grepl("raw$", modifier))
fulllist$traitnum <- 1:nrow(fulllist)
fulllist$newid <- NA
fulllist$trait <- NA

# total number
a <- strsplit(fulllist$pops, ",")
length(unlist(a))
table(unlist(a))

# numeric columns need to be coerced
pops <- c("MID", "CSA", "EAS", "AMR", "AFR", "EUR")
vars <- c("n_controls", "n_cases", "saige_heritability")
expand.grid(pops=pops, vars=vars) %>%
	mutate(v = paste0(vars, "_", pops)) %>%
	{.$v} %>%
	lapply(., function(x)
	{
		fulllist[[x]] <<- as.numeric(fulllist[[x]])
		fulllist[[x]][is.na(fulllist[[x]])] <<- 0
		return(x)
	})



# unique phenocodes
tempgood <- fulllist %>%
	group_by(phenocode) %>%
	summarise(n = n()) %>%
	filter(n == 1)

index <- fulllist$phenocode %in% tempgood$phenocode
fulllist$trait[index] <- fulllist$description[index]
fulllist$newid[index] <- fulllist$phenocode[index]

# check phenocode - should be unique for each one
temp <- fulllist %>%
	group_by(phenocode) %>%
	summarise(n = n()) %>%
	filter(n > 1)

# Ok sometimes the same trait is binarised
subset(fulllist, phenocode == temp$phenocode[1]) %>% 
	select(description, pheno_sex, description_more, coding_description, n_cases_EUR, n_controls_EUR) %>%
	str

# where description is unique within phenocode
temp0 <- fulllist %>%
	group_by(phenocode, description) %>%
	summarise(n=n(), traitnum = traitnum[1]) %>%
	filter(n == 1 & phenocode %in% temp$phenocode) %>%
	arrange(phenocode)

index <- fulllist$traitnum %in% temp0$traitnum
fulllist$trait[index] <- fulllist$description[index]
fulllist$newid[index] <- fulllist$phenocode[index]


temp1 <- fulllist %>%
	group_by(phenocode, description) %>%
	summarise(n=n()) %>%
	filter(n > 1) %>%
	arrange(phenocode)

sum(temp$n)
sum(temp1$n)


# most duplicate phenocodes also have duplicate phenocode/description combo
subset(fulllist, phenocode == temp1$phenocode[1]) %>% 
	select(description, pheno_sex, description_more, coding_description, n_cases_EUR, n_controls_EUR) %>%
	str

subset(fulllist, phenocode == temp1$phenocode[1])$coding_description

subset(fulllist, phenocode %in% temp1$phenocode & trait_type == "categorical") %>%
	summarise(nchar = nchar(coding_description)) %>%
	{summary(.$nchar)}

subset(fulllist, phenocode %in% temp1$phenocode & trait_type == "categorical") %>%
	summarise(nchar = nchar(description)) %>%
	{summary(.$nchar)}

subset(fulllist, phenocode %in% temp1$phenocode & trait_type == "categorical") %>%
	summarise(newname = paste0(description, ": ", coding_description), nchar = nchar(newname)) %>%
	arrange(desc(nchar))

index <- fulllist$traitnum %in% subset(fulllist, phenocode %in% temp1$phenocode & trait_type == "categorical")$traitnum

fulllist$trait[index] <- paste0(fulllist$description[index], ": ", fulllist$coding_description[index])
fulllist$newid[index] <- fulllist$phenocode[index]

table(is.na(fulllist$trait))
table(is.na(fulllist$newid))

x <- fulllist %>%
	group_by(newid) %>%
	summarise(n=n()) %>%
	filter(n > 1)

newidv <- fulllist %>% group_by(newid) %>%
	mutate(newid = paste0(newid, "_p", 1:n())) %>%
	{.$newid}

dupid <- subset(fulllist, duplicated(newid))$newid %>% unique
length(dupid)

fulllist$newid[fulllist$newid %in% dupid] <- newidv[fulllist$newid %in% dupid]

index <- grepl("[aeiou]", fulllist$newid)
fulllist$newid[index] <- paste0("recode", 1:sum(index))

# keep 
## sample size > 900
## n_cases >= 200

keeplist <- lapply(pops, function(pop)
{
	fulllist %>%
		dplyr::select(
			newid,
			description,
			aws_link,
			pheno_sex,
			n_cases=paste0("n_cases_", pop),
			n_controls=paste0("n_controls_", pop),
			saige_heritability=paste0("saige_heritability_", pop)
		) %>%
		mutate(
			pop=pop,
			n_cases = as.numeric(n_cases),
			n_controls = as.numeric(n_controls),
			saige_heritability = as.numeric(saige_heritability),
		) %>%
		mutate(
			n_cases = case_when(
				n_cases == NA ~ 0,
				TRUE ~ n_cases
			),
			n_controls = case_when(
				n_controls == NA ~ 0,
				TRUE ~ n_controls
			),
			n_total = n_cases + n_controls
		) %>%
		filter(n_cases >= 200 & n_total >= 900) %>%
		mutate(id = paste0(newid, "_", pop))
}) %>% bind_rows()

# check that one newid per aws_link
group_by(keeplist, aws_link) %>% summarise(n = length(unique(newid))) %>% {table(.$n)}

# how many pops per keeplist
table(keeplist$pop)

# create a list of unique files to download
uniquelist <- keeplist %>% 
	group_by(aws_link) %>%
	summarise(newid = first(newid), pop = paste(pop, collapse=","))

# how many files?
dim(uniquelist)

save(fulllist, uniquelist, keeplist, file="dl.rdata")

write.table(uniquelist$newid, file="filelist.txt", row=F, col=F, qu=F)
write.table(keeplist$id, file="idlist.txt", row=F, col=F, qu=F)

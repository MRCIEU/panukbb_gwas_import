library(parallel)
library(jsonlite)

config <- read_json("config.json")
dir.create(file.path(config$datadir, "raw"))

load("dl.rdata")

uniquelist$destination <- file.path("raw", paste0(uniquelist$newid, ".bgz"))

mclapply(1:nrow(uniquelist), function(i)
{
	download.file(
		uniquelist$aws_link[i],
		file.path(config$datadir, uniquelist$destination[i])
	)
}, mc.cores=3)


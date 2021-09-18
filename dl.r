library(parallel)
library(jsonlite)

config <- read_json("config.json")
dir.create(file.path(config$datadir, "raw"))

load("dl.rdata")

uniquelist$destination <- file.path("raw", paste0(uniquelist$newid, ".bgz"))
out <- file.path(config$datadir, uniquelist$destination)
table(file.exists(out))
uniquelist <- uniquelist[!file.exists(out), ]

o <- mclapply(1:nrow(uniquelist), function(i)
{
	message(i, " of ", nrow(uniquelist))
	out <- file.path(config$datadir, uniquelist$destination[i])
	if(!file.exists(out))
	{
		download.file(
			uniquelist$aws_link[i],
			file.path(config$datadir, uniquelist$destination[i])
		)
	}
}, mc.cores=3)



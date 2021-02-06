import os
import json


with open("config.json", "r") as f:
	config = json.load(f)

datadir = config['datadir']
os.makedirs(datadir + "/ready", exist_ok=True)
os.makedirs("job_reports", exist_ok=True)

with open("filelist.txt", "r") as f:
	files = [x.strip() for x in f.readlines()]

with open("idlist.txt", "r") as f:
	ids = [x.strip() for x in f.readlines()]


rule all:
	input:
		expand("{datadir}/ready/{ids}.gz", datadir=datadir, ids=ids),
		expand("{datadir}/ready/input.csv", datadir=datadir)

# Download all the files

rule dl:
	input:
		"dl.rdata"
	output:
		expand("{datadir}/raw/{files}.bgz", datadir=datadir, files=files)
	shell:
		"Rscript dl.r"


rule dl_complete:
	input:
		expand("{datadir}/raw/{files}.bgz", datadir=datadir, files=files)
	output:
		"dl_complete.flag"
	shell:
		"touch dl_complete.flag"


# Split each file into a single dataset per required ancestry
# Note, not keeping all ancestries per trait due to sample size cutoffs

rule format:
	input:
		"dl_complete.flag"
	output:
		"{datadir}/ready/{ids}.gz"
	shell:
		"Rscript format_dl.r {wildcards.ids} {datadir}"

# Update metadata with numbers of SNPs

rule metadata:
	input:
		"dl.rdata"
	output:
		"{datadir}/ready/input.csv"
	shell:
		"Rscript nsnp_metadata.r"


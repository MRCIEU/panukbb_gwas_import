import os
import json


with open("config.json", "r") as f:
	config = json.load(f)

datadir = config['datadir']
os.makedirs(datadir + "/ready", exist_ok=True)
os.makedirs(datadir + "/job_reports", exist_ok=True)

with open("filelist.txt", "r") as f:
	files = [x.strip() for x in f.readlines()][1:10]

with open("idlist.txt", "r") as f:
	ids = [x.strip() for x in f.readlines()][1:10]


rule all:
	input:
		expand("{datadir}/ready/{ids}.gz", datadir=datadir, ids=ids),
		"input.csv"

# Download all the files

rule dl:
	input:
		"dl.rdata"
	output:
		expand("{datadir}/raw/{files}.gz", datadir=datadir, files=files)
	shell:
		"Rscript dl.r"

# Split each file into a single dataset per required ancestry
# Note, not keeping all ancestries per trait due to sample size cutoffs

rule format:
	input:
		expand("{datadir}/raw/{files}.gz", datadir=datadir, files=files)
	output:
		"{datadir}/ready/{ids}.gz"
	shell:
		"Rscript format_dl.r {wildcards.ids} {datadir}"

# Update metadata with numbers of SNPs

rule metadata:
	input:
		"dl.rdata"
	output:
		"ready/input.csv"
	shell:
		"Rscript nsnp_metadata.r"


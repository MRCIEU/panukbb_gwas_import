#!/bin/bash

datadir=$(cat config.json | jq -r .datadir)

# fixing ukbb-e to ukb-e in scripts

sed -i 's/ukbb-e/ukb-e/g' input.csv
sed -i 's/ukbb-e/ukb-e/g' nsnp_metadata.r
sed -i 's/ukbb-e/ukb-e/g' igd-hpc-pipeline/idlist.txt


# fixing ukbb-e to ukb-e in data

cd $datadir
rename ukbb-e ukb-e ready/*json
sed -i 's/ukbb-e/ukb-e/g' ready/*json
sed -i 's/ukbb-e/ukb-e/g' ready/input.csv
sed -i 's/ukbb-e/ukb-e/g' ready/input_json.csv

rename ukbb-e ukb-e processed/*
rename ukbb-e ukb-e processed/*/*
sed -i 's/ukbb-e/ukb-e/g' processed/*/*json
sed -i 's/ukbb-e/ukb-e/g' processed/*/ldsc.txt.log

for id in processed/*
do
	id=$(basename $id)
	echo $id
	bcftools view -h processed/$id/$id.vcf.gz | sed 's/ukbb-e/ukb-e/g' > temp
	bcftools reheader -h temp -o processed/$id/$id.vcf.gz processed/$id/$id.vcf.gz
done

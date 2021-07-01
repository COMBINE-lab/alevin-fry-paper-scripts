#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
refs_dir=$top_dir/refs

refs="refdata-gex-mm10-2020-A refdata-cellranger-mm10-2.1.0 dr-101-cr-ref"
for ref in $refs;
do
	ref_dir=$refs_dir/$ref
	if [ $ref = "dr-101-cr-ref" ]; then
		gunzip $ref_dir/genes/genes.gtf.gz
	fi
	gffread $ref_dir/genes/genes.gtf -o $ref_dir/genes/genes.gff
	grep "gene_name" $ref_dir/genes/genes.gff | cut -f9 | cut -d';' -f2,3 | sed 's/=/ /g' | sed 's/;/ /g' | cut -d' ' -f2,4 | sort | uniq > $ref_dir/geneid_to_name.txt
done

### adding the id2name for mito sequences
echo $'ENSMUSG00000064337.1 ENSMUSG00000064337.1\nENSMUSG00000064339.1 ENSMUSG00000064339.1' >> $refs_dir/refdata-gex-mm10-2020-A/geneid_to_name.txt
echo $'ENSMUSG00000064337.1 ENSMUSG00000064337.1\nENSMUSG00000064339.1 ENSMUSG00000064339.1' >> $refs_dir/refdata-cellranger-mm10-2.1.0/geneid_to_name.txt
echo $'CK739347.1 CK739347.1\nEH454886.1 EH454886.1' >> $refs_dir/dr-101-cr-ref/geneid_to_name.txt

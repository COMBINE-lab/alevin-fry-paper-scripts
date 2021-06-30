#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
refs_dir=$top_dir/refs

refs=(refdata-gex-mm10-2020-A refdata-cellranger-mm10-2.1.0 cr_index_dr101)
for ref in ${refs[@]};
do
	ref_dir=$refs_dir/$ref
	gffread $ref_dir/genes/genes.gtf -o $ref_dir/genes/genes.gff
	grep "gene_name" $ref_dir/genes/genes.gff | cut -f9 | cut -d';' -f2,3 | sed 's/=/ /g' | sed 's/;/ /g' | cut -d' ' -f2,4 | sort | uniq > $ref_dir/geneid_to_name.txt
done

### adding the id2name for mito sequences
cat "ENSMUSG00000064337.1\tENSMUSG00000064337.1\nENSMUSG00000064339.1\tENSMUSG00000064339.1" >> $refs_dir/refdata-gex-mm10-2020-A/geneid_to_name.txt
cat "ENSMUSG00000064337.1\tENSMUSG00000064337.1\nENSMUSG00000064339.1\tENSMUSG00000064339.1" >> $refs_dir/refdata-cellranger-mm10-2.1.0/geneid_to_name.txt
cat "CK739347.1\tCK739347.1\nEH454886.1\tEH454886.1" >> $refs_dir/cr_index_dr101/geneid_to_name.txt

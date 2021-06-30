#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

topd_dir=$(jq -r '.top_dir' ${config})
mkdir -p $top_dir/permit_lists

##cellranger v2 and v3 barcodes
wget https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/translation/3M-february-2018.txt.gz
gunzip 3M-february-2018.txt.gz
cut -f1 3M-february-2018.txt > $top_dir/permit_lists/10xv3barcodes.txt
rm 3M-february-2018.txt

wget https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/737K-august-2016.txt
mv 737K-august-2016.txt $top_dir/permit_lists/10xv2barcodes.txt

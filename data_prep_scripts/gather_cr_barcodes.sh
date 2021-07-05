#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
permit_dir="$top_dir/permit_lists"
mkdir -p $permit_dir

tmp_dir="$top_dir/_tmp"
mkdir $tmp_dir

##cellranger v2 and v3 barcodes
curl -L https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/translation/3M-february-2018.txt.gz -o $tmp_dir/3M-february-2018.txt.gz
gunzip $tmp_dor/3M-february-2018.txt.gz
cut -f1 $tmp_dir/3M-february-2018.txt > $permit_dir/10xv3barcodes.txt

curl -L https://raw.githubusercontent.com/10XGenomics/cellranger/master/lib/python/cellranger/barcodes/737K-august-2016.txt -o $tmp_dir/737K-august-2016.txt
mv $tmp_dir/737K-august-2016.txt $permit_dir/10xv2barcodes.txt

rm -r $tmp_dir

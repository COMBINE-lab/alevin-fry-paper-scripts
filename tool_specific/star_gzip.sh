#!/bin/bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${top_dir})

samples="dr_pineal_s2 mouse_placenta"
for sample in $samples; do
	gzip -k $top_dir/results/star_solo/$sample/star_solo/Solo.out/Gene/raw/barcodes.tsv
	gzip -k $top_dir/results/star_solo/$sample/star_solo/Solo.out/Gene/raw/features.tsv
	gzip -k $top_dir/results/star_solo/$sample/star_solo/Solo.out/Gene/raw/matrix.mtx
	if [ $sample == "dr_pineal_s2" ]; then
		for type in "1mm_dir exact"; do
			gzip -k $top_dir/results/star_solo/$sample/star_solo_$type/Solo.out/Gene/raw/barcodes.tsv
			gzip -k $top_dir/results/star_solo/$sample/star_solo_$type/Solo.out/Gene/raw/features.tsv
			gzip -k $top_dir/results/star_solo/$sample/star_solo_$type/Solo.out/Gene/raw/matrix.mtx
		done
	fi
done

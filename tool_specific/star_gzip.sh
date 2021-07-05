#!/bin/bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})

samples="dr_pineal_s2 mouse_placenta"
for sample in $samples; do
	cmd="gzip -k $top_dir/results/star_solo/$sample/star_solo/Solo.out/Gene/raw/barcodes.tsv"
	echo $cmd
	eval $cmd
	cmd="gzip -k $top_dir/results/star_solo/$sample/star_solo/Solo.out/Gene/raw/features.tsv"
	echo $cmd
	eval $cmd
	cmd="gzip -k $top_dir/results/star_solo/$sample/star_solo/Solo.out/Gene/raw/matrix.mtx"
	echo $cmd
	eval $cmd
	if [ $sample == "dr_pineal_s2" ]; then
		modes="1mm_dir exact"
		for type in $modes; do
			cmd="gzip -k $top_dir/results/star_solo/$sample/star_solo_$type/Solo.out/Gene/raw/barcodes.tsv"
			echo $cmd
			eval $cmd
			cmd="gzip -k $top_dir/results/star_solo/$sample/star_solo_$type/Solo.out/Gene/raw/features.tsv"
			echo $cmd
			eval $cmd
			cmd="gzip -k $top_dir/results/star_solo/$sample/star_solo_$type/Solo.out/Gene/raw/matrix.mtx"
			echo $cmd
			eval $cmd
		done
	fi
done

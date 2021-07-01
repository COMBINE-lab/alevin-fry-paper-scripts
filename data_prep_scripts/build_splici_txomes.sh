#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

if [[ $# -ge 2 ]]; then
	refs_csv=$2
else
	echo "Please provide the refs csv file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
refs_dir=$top_dir/refs
flank_trim_length=$(jq -r '.flank_trim_length' ${config})
while IFS=, read -r name ref_dir ind_type read_length extra_spliced; do
	gtf_path="$refs_dir/$ref_dir/genes/genes.gtf"
	genome_path="$refs_dir/$ref_dir/fasta/genome.fa"
	splici_dir="$refs_dir/$ref_dir/transcriptome_splici/"

	let flank_length=$read_length-$flank_trim_length
	fasta="$refs_dir/$ref_dir/transcriptome_splici/transcriptome_splici_fl$flank_length.fa"
	extra_spliced_seqs=../mito_seqs/$extra_spliced
	if [ ! -f $fasta ]; then
		cmd="Rscript build_splici_txome.R $gtf_path $genome_path $read_length $flank_trim_length $splici_dir $extra_spliced_seqs"
		echo $cmd
		eval $cmd
	fi
done < $refs_csv

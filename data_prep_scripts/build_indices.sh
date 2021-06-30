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

indices_dir=$top_dir/indices
refs_dir=$top_dir/refs

kb=$(jq -r '.kb_binary' ${config})
star=$(jq -r '.star_binary' ${config})
salmon=$(jq -r '.salmon_binary' ${config})

threads=$(jq -r '.threads' ${config})
flank_trim_length=$(jq -r '.flank_trim_length' ${config})
force_build=$(jq -r '.force_build' ${config})

if [ $indices_dir = null ] || [ $threads = null ] || [ $kb = null ] || [ $star = null ] || [ $salmon = null ]; then
	echo "The config file is missing some information"
	echo "It should include the following: indices_dir, threads, kb_binary, star_binary and salmon_binary"
	exit
fi

while IFS=, read -r name ref_name ind_type read_length code; do

	ref_dir="$refs_dir/$ref_name"
	gtf="$ref_dir/genes/genes.gtf"
	genome="$ref_dir/fasta/genome.fa"
	index_dir="$indices_dir/$name"

	if [ -z $name ] || [ -z $ref_dir ] || [ -z $ind_type ]; then
		echo "Some fields are missing in the CSV file"
		echo "For each reference, it should include: name, refference dir and index type"
		exit
	fi
	### build kb index
	kb_dir="$index_dir/kb_index/"
	mkdir -p $kb_dir

	if [[ $ind_type == "standard" ]];
	then
		cmd="/usr/bin/time -v -o $kb_dir/index.time $kb ref -i $kb_dir/index.idx -g $kb_dir/t2g.txt \
			 -f1 $kb_dir/cdna.fa --workflow standard $genome $gtf"
	else
		cmd="/usr/bin/time -v -o $kb_dir/index.time $kb ref -i $kb_dir/index.idx -g $kb_dir/t2g.txt \
			 -f1 $kb_dir/cdna.fa -f2 $kb_dir/intron.fa -c1 $kb_dir/cdna_t2c.txt \
			 -c2 $kb_dir/intron_t2c.txt --workflow $ind_typ $genome $gtf"
	fi
	if [ ! -f $kb_dir/index.idx ] || [ $force_build = "true" ]; then
		echo $cmd
		eval $cmd
	fi

	## build star index
	star_dir="$index_dir/star_index/"
	mkdir -p $star_dir

	cmd="/usr/bin/time -v -o $star_dir/index.time $star --runMode genomeGenerate --runThreads $threads \
			--gnomeDir $star_dir --genomeFastaFiles $genome --sjdbGTFfile $gtf"
	if [ ! -f $star_dir/SA ] || [ $force_build = "true" ]; then
		echo $cmd
		eval $cmd
	fi

	### build salmon index
	let flank_length=$read_length-$flank_trim_length
	fasta="$ref_dir/transcriptome_splici/transcriptome_splici_fl$flank_length.fa"

	salmon_dir="$index_dir/salmon_fl${flank_trim_length}_index/"
	mkdir -p $salmon_dir
	cmd="/usr/bin/time -v -o $salmon_dir/index.time $salmon index -i $salmon_dir -t $fasta -p $threads"
	if [ ! -f $salmon_dir/pos.bin ] || [ $force_build = "true" ]; then
		echo $cmd
		eval $cmd
	fi
	
	salmon_dir="$index_dir/salmon_fl${flank_trim_length}_index_sparse/"
	mkdir -p $salmon_dir
	cmd="/usr/bin/time -v -o $salmon_dir/index.time $salmon index -i $salmon_dir -t $fasta -p $threads --sparse"
	if [ ! -f $salmon_dir/pos.bin ] || [ $force_build = "true" ]; then
		echo $cmd
		eval $cmd
	fi

	if [ $name = "human-cr3" ]; then
		fasta="$ref_dir/transcriptome.fa"
		salmon_dir="$index_dir/salmon_txome_index/"
		mkdir -p $salmon_dir
		cmd="/usr/bin/time -v -o $salmon_dir/index.time $salmon index -i $salmon_dir -t $fasta -p $threads"
		echo $cmd
		eval $cmd
	fi
done < $refs_csv

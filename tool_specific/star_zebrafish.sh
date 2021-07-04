#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
threads=$(jq -r '.threads' ${config})
star=$(jq -r '.star_binary' ${config})

index_dir=$top_dir/indices/dr-101/star_index/
permitlist="$top_dir/permit_lists/10xv2barcodes.txt"
fastq_dir=$top_dir/samples/dr_pineal_s2_rl98/
reads1="$fastq_dir/SRR8315379_R1.fastq.gz,$fastq_dir/SRR8315380_R1.fastq.gz"
reads2="$fastq_dir/SRR8315379_R2.fastq.gz,$fastq_dir/SRR8315380_R2.fastq.gz"
reads="$reads2 $reads1"

### run star with 1MM_dir umi-deduplication
output="$top_dir/results/star_solo/dr_pineal_s2/star_solo_1mm_dir/"
mkdir -p $output

cmd="/usr/bin/time -v -o $output/solo.time $star --genomeDir $index_dir --outFileNamePrefix $output --soloType CB_UMI_Simple --soloUMIlen 10 --soloCBlen 16 --readFilesIn $reads --readFilesCommand zcat --soloCBwhitelist $permitlist --limitIObufferSize 50000000 50000000 --outSJtype None --outSAMtype None --runThreadN $threads --soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --soloUMIdedup 1MM_Directional --soloCellFilter EmptyDrops_CR --clipAdapterType CellRanger4 --outFilterScoreMin 30 --soloFeatures Gene"
echo $cmd
eval $cmd

### run star with exact umi-deduplication
output="$top_dir/results/star_solo/dr_pineal_s2/star_solo_exact/"
mkdir -p $output

cmd="/usr/bin/time -v -o $output/solo.time $star --genomeDir $index_dir --outFileNamePrefix $output --soloType CB_UMI_Simple --soloUMIlen 10 --soloCBlen 16 --readFilesIn $reads --readFilesCommand zcat --soloCBwhitelist $permitlist --limitIObufferSize 50000000 50000000 --outSJtype None --outSAMtype None --runThreadN $threads --soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --soloUMIdedup Exact --soloCellFilter EmptyDrops_CR --clipAdapterType CellRanger4 --outFilterScoreMin 30 --soloFeatures Gene"
echo $cmd
eval $cmd

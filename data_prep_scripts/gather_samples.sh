#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
tmp_dir=$top_dir/_tmp
samples_dir=$top_dir/samples

mkdir -p $tmp_dir
mkdir -p $samples_dir

### pbmc10k
echo "Downloading the pbmc 10k sample"
pbmc_dir=$samples_dir/human-pbmc10k_v3_rl91
mkdir -p $pbmc_dir
curl -L https://cg.10xgenomics.com/samples/cell-exp/3.0.0/pbmc_10k_v3/pbmc_10k_v3_fastqs.tar -o $tmp_dir/pbmc_10k_v3_fastqs.tar
tar -xf $tmp_dir/pbmc_10k_v3_fastqs.tar -C $tmp_dir
mv $tmp_dir/pbmc_10k_v3_fastqs/* $pbmc_dir/

### the zebrafish sample
echo "Downloading the zebrafish sample"
dr_dir=$samples_dir/dr_pineal_s2_rl98
mkdir -p $dr_dir
curl -L ftp://ftp.ebi.ac.uk/vol1/fastq/SRR831/000/SRR8315380/SRR8315380_1.fastq.gz -o $dr_dir/SRR8315380_R1.fastq.gz
curl -L ftp://ftp.ebi.ac.uk/vol1/fastq/SRR831/000/SRR8315380/SRR8315380_2.fastq.gz -o  $dr_dir/SRR8315380_R2.fastq.gz
curl -L ftp://ftp.ebi.ac.uk/vol1/fastq/SRR831/009/SRR8315379/SRR8315379_1.fastq.gz -o  $dr_dir/SRR8315379_R1.fastq.gz
curl -L ftp://ftp.ebi.ac.uk/vol1/fastq/SRR831/009/SRR8315379/SRR8315379_2.fastq.gz -o  $dr_dir/SRR8315379_R2.fastq.gz

### the mouse plancenta
echo "Downloading the mouse placenta sample"
sn_dir=$samples_dir/nucleus_mouse_placenta_E14.5_rl150
mkdir -p $sn_dir
srr_list145=(SRR11993485 SRR11993486 SRR11993487 SRR11993488)
for x in ${srr_list145[@]};
do
        echo $x
        fastq-dump --outdir $sn_dir --split-files --gzip $x;
done


### the mouse pancreas
echo "Downloading the mouse plancreas sample"
velo_dir=$samples_dir/velocity_mouse_pancreas_rl151
mkdir -p $velo_dir
curl -L http://ftp.ebi.ac.uk/vol1/fastq/SRR920/004/SRR9201794/SRR9201794_1.fastq.gz -o $velo_dir/SRR9201794_1.fastq.gz
curl -L http://ftp.ebi.ac.uk/vol1/fastq/SRR920/004/SRR9201794/SRR9201794_2.fastq.gz -o  $velo_dir/SRR9201794_2.fastq.gz

rm -r $tmp_dir

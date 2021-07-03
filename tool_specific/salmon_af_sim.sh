#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
threads=$(jq -r '.threads' ${config})

salmon=$(jq -r '.salmon_binary' ${config})
fry=$(jq -r '.alevinfry_binary' ${config})

splici_index=$top_dir/indices/human-cr3/salmon_fl91_index
txomic_index=$top_dir/indices/human-cr3/salmon_txome_index
results_dir=$top_dir/results

output_dir=$top_dir/results
fastq_dir=$top_dir/samples/pbmc_5k_sims_human_CR_3.0.0_MultiGeneNo_rl91/
mkdir -p $output_dir

t2g=$top_dir/indices/human-cr3/kb_index/t2g.txt
t2g_3cols=$top_dir/indices/human-cr3/salmon_fl91_index/t2g_3col.tsv

unf_list=$top_dir/permit_lists/10xv3barcodes.txt

read1=$(ls $fastq_dir | awk -v p=$fastq_dir '{print p$0}' | grep "R1") 
read2=$(ls $fastq_dir | awk -v p=$fastq_dir '{print p$0}' | grep "R2") 

### run salmon-alevinfry in SLA mode
output="$output_dir/salmon_sla"
mkdir -p $output
mkdir -p $output/logs

cmd="/usr/bin/time -v -o $output/logs/pseudoalignment.time $salmon alevin -l ISR \
        -i $splici_index -1 $read1 -2 $read2 -o $output -p 16 --chromiumV3  --rad"
echo $cmd
eval $cmd

bash ./run_alevinfry.sh $fry $output $t2g_3cols $threads knee
bash ./run_alevinfry.sh $fry $output $t2g_3cols $threads unfilt $unf_list

mv $output/quant_unfilt $results_dir/alevin_fry/sim_data/fry_sla_unfilt_quant_usa_cr-like
mv $output/quant_knee $results_dir/alevin_fry/sim_data/fry_sla_knee_quant_usa_cr-like
### run salmon-alevinfry in txomic mode
output="$output_dir/salmon_txomic"
mkdir -p $output
mkdir -p $output/logs

cmd="/usr/bin/time -v -o $output/logs/pseudoalignment.time $salmon alevin -l ISR \
        -i $txomic_index -1 $reads1 -2 $reads2 -o $output -p 16 --chromiumV3  --rad --sketch"
echo $cmd
eval $cmd

bash ./run_alevinfry.sh $fry $output $t2g $threads knee
bash ./run_alevinfry.sh $fry $output $t2g $threads unfilt $unf_list

mv $output/quant_unfilt $results_dir/alevin_fry/sim_data/fry_unfilt_quant_txome_cr-like
mv $output/quant_knee $results_dir/alevin_fry/sim_data/fry_knee_quant_txome_cr-like

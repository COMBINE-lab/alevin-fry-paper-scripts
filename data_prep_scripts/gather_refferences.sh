#!/usr/bin/env bash

if [[ $# -ge 1 ]]; then
	config=$1
else
	echo "Please provide the config file"
	exit
fi

top_dir=$(jq -r '.top_dir' ${config})
cr=$(jq -r '.cr_binary' ${config})

tmp_dir=$top_dir/_tmp
refs_dir=$top_dir/refs

mkdir -p $tmp_dir
mkdir -p $refs_dir

### human 2020A
wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz -P $tmp_dir
tar -xzf $tmp_dir/refdata-gex-GRCh38-2020-A.tar.gz -C $refs_dir

### human CR3
wget https://cf.10xgenomics.com/supp/cell-exp/refdata-cellranger-GRCh38-3.0.0.tar.gz -P $tmp_dir
tar -xzf $tmp_dir/refdata-cellranger-GRCh38-3.0.0.tar.gz -C $refs_dir
cr3ref="$refs_dir/refdata-cellranger-GRCh38-3.0.0"
gffread -w $cr3ref/transcriptome.fa -g $cr3ref/fasta/genome.fa $cr3ref/genes/genes.gtf

### mm10 2020A
wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-mm10-2020-A.tar.gz -P $tmp_dir
tar -xzf $tmp_dir/refdata-gex-mm10-2020-A.tar.gz -C $refs_dir

### mm10 2.1.0
wget http://cf.10xgenomics.com/supp/cell-exp/refdata-cellranger-mm10-2.1.0.tar.gz -P $tmp_dir
tar -xzf $tmp_dir/refdata-cellranger-mm10-2.1.0.tar.gz -C $refs_dir

### dr 101
dr_dir=$refs_dir/dr-101
dr_cr_dir=$refs_dir/dr-101-cr-ref
wget ftp://ftp.ensembl.org/pub/release-101/gtf/danio_rerio/Danio_rerio.GRCz11.101.gtf.gz -P $dr_dir
wget ftp://ftp.ensembl.org/pub/release-101/fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna_sm.primary_assembly.fa.gz -P $dr_dir
gunzip $dr_dir/Danio_rerio.GRCz11.101.gtf.gz
gunzip $dr_dir/Danio_rerio.GRCz11.dna_sm.primary_assembly.fa.gz

gtf_in="$dr_dir/Danio_rerio.GRCz11.101.gtf"
gtf_out="$dr_dir/Danio_rerio.GRCz11.101filtered.gtf"
dna="$dr_dir/Danio_rerio.GRCz11.dna_sm.primary_assembly.fa"

cmd="$cr mkgtf $gtf_in $gtf_out \
                   --attribute=gene_biotype:protein_coding \
                   --attribute=gene_biotype:lincRNA \
                   --attribute=gene_biotype:antisense \
                   --attribute=gene_biotype:IG_LV_gene \
                   --attribute=gene_biotype:IG_V_gene \
                   --attribute=gene_biotype:IG_V_pseudogene \
                   --attribute=gene_biotype:IG_D_gene \
                   --attribute=gene_biotype:IG_J_gene \
                   --attribute=gene_biotype:IG_J_pseudogene \
                   --attribute=gene_biotype:IG_C_gene \
                   --attribute=gene_biotype:IG_C_pseudogene \
                   --attribute=gene_biotype:TR_V_gene \
                   --attribute=gene_biotype:TR_V_pseudogene \
                   --attribute=gene_biotype:TR_D_gene \
                   --attribute=gene_biotype:TR_J_gene \
                   --attribute=gene_biotype:TR_J_pseudogene \
                   --attribute=gene_biotype:TR_C_gene"
echo $cmd
eval $cmd

cmd="$cr mkref --genome=dr_cr_dir  --fasta=$dna --genes=$gtf_out"
echo $cmd
eval $cmd
mv dr_cr_dir $dr_cr_dir
### create gene_id to gene_name files
bash geneid2names.sh $config

rm -r $tmp_dir

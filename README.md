# Scripts used in the manuscript "Alevin-fry unlocks rapid, accurate, and memory-frugal quantification of single-cell RNA-seq data"

This directory includes the scripts for gathering and analyzing the data used in the alevin-fry manuscript.


First of all, make sure you have enough available space on your disk. Then clone the repository and navigate to the main directory of the repo:
```
$git clone git@github.com:COMBINE-lab/alevin-fry-paper-scripts.git
$cd alevin-fry-paper-scripts
```

In order to run all the scripts in this repository, please make sure you have the binaries for running the fallowing tools.

* [salmon](https://github.com/COMBINE-lab/salmon)

* [alevin-fry](https://github.com/COMBINE-lab/alevin-fry)

* [STARsolo](https://github.com/alexdobin/STAR)

* [kb (kallisto|bustools)](https://github.com/pachterlab/kb_python)

* [Cell Ranger](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/5.0/)

Also, please note that before executing each bash script, you should either make the bash files executable or use `bash ` before the commands.

### Gathering the references

First of all, edit the config file `configs/config.json` to include the relavent paths for `cellranger`, `kb`, `starsolo`, `salmon` and `alevin-fry` binaries. Also, set the `top_dir` in the config file to the address of the directory where you want to save all the files generated by these scritps.

Navigate to the `data_prep_scripts` directory and execute the `gather_refferences.sh` script for downloading the references.
```
$cd data_prep_scripts
$./gather_refferences.sh ../configs/config.json
```

If the script finishes running with no problem, you should have the following files available in the `refs` directory:
```
refs/refdata-gex-GRCh38-2020-A/fasta/genome.fa
refs/refdata-gex-GRCh38-2020-A/genes/genes.gtf

refs/refdata-cellranger-GRCh38-3.0.0/fasta/genome.fa
refs/refdata-cellranger-GRCh38-3.0.0/genes/genes.gtf
refs/refdata-cellranger-GRCh38-3.0.0/transcriptome.fa

refs/refdata-gex-mm10-2020-A/fasta/genome.fa
refdata-gex-mm10-2020-A/genes/genes.gtf
refdata-gex-mm10-2020-A/geneid_to_name.txt

refs/refdata-cellranger-mm10-2.1.0/fasta/genome.fa
refs/refdata-cellranger-mm10-2.1.0/genes/genes.gtf
refs/refdata-cellranger-mm10-2.1.0/geneid_to_name.txt

refs/dr-101-cr-ref/fasta/genome.fa
refs/dr-101-cr-ref/genes/genes.gtf
refs/dr-101-cr-ref/geneid_to_name.txt
```

### Generating splici transcriptome for the alevin-fry pipeline

Before starting this step, make sure the required packages (`eisaR`, `Biostrings`, `BSgenome`, `stringr`, `GenomicFeatures`) are installed for R version 4 on your system.


We need to build the splici reference which includes the intronic regions of the genes as well as the transcripts. To do so, please execute the `build_splici_txomes.sh` script.
```
$./build_splici_txomes.sh ../configs/config.json refs.csv
```

If this script runs successfully, you should be able to locate the following files:
```
refs/refdata-gex-GRCh38-2020-A/transcriptome_splici/transcriptome_splici_fl91_t2g.tsv
refs/refdata-gex-GRCh38-2020-A/transcriptome_splici/transcriptome_splici_fl91_t2g_3col.tsv
refs/refdata-gex-GRCh38-2020-A/transcriptome_splici/transcriptome_splici_fl91.fa

refs/refdata-cellranger-GRCh38-3.0.0/transcriptome_splici/transcriptome_splici_fl91_t2g.tsv
refs/refdata-cellranger-GRCh38-3.0.0/transcriptome_splici/transcriptome_splici_fl91_t2g_3col.tsv
refs/refdata-cellranger-GRCh38-3.0.0/transcriptome_splici/transcriptome_splici_fl91.fa

refs/refdata-cellranger-mm10-2.1.0/transcriptome_splici/transcriptome_splici_fl151_t2g.tsv
refs/refdata-cellranger-mm10-2.1.0/transcriptome_splici/transcriptome_splici_fl151_t2g_3col.tsv
refs/refdata-cellranger-mm10-2.1.0/transcriptome_splici/transcriptome_splici_fl151.fa

refs/refdata-gex-mm10-2020-A/transcriptome_splici/transcriptome_splici_fl150_t2g.tsv
refs/refdata-gex-mm10-2020-A/transcriptome_splici/transcriptome_splici_fl150_t2g_3col.tsv
refs/refdata-gex-mm10-2020-A/transcriptome_splici/transcriptome_splici_fl150.fa

refs/dr-101-cr-ref/transcriptome_splici/transcriptome_splici_fl98_t2g.tsv
refs/dr-101-cr-ref/transcriptome_splici/transcriptome_splici_fl98_t2g_3col.tsv
refs/dr-101-cr-ref/transcriptome_splici/transcriptome_splici_fl98.fa
```

### Building the indices

Run the `build_indices.sh` script for building all the indices.
```
$./build_indices.sh ../configs/config.json refs.csv
```

Successfully running this step means that all the indices (salmon, starsolo and kb) are available in the following directories:
```
indices/human-cr3
indices/human-2020A
indices/mm10-2.1.0
indices/mm10-2020A
indices/dr-101
```

### Downloading the 10x barcode lists

To download the 10x permitlists for version 2 and version 3 chemistries, run the `gather_cr_barcodes.sh` script.
```
$./gather_cr_barcodes.sh ../configs/config.json
```

After this step the following files should be available:
```
permit_lists/10xv2barcodes.txt
permit_lists/10xv3barcodes.txt
```

### Gathering the samples

To download all the experimental samples used in the manuscript, please run:
```
$./gather_samples.sh ../configs/config.json
```

After the successful run of the script you should be able to find the fastq files at the following directories:
```
samples/human-pbmc10k_v3_rl91
samples/dr_pineal_s2_rl98
samples/nucleus_mouse_placenta_E14.5_rl150
samples/velocity_mouse_pancreas_rl151
```

To generate the simulated dataset used in the manuscript, please follow the instructions available in the [STARsolo manuscript repository](https://github.com/dobinlab/STARsoloManuscript) for simulating the data with realisitic intronic and intergenic fragment distributions (but without gene-level multimapping). Then place both the biological and technical reads in a directory named `samples/pbmc_5k_sims_human_CR_3.0.0_MultiGeneNo_rl91`.

### Running the Nextflow pipeline

Navigate to the `nf_pipeline` directory and edit the config file in order to run the nextflow pipeline. Also the download the Nextflow executable from [here](https://www.nextflow.io/).
```
$cd ../nf_pipeline
$curl -s https://get.nextflow.io | bash
```

The `nextflow` executable should be downloaded and placed in the working directory (`nf_pipeline`). To configure the nextflow, open the `configs/nf.config` and put the address for `salmon`, `alevinfry`, `star_solo` and `kb` binaries in the lines 18 to 21. Also set the value of the `top.dir` parameter at line 15, to the same value you used for `top_dir` in the `config.json` file. Then run the nextflow pipeline by:

```
$./launch.sh -n nextflow
```

This pipeline will perform single cell pre-processing with all three tools (`alevinfry`, `starsolo` and `kb`) for all the five datasets and the results for all the samples should be available at:

```
results/alevin_fry
results/star_solo
results/kb
```

### Running the different alevin-fry modes for the simulated sample

For the simualted sample, we evaluate results with different modes of alevinfry, to do so, navigate to `tool_specific` directory and execute the `salmon_af_sim.sh` script.

```
$cd ../tool_specific
$./salmon_af_sim.sh ../configs/config.json
```

Executing this script should lead to generating these results:
```
results/alevin_fry/sim_data/fry_sla_unfilt_quant_usa_cr-like
results/alevin_fry/sim_data/fry_unfilt_quant_txome_cr-like
```

### Running the different starsolo specific scripts
Run the `star_zebrafish.sh` to generate the star output with different umi-deduplication strategies for the zebrafish sample.
```
$./star_zebrafish.sh ../configs/config.json
```

Executing this script should lead to generating these results:
```
results/star_solo/dr_pineal_s2/star_solo_1mm_dir
results/star_solo/dr_pineal_s2/star_solo_exact
```

Then, run the `star_gzip.sh` script.
```
$./star_gzip.sh ../configs/config.json
```

### Comparing the performance of different tools

To generated the timing and peak memory plots, navigate to `notebooks` directory and open the jupyter notebook `plot-time-rss.ipynb`. Then, execute all the commands in the notebook in order.

### Computing the accuracy metrics for the simulated sample

Navigate to `notebooks` directory and run all the lines in the `starsolo_sim_analysis.ipynb` jupyter notebook in order.

### Velocity analysis for the mouse pancreas dataset

To generate the RNA velocity streamlines plots and the latent time plots, navigate to `analysis_scripts/mouse_pancreas_velocity` and run the jupyter notebook files. 
- For alevin-fry counts, run `mouse_pancreas_af_velocity_analysis.ipynb`.
- For STARsolo counts, run `mouse_pancreas_st_velocity_analysis.ipynb`.
- For kallisto|bustools counts, run `mouse_pancreas_kb_velocity_analysis.ipynb`.

### Clustering analyses for the mouse placenta dataset 

To generate the t-SNE plots and the dotplot of the expression of the cell type markers, navigate to `analysis_scripts/mouse_placenta_clustering` directory and run the RMD files in RStudio. 
- For alevin-fry counts, run `mouse_placenta_nuclei_p14.5_alevinfry_analysis.Rmd`.
- For STARsolo counts, run `mouse_placenta_nuclei_p14.5_starsolo_analysis.Rmd`.
- For kallisto|bustools counts, run `mouse_placenta_nuclei_p14.5_kb_analysis.Rmd`.

### Gene expression analysis for the zebrafish pineal dataset

To generate the t-SNE plots and the dotplot of the expression of the cell type markers, navigate to `analysis_scripts/zebrafish_pineal_expression` directory and run the `zebrafish_pineal_expression_analysis.Rmd` in RStudio. 


nextflow.enable.dsl=2

include { get_permit_list } from './utils.nf'

def starsolo_index_for(org_name) {
  switch(org_name) {
    case "human-2020A":
      return params.star.index_human_2020A
    case "human-cr3":
      return params.star.index_human_cr3
    case "mouse-cr2":
      return params.star.index_mouse_cr2
    case "mouse-2020A":
      return params.star.index_mouse_2020A
    case "zebrafish":
      return params.star.index_zebrafish
  }
}

def starsolo_chem_flags(chem) {
  switch(chem) {
    case "v2":
      return "--soloType CB_UMI_Simple --soloUMIlen 10 --soloCBlen 16"
    case "v3":
      return "--soloType CB_UMI_Simple --soloUMIlen 12 --soloCBlen 16"
  }
}

def starsolo_process_type_flags(ptype) {
  switch(ptype) {
    case "single-cell":
      return "--soloFeatures Gene"
    case "single-nucleus":
      return "--soloFeatures GeneFull --soloBarcodeReadLength 0"
    case "velocity":
      return "--soloFeatures Gene Velocyto"
  }
}

process star_solo_quant {
  tag "star_solo:${name}"

  cpus 16

   publishDir "${params.output_dir}/star_solo"

  input:
    tuple val(name), val(dir), val(read1), val(read2), val(chem), val(ptype), val(org)
    

  output:
    path "${name}/**"
    
  script:
    def idx = starsolo_index_for(org)
    def chemistry = starsolo_chem_flags(chem)
    def permitlist = get_permit_list(chem)
    def ptflag = starsolo_process_type_flags(ptype)
    def odir = "${name}/star_solo"
    def reads1 = read1.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x}.join(',')
    def reads2 = read2.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x}.join(',')
    """
      mkdir -p ${name}/logs
      ${params.timecmd} -v -o ${name}/logs/solo.time $params.bin.star_solo \
--genomeDir ${idx} --outFileNamePrefix ${odir}/ ${chemistry} \
--readFilesIn ${reads2} ${reads1} --readFilesCommand zcat \
--soloCBwhitelist $permitlist --limitIObufferSize 50000000 50000000 \
--outSJtype None --outSAMtype None \
--runThreadN ${task.cpus} \
--soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --soloUMIfiltering MultiGeneUMI_CR \
--soloUMIdedup 1MM_CR --soloCellFilter EmptyDrops_CR \
--clipAdapterType CellRanger4 --outFilterScoreMin 30 \
${ptflag}
    """

   stub:
    def idx = starsolo_index_for(org)
    def chemistry = starsolo_chem_flags(chem)
    def permitlist = get_permit_list(chem)
    def ptflag = starsolo_process_type_flags(ptype)
    def odir = "${name}/star_solo"
    def reads1 = read1.split(' ').collect{ x -> dir + "/" + x}.join(',')
    def reads2 = read2.split(' ').collect{ x -> dir + "/" + x}.join(',')
    def cmdstr = """${params.timecmd} -v -o ${name}/logs/solo.time \
$params.bin.star_solo --genomeDir ${idx} --outFileNamePrefix ${odir}/ ${chemistry} \
--readFilesIn ${reads2} ${reads1} --readFilesCommand zcat \
--soloCBwhitelist $permitlist --limitIObufferSize 50000000 50000000 \
--outSJtype None --outSAMtype None \
--runThreadN ${task.cpus} \
--soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts --soloUMIfiltering MultiGeneUMI_CR \
--soloUMIdedup 1MM_CR --soloCellFilter EmptyDrops_CR \
--clipAdapterType CellRanger4 --outFilterScoreMin 30 \
${ptflag}
"""
    
    """
      echo Running :: "${cmdstr}"
      mkdir -p ${name}/logs
      mkdir -p ${odir}/Solo.out
      touch ${name}/logs/solo.time
      touch ${odir}/Solo.out/Barcodes.stats
    """
}


workflow ss_process {
  take: samp

  main:
    star_solo_quant(samp)

  emit:
    star_solo_quant.out[0]
}


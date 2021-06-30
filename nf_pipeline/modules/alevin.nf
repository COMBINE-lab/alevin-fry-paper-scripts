nextflow.enable.dsl=2

include { get_permit_list } from './utils.nf'

def suffix_for_index_type(index_type) {
  switch(index_type) {
    case "dense" : 
      return ""
    case "sparse" :
      return "_sparse"
  }
}

/*
* based on the name of an organism, return the appropriate salmon
* index.
* NOTE: probably want some way to specify dense vs sparse!
*/
def salmon_index_for(org_name, index_type) {
  switch(org_name) {
    case "human-2020A":
      return params.salmon.index_human_2020A + suffix_for_index_type(index_type)
    case "human-cr3":
      return params.salmon.index_human_cr3 + suffix_for_index_type(index_type)
    case "mouse-cr2":
      return params.salmon.index_mouse_cr2 + suffix_for_index_type(index_type)
    case "mouse-2020A":
      return params.salmon.index_mouse_2020A + suffix_for_index_type(index_type)
    case "zebrafish":
      return params.salmon.index_zebrafish + suffix_for_index_type(index_type)
  }
}

def alevin_t2g(org_name) {
  switch(org_name) {
    case "human-2020A":
      return params.salmon.t2g_human_2020A
    case "human-cr3":
      return params.salmon.t2g_human_cr3
    case "mouse-2020A":
      return params.salmon.t2g_mouse_2020A
    case "mouse-cr2":
      return params.salmon.t2g_mouse_cr2
    case "zebrafish":
      return params.salmon.t2g_zebrafish
  }
}

/*
* extract the flag that should be passed to alevin
* for the chemistry based on the chemistry type of a
* sample.  Currently, everything is Chromium v2 or v3
* and so that is all this currently supports
*/
def salmon_chem_flag(chem) {
  switch(chem) {
    case "v2":
      return "chromium"
    case "v3":
      return "chromiumV3"
  }
}

/*
* This process takes an input sample
* as defined by the columns in the sample table csv
* and runs `alevin` on it to produce a RAD file.
* Currently, sketch mode is always used.
*/
process salmon_map_rad {
    tag "salmon_map_${index_type}:${name}"

    cpus 16

    input:
    tuple val(name), val(dir), val(read1), val(read2), val(chem), val(ptype), val(org)
    val index_type
    val ss_done
    
    output:
    path name
    val chem
    path "${name}/alevin_map_${index_type}"
    file "${name}/alevin_map_${index_type}/map.rad"
    file "${name}/alevin_map_${index_type}/unmapped_bc_count.bin"
    val org
    
    script:
    def idx = salmon_index_for(org, index_type)
    def chemistry = salmon_chem_flag(chem)
    def odir = "${name}/alevin_map_${index_type}"
    def reads1 = read1.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x }.join(" ")
    def reads2 = read2.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x }.join(" ")
    """
      mkdir -p ${name}/logs/
      $params.timecmd -v -o ${name}/logs/map_sketch_${index_type}.time $params.bin.salmon alevin -i $idx -l ISR -1 ${reads1} -2 ${reads2} -p ${task.cpus} --${chemistry} --sketch -o ${odir} 
    """

    stub:
    def idx = salmon_index_for(org, index_type)
    def chemistry = salmon_chem_flag(chem)
    def odir = "${name}/alevin_map_${index_type}"
    def reads1 = read1.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x }.join(" ")
    def reads2 = read2.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x }.join(" ")
    """
      echo ${reads1}
      echo ${reads2}
      mkdir -p ${odir}
      mkdir -p ${name}/logs
      touch ${name}/logs/map_sketch_${index_type}.time
      touch ${odir}/map.rad
      touch ${odir}/unmapped_bc_count.bin
    """
}

/*
* This process takes the output produced by the 
* `salmon_map_rad` rule and generates a permit list 
* with alevin-fry (currently using the knee method).
*/
process alevin_fry_gpl {
  tag "fry_gpl:${name}:${filt_type}"

  cpus 16

  input:
    path name
    val chem
    path map_dir
    path rad_file 
    path unmapped_bin
    val filt_type

  output:
    path name
    path map_dir
    path "${name}/permitlist_${filt_type}_fw" 
    path "${name}/permitlist_${filt_type}_fw/permit_map.bin" 

  script:
    def permitlist = get_permit_list(chem)
    def filt_flag = (filt_type == "knee") ? "-k" : "-u ${permitlist}"
    def opath = "permitlist_${filt_type}_fw"
    """
      mkdir -p ${name}/logs/
      $params.timecmd -v -o ${name}/logs/permitlist_${filt_type}.time $params.bin.afry generate-permit-list ${filt_flag} -d fw -i ${map_dir} -o ${name}/${opath}
    """
  
  stub:
    def permitlist = get_permit_list(chem)
    def filt_flag = (filt_type == "knee") ? "-k" : "-u ${permitlist}"
    def opath = "permitlist_${filt_type}_fw"
    def cmd = """
$params.timecmd -v -o ${name}/logs/permitlist_${filt_type}.time $params.bin.afry generate-permit-list ${filt_flag} -d fw -i ${map_dir} -o ${name}/${opath}
"""

    """
      echo "running ${cmd}"
      echo ${map_dir}
      echo ${name}/${opath}
      mkdir ${name}/${opath}
      mkdir ${name}/${opath}/logs
      touch ${name}/${opath}/permit_map.bin
    """
}

/*
* This process takes the output produced by the 
* `alevin_fry_gpl` rule and generates a collated 
* RAD file.
*/
process alevin_fry_collate {
  tag "fry_collate:${name}:${filt_type}"
  cpus 16

  input:
    path name
    val filt_type
    path map_dir
    path permit_dir
    path permit_bin

  output:
    path name
    path permit_dir

  script:
    """
    $params.timecmd -v -o ${name}/logs/collate_${filt_type}.time $params.bin.afry collate \
-i ${permit_dir} -r ${map_dir} -t ${task.cpus} 
    """

  stub:
  def cmd = """$params.timecmd -v -o ${name}/logs/collate_${filt_type}.time $params.bin.afry collate \
-i ${permit_dir} -r ${map_dir} -t ${task.cpus} 
"""
  """
  echo "executing :: ${cmd}"
  mkdir -p ${permit_dir}
  touch ${permit_dir}/map.collated.rad
  """
}

/*
* This process takes the output produced by the 
* `alevin_fry_collate` rule and generates the resulting
* quantification.
*/
process alevin_fry_quant {
  tag "fry_quant:${name}:${filt_type}"

  cpus 16

  publishDir "${params.output_dir}/alevin_fry"
  
  input:
    path name
    path collate_dir 
    val filt_type
    val org

  output:
    path "${name}/logs/*"
    path "${name}/fry_${filt_type}_quant_usa_cr-like/**"

  script:
    def t2g = alevin_t2g(org)
    def odir = "${name}/fry_${filt_type}_quant_usa_cr-like/"
    def cmd = """$params.timecmd -v -o ${name}/logs/quant_${filt_type}.time $params.bin.afry quant \
-r cr-like --use-mtx -m ${t2g} -i ${collate_dir} -o ${odir} -t ${task.cpus}
"""
    """
      mkdir -p ${name}/logs
      ${cmd}
    """

  stub:
    def t2g = alevin_t2g(org)
    def odir = "${name}/fry_${filt_type}_quant_usa_cr-like/"
    def cmd = """$params.timecmd -v -o ${name}/logs/quant_${filt_type}.time $params.bin.afry quant \
-r cr-like --use-mtx -m ${t2g} -i ${collate_dir} -o ${odir} -t ${task.cpus}
"""
    """
      echo "executing :: ${cmd}"
      mkdir -p ${name}/logs
      mkdir -p ${name}/fry_${filt_type}_quant_usa_cr-like/
      touch ${name}/logs/quant_${filt_type}.time
      touch ${name}/fry_${filt_type}_quant_usa_cr-like/meta_info.json
    """
}

workflow af_map {
  take: 
    samp
    ss_done

  main: 
    salmon_map_rad(samp, "dense", ss_done)

  emit:
    salmon_map_rad.out[5]
    salmon_map_rad.out[0]
    salmon_map_rad.out[1] 
    salmon_map_rad.out[2] 
    salmon_map_rad.out[3] 
    salmon_map_rad.out[4] 
}

// NOTE: there *must* be a better way to do this
workflow af_map_sparse {
  take: 
    samp
    ss_done

  main: 
    salmon_map_rad(samp, "sparse", ss_done)

  emit:
    salmon_map_rad.out[5]
    salmon_map_rad.out[0]
    salmon_map_rad.out[1] 
    salmon_map_rad.out[2] 
    salmon_map_rad.out[3] 
    salmon_map_rad.out[4] 
}

workflow af_gpl {
  take: 
    sname
    chem
    map_path
    rad_file
    unmapped_file
    filt_type

  main: 
    alevin_fry_gpl(sname, chem, map_path, rad_file, unmapped_file, filt_type)

  emit: 
    alevin_fry_gpl.out[0]
    alevin_fry_gpl.out[1]
    alevin_fry_gpl.out[2]
    alevin_fry_gpl.out[3]
}

workflow af_collate {
  take: 
    name
    map_dir
    permit_dir
    permit_map_file
    filt_type
  
  main: 
    alevin_fry_collate(name, filt_type, map_dir, permit_dir, permit_map_file)

  emit: 
    alevin_fry_collate.out[0]
    alevin_fry_collate.out[1]
}

workflow af_quant {
  take: 
    sname
    collate_dir
    filt_type
    org

  main: 
    alevin_fry_quant(sname, collate_dir, filt_type, org)

  emit: 
    alevin_fry_quant.out[0] // name
    alevin_fry_quant.out[1] // quant-dir
}

workflow af_knee {
  take:
    org
    sname
    chem
    map_path
    rad_file
    unmapped_file

  emit:
    sname

  main:
    af_gpl(sname, chem, map_path, rad_file, unmapped_file, "knee")
    af_collate(af_gpl.out, "knee")
    af_quant(af_collate.out, "knee", org)
}

workflow af_unfilt {
  take:
    org
    sname
    chem
    map_path
    rad_file
    unmapped_file

  emit:
    sname

  main:
    af_gpl(sname, chem, map_path, rad_file, unmapped_file, "unfilt")
    af_collate(af_gpl.out, "unfilt")
    af_quant(af_collate.out, "unfilt", org)
}



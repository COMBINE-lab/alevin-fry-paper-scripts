nextflow.enable.dsl=2

include { get_permit_list } from './utils.nf'

def kb_chem_flag(chem) {
  switch(chem) {
    case "v2":
      return "10xv2"
    case "v3":
      return "10xv3"
  }
}


def kb_index_for(org_name, ptype) {
   switch([org_name, ptype]) {
     case { it == ["human-2020A", "single-cell"]} :
      return params.kb.index_human_2020A_sc;
     case { it == ["human-cr3", "single-cell"]} :
      return params.kb.index_human_cr3_sc;
     case { it == ["mouse-cr2", "velocity"]} :
      return params.kb.index_mouse_cr2_velo;
     case { it == ["mouse-2020A", "single-nucleus"]} :
      return params.kb.index_mouse_2020A_sn;
     case { it == ["zebrafish", "single-cell"]} :
      return params.kb.index_zebrafish_sc;
     default:
      println("No kb index for combination (org = ${org_name}, ptype = ${ptype})");
      return "NULL";
   }
}


def kb_t2g_for(org_name, ptype) {
   switch([org_name, ptype]) {
     case { it == ["human-2020A", "single-cell"]} :
      return params.kb.t2g_human_2020A_sc;
     case { it == ["human-cr3", "single-cell"]} :
      return params.kb.t2g_human_cr3_sc;
     case { it == ["mouse-cr2", "velocity"]} :
      return params.kb.t2g_mouse_cr2_velo;
     case { it == ["mouse-2020A", "single-nucleus"]} :
      return params.kb.t2g_mouse_2020A_sn;
     case { it == ["zebrafish", "single-cell"]} :
      return params.kb.t2g_zebrafish_sc;
     default:
      println("No kb t2g for combination (org = ${org_name}, ptype = ${ptype})");
      return "NULL";
   }
}



def get_kb_workflow(ptype)  {
   switch(ptype) {
    case "single-cell":
      return "standard"
    case "single-nucleus":
      return "nucleus"
    case "velocity":
      return "lamanno"
  } 
}

process kb_quant {
  tag "kb:${name}"

  cpus 16

   publishDir "${params.output_dir}/kb"

  input:
    tuple val(name), val(dir), val(read1), val(read2), val(chem), val(ptype), val(org)
    val knee_done
    val unfilt_done

  output:
    path "${name}/**"

  script:
    def workflow_type = get_kb_workflow(ptype) 
    def idx = kb_index_for(org, ptype)
    def kb_t2g = kb_t2g_for(org, ptype)
    def kb_c1 = (ptype == "single-cell") ? "" : ("-c1 " + kb_t2g.replaceAll("t2g.txt", "cdna_t2c.txt"))
    def kb_c2 = (ptype == "single-cell") ? "" : ("-c2 " + kb_t2g.replaceAll("t2g.txt", "intron_t2c.txt"))
    def extra_ptype_flags = (ptype == "single-cell") ? "" : "${kb_c1} ${kb_c2}"
    def chemflag = kb_chem_flag(chem)
    def reads1 = read1.split(' ').collect{ x -> dir + "/" + x.replaceAll (/\"/,"")}
    def reads2 = read2.split(' ').collect{ x -> dir + "/" + x.replaceAll (/\"/,"")}
    def reads = [reads1, reads2].transpose().flatten().join(" ")
    """
    mkdir -p ${name}/logs
    ${params.timecmd} -v -o ${name}/logs/kb.time $params.bin.kb count -i ${idx} -g ${kb_t2g} ${extra_ptype_flags} -x ${chemflag} -o ${name}/kb_out -t ${task.cpus} --workflow ${workflow_type} ${reads}
    """

  stub:
    def workflow_type = get_kb_workflow(ptype) 
    def idx = kb_index_for(org, ptype)
    def kb_t2g = kb_t2g_for(org, ptype)
    def kb_c1 = (ptype == "single-cell") ? "" : ("-c1 " + kb_t2g.replaceAll("t2g.txt", "cdna_t2c.txt"))
    def kb_c2 = (ptype == "single-cell") ? "" : ("-c2 " + kb_t2g.replaceAll("t2g.txt", "intron_t2c.txt"))
    def extra_ptype_flags = (ptype == "single-cell") ? "" : "${kb_c1} ${kb_c2}"
    def chemflag = kb_chem_flag(chem)
    def reads1 = read1.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x }
    def reads2 = read2.replaceAll(/\"/,"").split(' ').collect{ x -> dir + "/" + x }
    def reads = [reads1, reads2].transpose().flatten().join(" ")
    def cmd = """
${params.timecmd} -v -o ${name}/logs/kb.time $params.bin.kb count -i ${idx} -g ${kb_t2g} ${extra_ptype_flags} -x ${chemflag} -o ${name}/kb_out -t ${task.cpus} --workflow ${workflow_type} ${reads}
"""

    """
    mkdir -p ${name}/logs
    mkdir -p ${name}/kb_out
    echo "${cmd}"
    touch ${name}/logs/kb.time
    touch ${name}/kb_out/nextflow_was_here
    """
  }

workflow kb_process {
  take: 
    samp
    knee_done
    unfilt_done

  main:
    kb_quant(samp, knee_done, unfilt_done)
}



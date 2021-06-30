nextflow.enable.dsl=2

include { af_map; af_map_sparse; af_knee; af_unfilt } from './modules/alevin'

include { ss_process } from './modules/star_solo'

include { kb_process } from './modules/kb'

workflow {
  data = Channel
    .fromPath(params.input_csv)
    .splitCsv(header:true)
    .map{ row-> tuple(row.name, row.dir, row.r1, row.r2, row.chem, row.ptype, row.org) }

  // run starsolo on the dataset 
  ss_process(data)

  // run alevin-fry on the dataset 
  // producing both the knee filtered and 
  // unfiltered output
  af_map_sparse(data, ss_process.out)
  af_map(data, ss_process.out)
  af_knee(af_map.out)
  af_unfilt(af_map.out)

  kb_process(data, af_knee.out, af_unfilt.out)
}


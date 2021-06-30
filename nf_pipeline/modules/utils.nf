
nextflow.enable.dsl=2

def get_permit_list(chem) {
  switch(chem) {
    case "v2":
      return params.v2_permitlist
    case "v3":
      return params.v3_permitlist
  }
}
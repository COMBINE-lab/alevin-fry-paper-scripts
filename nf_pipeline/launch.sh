#!/usr/bin/env bash

NEXTFLOW=''
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -n|--nextflow)
      NEXTFLOW="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

echo $NEXTFLOW

if [[ -z "${NEXTFLOW}" ]]; then
  echo "set the NEXTFLOW variable to launch"
else
  mkdir -p reports
  ${NEXTFLOW} run main.nf -c ../configs/nf.config -with-trace -with-report reports/workflow_report.html -with-tower
fi

config="../configs/config.json"
top_dir=$(jq -r '.top_dir' ${config})
cp pipeline_trace.txt $top_dir/results/pipeline_trace.csv

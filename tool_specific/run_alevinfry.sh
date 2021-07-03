#!/usr/bin/env bash

time="/usr/bin/time -v -o"

fry=$1
result_dir=$2
t2g=$3
threads=$4
permit_mode=$5
unf_list=$6

logs_dir=$result_dir/logs
mkdir -p $logs_dir

permitlist="permitlist_$permit_mode"
if [ $permit_mode = "knee" ]; then
    permitmodecmd="--knee-distance"
elif [ $permit_mode = "unfilt" ]; then
    permitmodecmd="-u $unf_list"
fi

### generate permit list
cmd="$time $logs_dir/$permitlist.time $fry generate-permit-list $permitmodecmd -d fw -i $result_dir -o $result_dir/$permitlist/"
echo $cmd
eval $cmd

### collate
cmd="$time $logs_dir/collate_$permit_mode.time $fry collate -i $result_dir/$permitlist/ -r $result_dir -t $threads"
echo $cmd
eval $cmd

### quant
cmd="$time $logs_dir/quant_$permit_mode.time $fry quant -r cr-like --use-mtx -m $t2g \
        -i $result_dir/$permitlist/ -o $result_dir/quant_$permit_mode -t $threads"
echo $cmd
eval $cmd

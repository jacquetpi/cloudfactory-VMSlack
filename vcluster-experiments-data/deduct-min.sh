#!/bin/bash
if (( "$#" != "7" ))
then
  echo "deduct-min.sh Missing argument : ./deduct-min.sh label vm start filter_oc vmproperties modelproperties"
  echo "Example ./deduct-min.sh label 1000 20 1.0/no vmproperties modelproperties firstfit"
  exit -1
fi
cpu_config="32"
mem_config="128"
label="$1"
vm="$2"
host_count="$3"
filter_oc="$4"
vmproperties=$5
modelproperties=$6
firstfit=$7
temporary_file=$(mktemp)
while :
do
  java -cp /usr/local/src/cloudsimplus/target/cloudsimplus-*-with-dependencies.jar org.cloudsimplus.examples.CloudFactoryGeneratedWorkload "$host_count" "$cpu_config" "$mem_config" "$filter_oc" "$vmproperties" "$modelproperties" "$firstfit"> "$temporary_file"
  if ! grep -q 'No suitable host found' "$temporary_file"; then
    # Everything went fine
    mv "$temporary_file" "/usr/local/src/cloudfactory-premium/vcluster-experiments-data/cloudsimplus-dump/$label-$firstfit.txt"
    break
  fi
  host_count=$(( host_count + 1 ))
done
echo "$host_count"
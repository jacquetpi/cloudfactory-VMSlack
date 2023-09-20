#!/bin/bash
if (( "$#" != "1" ))
then
  echo "cluster-sizing-exp.sh Missing argument : ./cluster-sizing-exp.sh dataset"
  echo "Example ./cluster-sizing-exp.sh azure2017"
  exit -1
fi
dataset="$1"
output_csv="vcluster-experiments-data/output-"$dataset".csv"
echo "dataset,distribution,vm,label,host,hostoc1,hostoc2,hostoc3" > "$output_csv"

for oc1 in $(seq 0 25 100)
do
    to_dispath=$((100 - $oc1))
    for oc2 in $(seq 0 25 $to_dispath)
    do
        oc3=$((100 - $oc1 - $oc2))
        oc1_r=$(python3 -c "print($oc1/100)")
        oc2_r=$(python3 -c "print($oc2/100)")
        oc3_r=$(python3 -c "print($oc3/100)")
        cat /usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-premium-template.yml | sed -e "s/§oc1§/$oc1_r/" | sed -e "s/§oc2§/$oc2_r/" | sed -e "s/§oc3§/$oc3_r/" > /usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-premium.yml
        distribution="oc1:$oc1_r-oc2:$oc2_r-oc3:$oc3_r"
        # Reinit counters
        prev_vcluster=0
        prev_oc1=0
        prev_oc2=0
        prev_oc3=0
        for vm in $(seq 100 100 1000)
        do
            echo "Testing following oversubscription distribution oc1:$oc1% oc2:$oc2% oc3:$oc3% with $vm vm"
            
            # Cloudfactory generation
            extended_label="$dataset-$distribution-$vm.vm"
            python3 -m generator --distribution=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-distribution-"$dataset".yml --usage=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-usage-azure2017.yml --premium=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-premium.yml --vm="$vm" --output=cloudsimplus --temporality=360,8640,7 --export="/usr/local/src/cloudfactory-premium/vcluster-experiments-data/cloudfactory-dump/$extended_label.json"
            
            echo "source vcluster-experiments-data/deduct-min.sh $extended_label-vcluster $vm $prev_vcluster no"
            vcluster=$( source vcluster-experiments-data/deduct-min.sh "$extended_label-vcluster" "$vm" "$prev_vcluster" no)
            clusteroc1=$( source vcluster-experiments-data/deduct-min.sh "$extended_label-oc1" "$vm" "$prev_oc1" 1.0)
            clusteroc2=$( source vcluster-experiments-data/deduct-min.sh "$extended_label-oc2" "$vm" "$prev_oc2" 2.0)
            clusteroc3=$( source vcluster-experiments-data/deduct-min.sh "$extended_label-oc3" "$vm" "$prev_oc3" 3.0)
            cluster=$(python3 -c "print($clusteroc1 + $clusteroc2 + $clusteroc3)")
            echo "overall: found min with $vcluster against $cluster"
            echo "$dataset,$distribution,$vm,vcluster,$vcluster,$clusteroc1,$clusteroc2,$clusteroc3" >> "$output_csv"
            echo "$dataset,$distribution,$vm,cluster,$cluster,None,None,None" >> "$output_csv"
            prev_vcluster="$vcluster"
            prev_oc1="$clusteroc1"
            prev_oc2="$clusteroc2"
            prev_oc3="$clusteroc3"
        done
    done
done
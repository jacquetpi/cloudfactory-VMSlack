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

for oc1 in $(seq 50 25 100)
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

        # Initialise CloudFactory scenario
        startvm=100
        step=100
        extended_label="$dataset-$distribution-$startvm.vm"
        python3 -m generator --distribution=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-distribution-"$dataset".yml --usage=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-usage-azure2017.yml --premium=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-premium.yml --vm="$startvm" --output=cloudsimplus --temporality=360,8640,7 --export="/usr/local/src/cloudfactory-premium/vcluster-experiments-data/cloudfactory-dump/$extended_label.json"

        for vm in $(seq $startvm $step 500)
        do
            echo "Testing following oversubscription distribution oc1:$oc1% oc2:$oc2% oc3:$oc3% with $vm vm"
            extended_label="$dataset-$distribution-$vm.vm"

            # Launch experiments
            mv vms.properties /tmp/vms.properties
            mv models.properties /tmp/models.properties

            vcluster-experiments-data/deduct-min.sh "$extended_label-vcluster" "$vm" "$prev_vcluster" no /tmp/vms.properties /tmp/models.properties false> /tmp/res-vcluster &
            vcluster-experiments-data/deduct-min.sh "$extended_label-oc1" "$vm" "$prev_oc1" 1.0 /tmp/vms.properties /tmp/models.properties false> /tmp/res-oc1 &
            vcluster-experiments-data/deduct-min.sh "$extended_label-oc2" "$vm" "$prev_oc2" 2.0 /tmp/vms.properties /tmp/models.properties false> /tmp/res-oc2 &
            vcluster-experiments-data/deduct-min.sh "$extended_label-oc3" "$vm" "$prev_oc3" 3.0 /tmp/vms.properties /tmp/models.properties false> /tmp/res-oc3 &
            vcluster-experiments-data/deduct-min.sh "$extended_label-oc1" "$vm" "$prev_oc1" 1.0 /tmp/vms.properties /tmp/models.properties true> /tmp/ff-oc1 &
            vcluster-experiments-data/deduct-min.sh "$extended_label-oc2" "$vm" "$prev_oc2" 2.0 /tmp/vms.properties /tmp/models.properties true> /tmp/ff-oc2 &
            vcluster-experiments-data/deduct-min.sh "$extended_label-oc3" "$vm" "$prev_oc3" 3.0 /tmp/vms.properties /tmp/models.properties true> /tmp/ff-oc3 &
            # Preparing next round in background to reduce time
            nextvm=$(($vm + $step))
            nextlabel="$dataset-$distribution-$nextvm.vm"
            python3 -m generator --distribution=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-distribution-"$dataset".yml --usage=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-usage-azure2017.yml --premium=/usr/local/src/cloudfactory-premium/examples-scenario/scenario-vm-premium.yml --vm="$nextvm" --output=cloudsimplus --temporality=360,8640,7 --export="/usr/local/src/cloudfactory-premium/vcluster-experiments-data/cloudfactory-dump/$nextlabel.json" &

            wait
            vcluster=$(cat /tmp/res-vcluster)
            clusteroc1=$(cat /tmp/res-oc1)
            clusteroc2=$(cat /tmp/res-oc2)
            clusteroc3=$(cat /tmp/res-oc3)
            ffoc1=$(cat /tmp/ff-oc1)
            ffoc2=$(cat /tmp/ff-oc2)
            ffoc3=$(cat /tmp/ff-oc3)
            
            cluster=$(($clusteroc1 + $clusteroc2 + $clusteroc3))
            ff=$(($ffoc1 + $ffoc2 + $ffoc3))

            echo "overall: found min with $vcluster against $cluster"
            echo "$dataset,$distribution,$vm,vcluster,$vcluster,None,None,None" >> "$output_csv"
            echo "$dataset,$distribution,$vm,cluster,$cluster,$clusteroc1,$clusteroc2,$clusteroc3" >> "$output_csv"
            echo "$dataset,$distribution,$vm,ff,$ff,$ffoc1,$ffoc2,$ffoc3" >> "$output_csv"
            prev_vcluster="$vcluster"
            prev_oc1="$clusteroc1"
            prev_oc2="$clusteroc2"
            prev_oc3="$clusteroc3"
        done
    done
done

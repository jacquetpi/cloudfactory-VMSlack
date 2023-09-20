#!/bin/bash
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
        #echo "Launching with oc1:$oc1% oc2:$oc2% oc3:$oc3%"
        for vm in $(seq 100 100 1000)
        do
            echo "$vm"
        done
    done
done

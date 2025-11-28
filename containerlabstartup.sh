#!/bin/bash

usage() {
  echo "Usage: $0 -f <pceFqdn> -P <pcePort> -u <apiName> -s <apiSecret> -o <orgId>"
  echo "  -f  PCE FQDN"
  echo "  -P  PCE Port"
  echo "  -u  API Username"
  echo "  -s  API Secret"
  echo "  -o  Org ID"
  exit 1
}

while getopts "f:P:u:s:o:" opt; do
  case $opt in
    f) pceFqdn="$OPTARG" ;;
    P) pcePort="$OPTARG" ;;
    u) apiName="$OPTARG" ;;
    s) apiSecret="$OPTARG" ;;
    o) orgId="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check required arguments
if [[ -z "$pceFqdn" || -z "$pcePort" || -z "$apiName" || -z "$apiSecret" || -z "$orgId" ]]; then
  usage
fi



# Run in startup/teardown directory
cd ~/manual-instruqt-startup

# Add PCE Configuration
echo -e "\n### Adding Workloader PCE Configuration ###"
./workloader pce-add -a --name default --fqdn "$pceFqdn" --port "$pcePort" --api-user "$apiName" --api-secret "$apiSecret" --org "$orgId" --disable-tls-verification true

#--- dd pairing profile ------
./workloader pairing-profile-export --output-file /tmp/delete_pp.csv
if [[ -f /tmp/delete_pp.csv ]]; then
  ./workloader delete /tmp/delete_pp.csv --header href --update-pce --no-prompt --provision
fi

#---dd label---
./workloader label-export --output-file /tmp/delete_labels.csv 
if [[ -f /tmp/delete_labels.csv ]]; then
   ./workloader delete /tmp/delete_labels.csv --header href --update-pce --no-prompt --provision
fi

#Make sure basic labels are added so students can continue in the track
echo -e "\n### Creating Labels and Label Dimensions ###"
./workloader label-dimension-import ./vensim-templates/standard-demo/labeldimensions.csv --update-pce --no-prompt
./workloader label-import ./vensim-templates/standard-demo/labels.csv --update-pce --no-prompt
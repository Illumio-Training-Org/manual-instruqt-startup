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

#--dd svc-----
./workloader svc-export --compressed --output-file /tmp/delete_svc.csv 
if [[ -f /tmp/delete_svc.csv ]]; then
   ./workloader delete /tmp/delete_svc.csv --header href --update-pce --no-prompt --provision --continue-on-error
fi

#Make sure basic labels are added so students can continue in the track
echo -e "\n### Creating Labels and Label Dimensions ###"
./workloader label-dimension-import ./vensim-templates/standard-demo/labeldimensions.csv --update-pce --no-prompt
./workloader label-import ./vensim-templates/standard-demo/labels.csv --update-pce --no-prompt



# Generate Pairing Keys
echo -e "\n### Generating Pairing Keys ###"
./workloader get-pk --profile Vensim-Created-Servers --create --ven-type server -f server_pp
./workloader get-pk --profile Vensim-Created-Endpoints --create --ven-type endpoint -f endpoint_pp

# Create and Import Resources
echo -e "\n### Creating and Importing Resources ###"
# ./workloader wkld-import ./vensim-templates/standard-demo/wklds.csv --umwl --allow-enforcement-changes --update-pce --no-prompt
./workloader svc-import ./vensim-templates/standard-demo/svcs.csv --update-pce --provision --no-prompt 
./workloader svc-import ./vensim-templates/standard-demo/svcs_meta.csv --meta --update-pce --no-prompt --provision
./workloader ipl-import ./vensim-templates/standard-demo/iplists.csv --update-pce --no-prompt --provision
./workloader adgroup-import ./vensim-templates/standard-demo/adgroups.csv --update-pce --no-prompt
#./workloader ruleset-import ./vensim-templates/standard-demo/rulesets.csv --update-pce --no-prompt --provision
#./workloader rule-import ./vensim-templates/standard-demo/rules.csv --update-pce --no-prompt --provision

echo "done" > /tmp/startup.done

echo "### Startup Complete ###"
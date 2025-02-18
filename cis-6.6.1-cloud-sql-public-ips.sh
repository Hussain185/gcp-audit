#!/bin/bash

source functions.inc

PROJECT_IDS="";
DEBUG="False";
HELP=$(cat << EOL
	$0 [-p, --project PROJECT] [-d, --debug] [-h, --help]	
EOL
);

for arg in "$@"; do
  shift
  case "$arg" in
    "--help") 		set -- "$@" "-h" ;;
    "--debug") 		set -- "$@" "-d" ;;
    "--project")   	set -- "$@" "-p" ;;
    *)        		set -- "$@" "$arg"
  esac
done

while getopts "hdp:" option
do 
    case "${option}"
        in
        p)
        	PROJECT_IDS=${OPTARG};;
        d)
        	DEBUG="True";;
        h)
        	echo $HELP; 
        	exit 0;;
    esac;
done;


if [[ $PROJECT_IDS == "" ]]; then
	declare PROJECT_IDS=$(get_projects);
fi;

for PROJECT_ID in $PROJECT_IDS; do
	set_project $PROJECT_ID;	

	if ! api_enabled sqladmin.googleapis.com; then
		echo "Cloud SQL API not enabled on Project $PROJECT_ID.";
		continue;
	fi;

	declare INSTANCES=$(gcloud sql instances list --quiet --format="json");

	DATABASE_NAME=$(echo $INSTANCES | jq '.[]' | jq '.name');	
	DATABASE_VERSION=$(echo $INSTANCES | jq '.[]' | jq '.databaseVersion');
	EXTERNAL_IP=$(echo $INSTANCES | jq '.[]' | jq '.ipAddresses[]' | jq 'select(.type == "PRIMARY")' | jq '.ipAddress');
	
	if [[ $DATABASE_NAME != "" ]]; then
	
		#Get project details
      		get_project_details $PROJECT_ID

		echo "Project Name: $PROJECT_NAME";
		echo "Project Application: $PROJECT_APPLICATION";
		echo "Project Owner: $PROJECT_OWNER";
		echo "Cloud SQL Instance $DATABASE_NAME";
		echo "Version: $DATABASE_VERSION";
		if [[ $EXTERNAL_IP != "" ]]; then
			echo "External IP Addresses: $EXTERNAL_IP";
		else
			echo "No external IP found";
		fi
		echo "";
		sleep 0.5;
	else
		echo "Project $PROJECT_ID: No Cloud SQL found";
	fi
done;

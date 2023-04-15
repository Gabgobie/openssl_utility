#!/bin/bash

# Variables
eval $(awk -F' *= *' '$1 == "TLD" {print $1 "=" $2}' values/rsa_values.cnf)
filename="${TLD}_Root_CA_Collection"

# File to collect certs in
echo "Looking for previous version of $filename"
if [ -e ${filename}.pem ]; then
	read -p "Found ${filename}.pem! Do you want me to remove it before running the script? (y/n/CANCEL): " decision
	if [ ${decision,,} = "y" ]; then
		rm -f ${filename}.pem
	elif [ ${decision,,} = "n" ]; then
		echo "Leaving the old file and appending the certificates."
	else
		echo "Canceling the script."
		exit 0
	fi
else
	echo "No previous version of {$filename}.pem found. Proceeding with the script."
fi
echo "Collecting Root-CA certs in $filename"


# Collection process
read -p "Do you want me to autodetect the certificates you created or supply their paths manually? (AUTO/manual)" decision
if [ "${decision,,}" = "manual" ]; then
	while read -p "Please enter the absolute path (or relative from the directory you executed the script from) to your certificates (or press enter to end the input): " input; do
		if [[ -z $input ]]; then
			break
		fi
		known_Locations+=( $input )
	done
else
	eval $(awk -F'*' '$1 {print "known_Locations+=( "$1" )"}' values/known_Certs.txt)
fi

for cert in ${known_Locations[@]}; do
    cat ${cert} >> ${filename}.pem
done

unset known_Locations

read -p "Do you want me to collect the certificates into a .pfx file? (y/N): " decision
if [ "${decision,,}" = "y" ]; then
	echo "Creating .pfx file!"
	openssl pkcs12 -export -out ${filename}.pfx -nokeys -in $filename.pem -nodes
	echo "Script finished successfully!"
else
	echo "Script finished successfully!"
fi
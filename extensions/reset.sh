#!/bin/bash

eval $(awk -F' *= *' '$1 == "TLD" {print $1 "=" $2}' values/RSA_values.cnf)

read -p "Are you sure you want to delete ${TLD}_* in this directory? This action can not be undone! If so please type in 'YES': " input

if [ "${input,,}" = "yes" ]; then
    sudo rm -r ${TLD}_*
    rm values/known_Certs.txt
    clear
else
    echo "Aborted"
fi
#!/bin/bash

eval $(awk -F' *= *' '$1 == "Domain" {print $1 "=" $2}' values/openssl.cnf)

read -p "Are you sure you want to delete ${Domain}_* in this directory? This action can not be undone! If so please type in 'YES': " input

if [ "${input,,}" = "yes" ]; then
    sudo rm -r ${Domain}_*
    rm values/known_Certs.txt
    clear
else
    echo "Aborted"
fi
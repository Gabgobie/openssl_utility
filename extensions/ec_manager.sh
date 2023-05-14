#!/bin/bash

# setting dummy values for openssl
types=( "Root_CA" "Interoot_CA" "Intermediate_CA" )
for type in "${types[@]}"; do
    key="${type}_key"
    cert="${type}_cert"
    crl="${type}_crl"

    declare -g -x $key="$type N/A"
    declare -g -x $cert="$type N/A"
    declare -g -x $crl="$type N/A"
done

read -p "Please make sure you set all of the variables inside values/EC_values.cnf to your liking and press enter to continue."

# Variables
eval $(awk -F' *= *' '$1 == "TLD" || $1 == "bits" || $1 == "root_days" || $1 == "interoot_days" || $1 == "intermediate_days" || $1 == "algorithm" {print $1 "=" $2}' values/EC_values.cnf)

# script running
if [ ! -d ${TLD}_${algorithm} ]; then
    echo "Creating directory for your ${algorithm} certificates"
    mkdir ${TLD}_${algorithm}
else
    echo "Directory already exists: Skipping"
fi

make_subdirectories () {

    local type=$1

    mkdir ${TLD}_${algorithm}/${TLD}_${type}/certs
    mkdir ${TLD}_${algorithm}/${TLD}_${type}/crl
    mkdir ${TLD}_${algorithm}/${TLD}_${type}/newcerts
    mkdir ${TLD}_${algorithm}/${TLD}_${type}/private
    touch ${TLD}_${algorithm}/${TLD}_${type}/index.txt
    echo "1000" > ${TLD}_${algorithm}/${TLD}_${type}/serial
    echo "1000" > ${TLD}_${algorithm}/${TLD}_${type}/crlnumber
    openssl rand -out ${TLD}_${algorithm}/${TLD}_${type}/private/.rand $bits
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/.rand

    if [ ! "$type" = "Root_CA" ]; then
        mkdir ${TLD}_${algorithm}/${TLD}_${type}/csr
    fi

}

choose_CA () { # I think I will change the folder structure slightly so the certs will be in a subfolder of certs/ that's naming is referencing the CA that signed them. Not sure about that though.

    local type=$1
    local directory="${TLD}_${algorithm}/${TLD}_${type}/certs/"

    if [ -d "$directory" ]; then
        local discovered_CAs=( $(ls ${directory}) )
    else
        local discovered_CAs=()
    fi

    if [ "${#discovered_CAs[@]}" = "0" ]; then

        echo "No CAs found. Creating a new one."

        create_${type}

        local discovered_CAs=( $(ls ${directory}) )

        local chosen_CA=${discovered_CAs[0]}
    
    elif [ "${#discovered_CAs[@]}" = "1" ]; then

        echo "Choosing the only available CA for signing."

        local chosen_CA=${discovered_CAs[0]}
    
    else

        echo "These CAs were located and can be chosen by typing in the corresponding number:"

        for i in ${!discovered_CAs[@]}; do
            echo $((i+1)). ${discovered_CAs[${i}]}
        done
    
        read -p "Enter a valid number: " number

        local chosen_CA=${discovered_CAs[$((number-1))]}

    fi

    key="${type}_key"
    cert="${type}_cert"
    crl="${type}_crl"

    declare -g -x $key=${chosen_CA/%.cert.pem/.key.pem}
    declare -g -x $cert=${chosen_CA/%.cert.pem/.cert.pem}
    declare -g -x $crl=${chosen_CA/%.cert.pem/.crl.pem}

    echo "Chosen_CA is $chosen_CA"
}

create_Root_CA () {

    local type="Root_CA"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
    else
        sudo mv ${TLD}_${algorithm}/${TLD}_${type} ${TLD}_${algorithm}/${TLD}_${type}.old
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
    fi

    make_subdirectories $type

    declare -g -x exported_CN="${TLD} Root CA"
    declare -g -x Root_CA_key="${TLD}_${type}_${algorithm}.key.pem"
    declare -g -x Root_CA_cert="${TLD}_${type}_${algorithm}.cert.pem"
    declare -g -x Root_CA_crl="${TLD}_${type}_${algorithm}.crl.pem"
    declare -g -x serial=""

    # Generating encrypted EC privatekey, secure it
    openssl ecparam -name ${algorithm} -genkey -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem
    openssl ec -in ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem -aes256 -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem

    # generate the corresponding certificate
    openssl req -config values/EC_values.cnf -new -x509 -days $root_days -extensions v3_${type} -key ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    # secure the certificate
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    # incpect
    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem -text -noout
    fi

    # export to known certs file
    echo "${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem" >> values/known_Certs.txt

    # confirmation
    echo "Creation of ${type} complete."

    # cleanup
    unset type input exported_CN
}

create_Interoot_CA () {

    local requirement="Root_CA"
    local type="Interoot_CA"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
        make_subdirectories $type
    fi

    choose_CA ${requirement}

    echo "Now commencing the creation of your ${type}"

    export exported_CN="${TLD} Interoot CA"
    export serial=$(cat "${TLD}_${algorithm}/${TLD}_${requirement}/serial")

    # Generating encrypted EC privatekey, secure it
    openssl ecparam -name ${algorithm} -genkey -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem
    openssl ec -in ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem -aes256 -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem

    # generate the corresponding csr
    openssl req -config values/EC_values.cnf -new -extensions v3_${type} -key ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}_${serial}.csr.pem

    # sign the csr
    openssl ca -config values/EC_values.cnf -name ${requirement} -in ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}_${serial}.csr.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem

    # secure and incpect
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem

    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem -text -noout
    fi

    # confirmation
    echo "Creation of ${type} complete."

    # cleanup
    unset type requirement input exported_CN
}

create_Intermediate_CA () {

    local requirement="Interoot_CA"
    local type="Intermediate_CA"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
        make_subdirectories $type
    fi

    choose_CA ${requirement}

    echo "Now commencing the creation of your ${type}"

    export exported_CN="${TLD} Intermediate CA"
    export serial=$(cat "${TLD}_${algorithm}/${TLD}_${requirement}/serial")

    # Generating encrypted EC privatekey, secure it
    openssl ecparam -name ${algorithm} -genkey -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem
    openssl ec -in ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem -aes256 -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem

    # generate the corresponding csr
    openssl req -config values/EC_values.cnf -new -extensions v3_${type} -key ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}_${serial}.csr.pem

    # sign the csr
    openssl ca -config values/EC_values.cnf -name ${requirement} -in ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}_${serial}.csr.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem

    # secure and incpect
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem

    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem -text -noout
    fi

    # confirmation
    echo "Creation of ${type} complete."

    # cleanup
    unset type requirement input exported_CN
}

create_server_cert () {

    local requirement="Intermediate_CA"
    local type="Server_Cert"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
        make_subdirectories $type
    fi

    choose_CA ${requirement}

    echo "Now commencing the creation of your ${type}"

    export exported_CN="${TLD} Leaf Cert"
    export serial=$(cat "${TLD}_${algorithm}/${TLD}_${requirement}/serial")

    # Generating encrypted EC privatekey, secure it
    openssl ecparam -name ${algorithm} -genkey -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem
    openssl ec -in ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem -aes256 -out ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem

    # generate the corresponding csr
    openssl req -config values/EC_values.cnf -new -key ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}_${serial}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}_${serial}.csr.pem

    # sign the csr
    openssl ca -config values/EC_values.cnf -name ${requirement} -in ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}_${serial}.csr.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem

    # secure and incpect
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem

    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}_${serial}.cert.pem -text -noout
    fi

    # confirmation
    echo "Creation of ${type} complete."

    # cleanup
    unset type requirement input exported_CN
}




# Activation sequence

known_Functions=( "create_Root_CA" "create_Interoot_CA" "create_Intermediate_CA" "create_server_cert" )

if [[ "$( read -p "If you want to enable full functionality, please type 'Safety_wheels_off!' (This is case sensitive!): " input; echo $input )" = "Safety_wheels_off!" ]]; then
    echo "Safe mode deactivated."
else
    unset known_Functions[0]
    echo "Nothing bad can happen now."
fi

for i in ${!known_Functions[@]}; do
    echo $((i+1)). ${known_Functions[${i}]}
done

read -p "Enter a valid number: " number

eval ${known_Functions[$((number-1))]}
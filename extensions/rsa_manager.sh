#!/bin/bash

read -p "Please make sure you set all of the variables inside values/RSA_values.cnf to your liking and press enter to continue."

# Variables
eval $(awk -F' *= *' '$1 == "TLD" || $1 == "bits" || $1 == "root_days" || $1 == "interoot_days" || $1 == "intermediate_days" || $1 == "algorithm" {print $1 "=" $2}' values/RSA_values.cnf)

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

create_Root_CA () {

    type="Root_CA"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
    else
        sudo mv ${TLD}_${algorithm}/${TLD}_${type} ${TLD}_${algorithm}/${TLD}_${type}.old
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
    fi

    make_subdirectories $type

    export exported_CN="${TLD} Root CA"

    # Generating encrypted ${algorithm} privatekey, secure it and the generate the corresponding certificate
    openssl req -config values/${algorithm}_values.cnf -new -x509 -days $root_days -extensions v3_${type} -keyout ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem

    # secure the certificate
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    # incpect
    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem -text -noout
    fi

    # cleanup
    unset type input exported_CN

    # export to known certs file
    echo "${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem" >> values/known_Certs.txt

    # confirmation
    echo "Creation of ${type} complete."
}

create_Interoot_CA () {

    requirement="Root_CA"
    type="Interoot_CA"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}

        if [ ! -e ${TLD}_${algorithm}/${TLD}_${requirement}/certs/${TLD}_${requirement}_${algorithm}.cert.pem ]; then
            echo "You will need to create a ${requirement} first! Starting creation..."
            eval "create_${requirement}"
        fi

        requirement="Root_CA"
        type="Interoot_CA"
        echo "Now commencing the creation of your ${type}"
    fi

    make_subdirectories $type
    export exported_CN="${TLD} Interoot CA"

    # Generating encrypted ${algorithm} privatekey, secure it and the generate the corresponding certificate
    openssl req -config values/${algorithm}_values.cnf -new -extensions v3_${type} -keyout ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}.csr.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem

    # sign the csr
    openssl ca -config values/${algorithm}_values.cnf -name ${requirement} -in ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}.csr.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    # secure and incpect
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem -text -noout
    fi

    # cleanup
    unset type requirement input exported_CN

    # confirmation
    echo "Creation of ${type} complete."
}

create_Intermediate_CA () {

    requirement="Interoot_CA"
    type="Intermediate_CA"

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}
        
        make_subdirectories $type

        if [ ! -e ${TLD}_${algorithm}/${TLD}_${requirement}/certs/${TLD}_${requirement}_${algorithm}.cert.pem ]; then
            echo "You will need to create a ${requirement} first! Starting creation..."
            eval "create_${requirement}"
        fi

        requirement="Interoot_CA"
        type="Intermediate_CA"
        echo "Now commencing the creation of your ${type}"
    fi


    export exported_CN="${TLD} Intermediate CA"

    # Generating encrypted ${algorithm} privatekey, secure it and the generate the corresponding certificate
    openssl req -config values/${algorithm}_values.cnf -new -extensions v3_${type} -keyout ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}.csr.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem

    # sign the csr
    openssl ca -config values/${algorithm}_values.cnf -name ${requirement} -in ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}.csr.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    # secure and incpect
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem -text -noout
    fi

    # cleanup
    unset type requirement input exported_CN

    # confirmation
    echo "Creation of ${type} complete."
}




# !!! NOT FINISHED !!!

create_server_cert () {

    requirement="Intermediate_CA"
    type="Server_Cert"

    echo "WARNING! THIS IS CURRENTLY JUST A QUICK EDIT OF ANOTHER FUNCTION AND WILL NOT BE ABLE TO PRODUCE MULTIPLE CERTS! You can use it by creating one cert at a time and copying the relevant files somewhere else before creating the next one."

    if [ ! -d ${TLD}_${algorithm}/${TLD}_${type} ]; then
        echo "Creating directory for your ${type}"
        mkdir ${TLD}_${algorithm}/${TLD}_${type}

        if [ ! -e ${TLD}_${algorithm}/${TLD}_${requirement}/certs/${TLD}_${requirement}_${algorithm}.cert.pem ]; then
            echo "You will need to create a ${requirement} first! Starting creation..."
            eval "create_${requirement}"
        fi

        requirement="Intermediate_CA"
        type="Server_Cert"
        echo "Now commencing the creation of your ${type}"

        make_subdirectories $type

    fi

    export exported_CN="Your CN"

    # Generating encrypted ${algorithm} privatekey, secure it and the generate the corresponding certificate
    openssl req -config values/${algorithm}_values.cnf -new -keyout ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem -out ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}.csr.pem
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/private/${TLD}_${type}_${algorithm}.key.pem

    # sign the csr
    openssl ca -config values/${algorithm}_values.cnf -name ${requirement} -in ${TLD}_${algorithm}/${TLD}_${type}/csr/${TLD}_${type}_${algorithm}.csr.pem -out ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    # secure and incpect
    chmod 400 ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem

    read -p "Do you want to inspect your certificate to make sure everything is as expected? (Y/n) " -r input
    if [ "${input,,}" = "n" ]; then
        echo "Skipping inspection..."
    else
        openssl x509 -in ${TLD}_${algorithm}/${TLD}_${type}/certs/${TLD}_${type}_${algorithm}.cert.pem -text -noout
    fi

    # cleanup
    unset type requirement input exported_CN

    # confirmation
    echo "Creation of ${type} complete."
}


# Activation sequence

known_Functions=( "create_Root_CA" "create_Interoot_CA" "create_Intermediate_CA" "create_server_cert" )

if [[ "$( read -p "If you want to enable full functionality, please type 'Safety_wheels_off!' (This is case sensitive!): " )" = "safety-wheels-off" ]]; then
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
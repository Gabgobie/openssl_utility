#!/bin/bash

echo "Initializing..."

# dependencies
dependencies=( "openssl" "gawk" )

for REQUIRED_PKG in ${dependencies[@]}; do
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
        echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG in the next step."
        missing_dependencies+=($REQUIRED_PKG)
    fi
done

if [ ${#missing_dependencies[@]} -eq 0 ]; then
    echo "Good news! All dependencies are already installed!"
else
    sudo apt update
    sudo apt-get --yes install ${missing_dependencies[@]}
fi

# gathering facts
echo "Loading modules..."
modules=( $(ls extensions) )

if [ -e values ]; then
    echo "Values folder already exists"
else
    echo "Creating values folder"
    mkdir values
fi

echo "These extensions were loaded and can be chosen by typing in the corresponding number:"

for i in ${!modules[@]}; do
    echo $((i+1)). ${modules[${i}]}
done

read -p "Enter a valid number: " number

bash extensions/${modules[$((number-1))]}
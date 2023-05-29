#!/bin/bash

# Update package list
sudo apt-get update -y

# Install necessary packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

# Add Docker's repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Update package list again
sudo apt-get update -y

# Finally, install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

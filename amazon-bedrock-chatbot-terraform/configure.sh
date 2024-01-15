#!/bin/bash

if [  $# -le 1 ]
then
    echo "Usage: $0 <Terraform Workspace> <AWS_REGION>"
    return 1
fi

# First try to select terraform workspace.
terraform workspace select $1
if [ $? -eq 0 ]
then
    echo "Workspace <$1> exists, which to be deleted for freshness."
    terraform workspace delete $1
fi

#echo "Seems to be a fresh terraform workspace: <$1>. Creating a new one..."
echo "Creating a new fresh workspace <$1>..."
terraform workspace new $1
terraform workspace select $1

echo "Terraform workspace <$1> selected"

AWS_REGION=$2
echo "AWS_REGION selected: ${AWS_REGION}"

#!/bin/bash

# Check if the k8s service account for xray exists.
# Troubleshooting Reference: https://stackoverflow.com/questions/66405794/not-authorized-to-perform-stsassumerolewithwebidentity-403
kubectl get serviceaccount riches-pod-service-account -n riches
if [ $? -eq 0 ]; then
  echo "K8S service account exists. No need to create it."
else
  echo "K8S service account does not exist. Creating."
  kubectl create serviceaccount riches-pod-service-account -n riches
  kubectl annotate serviceaccount --overwrite riches-pod-service-account eks.amazonaws.com/role-arn=$RICHES_POD_ROLE_ARN -n riches
fi


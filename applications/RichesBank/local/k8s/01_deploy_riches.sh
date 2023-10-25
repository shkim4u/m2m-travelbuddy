#!/bin/bash

export CERTIFICATE_ARN=<CERTIFICATE_ARN>

kubectl apply -f riches_deployment.yaml
kubectl apply -f riches_service.yaml
#kubectl apply -f riches_ingress.yaml
cat riches_ingress.yaml | envsubst | kubectl apply -f -

kubectl get pod --namespace riches
kubectl get service --namespace riches
kubectl get ingress --namespace riches

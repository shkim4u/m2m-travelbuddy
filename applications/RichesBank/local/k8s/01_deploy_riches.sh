#!/bin/bash

kubectl apply -f riches_deployment.yaml
kubectl apply -f riches_service.yaml
kubectl apply -f riches_ingress.yaml

kubectl get pod --namespace riches
kubectl get service --namespace riches
kubectl get ingress --namespace riches

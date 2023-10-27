#!/bin/bash

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output=text) && echo $AWS_ACCOUNT_ID

export CERTIFICATE_ARN=`aws acm list-certificates --query "CertificateSummaryList[?DomainName=='www.mydemo.co.kr'].CertificateArn" --output text`
echo $CERTIFICATE_ARN

kubectl apply -f riches_namespace.yaml
cat riches_deployment.yaml | enbsubst | kubectl apply -f -
kubectl apply -f riches_service.yaml
cat riches_ingress.yaml | envsubst | kubectl apply -f -

kubectl get pod --namespace riches
kubectl get service --namespace riches
kubectl get ingress --namespace riches

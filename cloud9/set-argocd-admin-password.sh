#!/bin/bash

# Check if argocd is installed.
if [ -z `which argocd` ]; then
  echo "argocd is not installed."
  ehho "Install argocd first by running install-argocd-cli.sh."
  exit 1
fi

# Check if the number of argument is 2.
if [ $# -ne 2 ]; then
  echo "Usage: $0 <argocd-admin-password> <AWS Secrets Manager SecretID: (eg)riches-ci-argocd-admin-password>"
  exit 1
fi

# Set passwd as the first argument.
ARGOCD_ADMIN_PASSWD=$1
AWS_SECRETS_MANAGER_SECRET_ID=$2

# Get ArgoCD Server URL.
ARGOCD_SERVER=`kubectl get ingress/argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
echo "ARGOCD_SERVER: ${ARGOCD_SERVER}"

# ArgoCD의 Admin 사용자 초기 패스워드 확인
ARGOCD_ADMIN_INITIAL_PASSWORD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo $ARGOCD_ADMIN_INITIAL_PASSWORD

# Login to ArgoCD Server.
argocd login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_ADMIN_INITIAL_PASSWORD} --insecure

# Set ArgoCD admin password.
#argocd login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_ADMIN_PASSWD} --insecure
argocd account update-password --current-password ${ARGOCD_ADMIN_INITIAL_PASSWORD} --new-password ${ARGOCD_ADMIN_PASSWD}

# Set AWS Secrets Manager SecretID.
aws secretsmanager put-secret-value --secret-id ${AWS_SECRETS_MANAGER_SECRET_ID} --secret-string ${ARGOCD_ADMIN_PASSWD}

#!/bin/bash

# Get ArgoCD Server URL.
ARGOCD_SERVER=`kubectl get ingress/argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
echo "ARGOCD_SERVER: ${ARGOCD_SERVER}"

# ArgoCD의 Admin 사용자 초기 패스워드 확인
ARGOCD_ADMIN_INITIAL_PASSWORD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo $ARGOCD_ADMIN_INITIAL_PASSWORD

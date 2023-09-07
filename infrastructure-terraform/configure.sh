#!/bin/bash

if [  $# -le 0 ]
then
    echo "Usage: $0 <Terraform Workspace>"
    return 1
fi

# Caution!: Clean up the previous terraform state.
#terraform state rm $(terraform state list)
#rm -rf .terraform.lock.hcl
#rm -rf terraform.tfstate*
#rm -rf tfplan
#rm -rf .terraform

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

###
### Some other things to initialize from here.
###

# 1. Create Private Certificate Authority.
export CA_ARN=`aws acm-pca create-certificate-authority --certificate-authority-configuration file://ca-config.txt --revocation-configuration file://ocsp-config.txt --certificate-authority-type "ROOT" --idempotency-token 01234567 --tags Key=Name,Value=AwsProservePCA | jq --raw-output .CertificateAuthorityArn`
echo $CA_ARN

# (Optional) For Terraform
export TF_VAR_ca_arn=${CA_ARN}
echo $TF_VAR_ca_arn

# Wait for a while so that the private CA is completed to be created.
# TODO: Do more elegantly by probing with AWS API.
echo "Wait for 10 secs for the private CA is ready to go."
sleep 10

# 2. Generate a certificate signing request (CSR).
aws acm-pca get-certificate-authority-csr \
     --certificate-authority-arn ${CA_ARN} \
     --output text > ca.csr

# 3. View and verify the contents of the CSR.
openssl req -text -noout -verify -in ca.csr

# 4. Root CA 인증서를 발행합니다.
export CERTIFICATE_ARN=`aws acm-pca issue-certificate --certificate-authority-arn ${CA_ARN} --csr fileb://ca.csr --signing-algorithm SHA256WITHRSA --template-arn arn:aws:acm-pca:::template/RootCACertificate/V1 --validity Value=3650,Type=DAYS | jq --raw-output .CertificateArn`
echo $CERTIFICATE_ARN

# 5. Root CA 인증서를 가져옵니다.
aws acm-pca get-certificate \
	--certificate-authority-arn ${CA_ARN} \
	--certificate-arn ${CERTIFICATE_ARN} \
	--output text > cert.pem

# 6. Certificate 정보를 OpenSSL로 조회해 봅니다.
openssl x509 -in cert.pem -text -noout

# 7. Root CA 인증서를 CA로 주입하고 설치합니다.
aws acm-pca import-certificate-authority-certificate \
     --certificate-authority-arn ${CA_ARN} \
     --certificate fileb://cert.pem

# 8. 사설 CA의 상태를 살펴봅니다. ACTIVE 상태임을 확인합니다.
aws acm-pca describe-certificate-authority \
	--certificate-authority-arn ${CA_ARN} \
	--output json

#!/bin/bash

sudo yum update -y
sudo yum upgrade -y

# 1. IDE IAM 설정 확인
echo "1. Checking Cloud9 IAM role..."
rm -vf ${HOME}/.aws/credentials
aws sts get-caller-identity --query Arn

# 2. (Optional for Amazon EKS) EKS 관련 도구
## 2.1. Kubectl 설치
# Refer to: https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html
echo "2.1. Installing kubectl..."
sudo curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl

# 실행 모드 변경
sudo chmod +x /usr/local/bin/kubectl
# 설치 확인
kubectl version --client

## 2.2. eksctl 설치
echo "2.2. Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
eksctl version

## 2.3. k9s 설치
echo "2.3. Installing k9s..."
#curl -sL https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz | sudo tar xfz - -C /usr/local/bin
curl -sL https://github.com/derailed/k9s/releases/download/v0.31.8/k9s_Linux_amd64.tar.gz | sudo tar xfz - -C /usr/local/bin
k9s version

## 2.4 Helm 설치
echo "2.4. Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version --short

## 3. Upgrade AWS CLI.
echo "3. Upgrading AWS CLI..."
aws --version

echo "3.1. Removing the AWS CLI Version 1..."
sudo rm /usr/local/bin/aws
sudo rm /usr/local/bin/aws_completer
sudo rm -rf /usr/local/aws-cli

echo "3.1. Installing AWS CLI Version 2..."
rm -rf ./aws | true
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
hash -d aws
aws --version
rm -rf aws awscliv2.zip

## 4. Upgrade AWS CDK.
echo "4. Upgrading AWS CDK..."
sudo npm uninstall -g aws-cdk
sudo rm -rf $(which cdk)
sudo npm install -g aws-cdk
cdk --version

## 5. Installing Misc.
echo "5. Installing miscellaneous tools..."

echo "5.1. Installing AWS SSM Session Manager..."
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo yum install -y session-manager-plugin.rpm
rm -rf session-manager-plugin.rpm

echo "5.2. Installing AWS Cloud9 CLI..."
sudo npm install -g c9

echo "5.3. Installing jq..."
sudo yum install -y jq

echo "5.4. Installing yq..."
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod a+x /usr/local/bin/yq
yq --version

echo "5.5. Installing bash-completion..."
sudo yum install -y bash-completion

## 6. [2023-12-06] CloudShell is now removed to reflect the license change of HashiCorp terraform, so manually install it.
echo "6. Installing terraform..."
rm -rf .tfenv
rm -rf ~/bin
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
mkdir ~/bin
ln -s ~/.tfenv/bin/* ~/bin/
#tfenv install 1.6.6
tfenv install latest
tfenv use latest
terraform --version

echo "7. Installing ArooCD CLI..."
# https://argo-cd.readthedocs.io/en/stable/cli_installation/
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "8. Installing wscat and awscurl..."
sudo npm install -g wscat
pip3 install awscurl

eccho "9. Installing Python 3.11..."
# Install Python 3.11:
curl https://pyenv.run | bash
exec $SHELL
echo "Configure ~/.bash_profile as guided and restart the shell."

# Add pyenv to PATH:
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# And add the following to ~/.bash_profile:
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile

# Install Dependencies for Python 3.11:
sudo yum update -y
sudo yum remove -y openssl-devel
sudo yum install -y gcc git zlib-devel openssl11-devel openssl libffi-devel bzip2 bzip2-devel ncurses-devel readline-devel xz-devel sqlite-devel

# Install Python 3.11.7 using pyenv:
pyenv install 3.11.7
pyenv global 3.11.7

# Refresh python version.
#echo "You may ignore if you see command not found error."
#hash -d python3
#hash -d python

## 99. AWS CLI Completer.
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
. ~/.bashrc

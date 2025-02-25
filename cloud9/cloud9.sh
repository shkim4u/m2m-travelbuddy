#!/bin/bash

sudo yum update -y
sudo yum upgrade -y

# 1. IDE IAM 설정 확인
echo "1. Checking Cloud9 IAM role..."
rm -vf ${HOME}/.aws/credentials
aws sts get-caller-identity --query Arn | grep cloud9-admin

# 2. (Optional for Amazon EKS) EKS 관련 도구
## 2.1. Kubectl
# 설치
echo "2.1. Installing kubectl..."
#sudo curl -o /usr/local/bin/kubectl  \
#   https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
sudo curl -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.1/2023-09-14/bin/linux/amd64/kubectl

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

## 6. Addition Cloud9 configurations.
echo "6. Additional Cloud9 configurations..."

echo "6.1. Configuring AWS_REGION..."
#export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
VERSIONID=$(awk /VERSION_ID=/ /etc/os-release |cut -d \" -f 2)

#if [[ "$VERSIONID" == "2023" || "$VERSIONID" == "22.04" ]]; then
#  # Get the METADATA INSTANCE V2 token
#  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
#  # Get the ID of the environment host Amazon EC2 instance.
#  export INSTANCEID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2> /dev/null)
#  export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/' 2> /dev/null)
#else
#  # Get the ID of the environment host Amazon EC2 instance.
#  export INSTANCEID=$(curl http://169.254.169.254/latest/meta-data/instance-id 2> /dev/null)
#  export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/' 2> /dev/null)
#fi

# Get the METADATA INSTANCE V2 token
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# Get the ID of the environment host Amazon EC2 instance.
export INSTANCEID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2> /dev/null)
export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/' 2> /dev/null)

echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile

aws configure set default.region ${AWS_REGION}

# 확인
aws configure get default.region

echo "6.2. Configuring AWS ACCOUNT_ID..."
#export ACCOUNT_ID=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId')
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile

## 7. Extend disk size.
echo "7. Extending disk size..."
echo "7.1. Checking disk size before extending..."
df -h

echo "7.2. Now extending the disk size..."
#curl -fsSL https://raw.githubusercontent.com/shkim4u/kubernetes-misc/main/aws-cloud9/resize.sh | bash -s -- 100
curl -fsSL https://raw.githubusercontent.com/shkim4u/m2m-travelbuddy/main/cloud9/cloud9-resize-v2.sh | bash -s -- 120

echo "7.3. Checking disk size with extension..."
df -h

# Acquire the first argument as the "INSTALL_CUDA" flag.
INSTALL_CUDA=${1:-"false"}

# If the "INSTALL_CUDA" flag is set to "true", install CUDA and cuDNN.
if [ "${INSTALL_CUDA}" = "true" ]; then
    echo "Installing CUDA and cuDNN..."
    ## 8. Download cuDNN (CUDA Deep Neural Network Library) and install it.
    echo "8.1. Downloading cuDNN..."
    #curl -fsSL https://developer.download.nvidia.com/compute/cudnn/secure/8.1.1.33/cudnn-8.1.1.33-linux-x64-v8.1.1.33.tgz | tar -xz -C /usr/local
    export CUDNN_DOWNLOAD_URL="https://shkim4u-generative-ai.s3.ap-northeast-2.amazonaws.com/cudnn-linux-x86_64-8.9.6.50_cuda12-archive.tar.xz"
    wget "${CUDNN_DOWNLOAD_URL}" -O cudnn-linux-x86_64-8.9.6.50_cuda12-archive.tar.xz
    tar -xvf cudnn-linux-x86_64-8.9.6.50_cuda12-archive.tar.xz

    echo "8.2. Installing cuDNN..."
    sudo mkdir -p /usr/local/cuda/include /usr/local/cuda/lib64
    sudo cp cudnn-*-archive/include/cudnn*.h /usr/local/cuda/include
    sudo cp -P cudnn-*-archive/lib/libcudnn* /usr/local/cuda/lib64
    sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*

    # Load LD_LIBRARY_PATH
    # References
    # - https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/install-nvidia-driver.html
    # -https://repost.aws/ko/questions/QUBqYWuFr7SyC6P6Uae9LOww/sagemaker-g4-and-g5-instances-do-not-have-working-nvidia-drivers
    # - https://stackoverflow.com/questions/75614728/cuda-12-tf-nightly-2-12-could-not-find-cuda-drivers-on-your-machine-gpu-will
    # - https://arinzeakutekwe.medium.com/how-to-configure-nvidia-gpu-to-work-with-tensorflow-2-on-aws-sagemaker-1be98b9db464
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
    source ~/.bashrc
    /sbin/ldconfig -N -v $(sed 's/:/ /' <<< $LD_LIBRARY_PATH) 2>/dev/null

    echo "8.2. cuDNN installed!"
else
    echo "Skipping CUDA and cuDNN installation..."
fi

## 9. [2023-12-06] Cloud9 is now removed to reflect the license change of HashiCorp terraform, so manually install it.
echo "9. Installing terraform..."
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

echo "10. Installing ArooCD CLI..."
# https://argo-cd.readthedocs.io/en/stable/cli_installation/
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "11. Installing wscat and awscurl..."
sudo npm install -g wscat
#pip3 install awscurl

echo "12. Installing Python 3.11..."
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

## 99. awscurl for testing and AWS CLI Completer.
pip3 install awscurl
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
. ~/.bashrc

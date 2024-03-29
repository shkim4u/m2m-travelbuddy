# Cloud9 환경 구성하기

IDE로 Cloud9을 사용하기 위해서 Cloud9 환경을 시작하고, 각종 도구들을 설치합니다.

## Agenda

1. Cloud9 시작하기
    * 1.1. AWS Cloud9 IDE 생성 (AWS CLI 사용)
    * 1.2. AWS Cloud9 IDE 생성 (AWS Management Console 사용)
      * 1.2.1. Cloud9 환경 생성
      * 1.2.2. IAM Role 생성
      * 1.2.3. IDE(AWS Cloud9 인스턴스)에 IAM Role 부여
      * 1.2.4. IDE에서 IAM 설정 업데이트
2. Cloud9 통합 설정 파일 실행

## 1. Cloud9 시작하기

AWS Cloud9으로 실습 환경을 구축하는 순서는 아래와 같습니다.

- AWS Cloud9으로 IDE 구성
- IAM Role 생성
- IDE(AWS Cloud9 인스턴스)에 IAM Role 부여
- IDE에서 IAM 설정 업데이트

### 1.1. AWS Cloud9 환경 생성 (AWS CLI 사용)
강사에 의해 제공된 AWS 관리 콘솔에서 ```CloudShell```을 실행한 후 아래 명령을 수행하여 ```Cloud9``` 환경을 생성해 줍니다.<br>
```CloudShell```도 다수의 개발 언어와 런타임, 그리고 클라우드 환경을 다룰 수 있는 CLI를 기본적으로 제공하지만 보다 풍부한 통합 개발 환경을 제공하는 ```Cloud9```을 사용하기로 합니다.<br>
```bash
curl -fsSL https://raw.githubusercontent.com/shkim4u/m2m-travelbuddy/main/cloud9/bootstrap-v2.sh | bash -s -- c5.9xlarge
```

(참고) IAM 사용자 ```admin```을 생성하고 권한 설정을 추가적으로 구성해 주려면 다음 스크립트를 실행해 줍니다.<br>
```bash
curl -fsSL https://raw.githubusercontent.com/shkim4u/m2m-travelbuddy/main/cloud9/bootstrap-v2-with-admin-user-trust.sh | bash -s -- c5.9xlarge
```

![](./assets/bootstrap-cloud9-via-cloudshell.png)

### 1.2. AWS Cloud9 환경 생성 (AWS Management Console 사용)
#### 1.2.1. Cloud9 환경 생성
1. [AWS Cloud9 콘솔창](https://console.aws.amazon.com/cloud9)에 접속한 후, ```환경 생성 (Create environment)``` 버튼을 클릭합니다.<br>
   ![Create Cloud9 Environment](../images/cloud9/create-cloud9-environment.png)
2. ```세부 정보 (Details)```에서 이름을 다음과 같이 cloud9-workspace으로 입력합니다.
   ```
   cloud9-workspace
   ```
   
   ![Cloud9 Name](../images/cloud9/create-cloud9-name.png)


[//]: # (3. &#40;중요&#41; "Network settings"에서 앞서 EKS 클러스터 생성 과정에서 함께 생성된 VPC 및 Subnet을 선택한다. 이는 이후에 생성할 데이터베이스에 접속하여 구성하는 작업을 함께 수행하기 위함이다.)

[//]: # (  - VPC: EKS 클러스터 생성 시 함께 생성된 VPC)

[//]: # (  - Subnet: PrivateSubnet-a <br>)

[//]: # (![Cloud9 생성 화면]&#40;./images/cloud9/cloud9-network-settings.png&#41;)

3. New EC2 Instance에서 인스턴스 타입 (Instance Type)으로 ```추가 인스턴스 유형``` > ```m5.4xlarge (16vCPU + 64GiB RAM)``` 혹은 선호하는 인스턴스 유형을 선택합니다. 플랫폼 (Platform)은 "Amazon Linux 2"를 선택하고 Timeout은 "1 Day"를 선택한 후 하단의 Create를 클릭하여 생성합니다. 나머지는 기본값을 그대로 사용합니다.

   ![Create Cloud9 Details](../images/cloud9/create-cloud9-details.png)

#### 1.2.2. IAM Role 생성

IAM Role은 특정 권한을 가진 IAM 자격 증명입니다. IAM 역할의 경우, IAM 사용자 및 AWS가 제공하는 서비스에 사용할 수 있습니다. 서비스에 IAM Role을 부여할 경우, 서비스가 사용자를 대신하여 수임받은 역할을 수행합니다.

본 실습에서는 Administrator access 정책을 가진 IAM Role을 생성하여 AWS Cloud9에 사용하지만, 실제 프로덕션 환경을 구동할 때에는 최소 권한을 부여하는 것이 적합합니다.

1. [여기](https://console.aws.amazon.com/iam/home#/roles$new?step=type&commonUseCase=EC2%2BEC2&selectedUseCase=EC2&policies=arn:aws:iam::aws:policy%2FAdministratorAccess)를 클릭하여 IAM Role 생성 페이지에 접속합니다.<br>

   ![Cloud9 IAM Role Create](../images/cloud9/create-cloud9-iam-role.png)

2. AWS Service 및 EC2가 선택된 것을 확인하고 Next: Permissions를 클릭합니다.
3. AdministratorAccess 정책이 선택된 것을 확인하고 Next: Tags를 클릭합니다.
4. 태그 추가(선택 사항) 단계에서 Next: Review를 클릭합니다.
5. Role name에 아래와 같이 cloud9-admin을 입력한 후, AdministratorAccess 관리형 정책이 추가된 것을 확인하고 Create role을 클릭합니다. (참고) Role 이름은 조금씩 다르게 지어도 되지만 기록해 두시면 좋습니다.
   ```
   cloud9-admin
   ```
   
   ![Create Cloud9 Role Review](../images/cloud9/create-cloud9-role-review.png)


#### 1.2.3. IDE (AWS Cloud9 인스턴스)에 IAM Role 부여

AWS Cloud9 환경은 EC2 인스턴스로 구동됩니다. 따라서 EC2 콘솔에서 AWS Cloud9 인스턴스에 방금 생성한 IAM Role을 부여합니다.

1. [여기](https://console.aws.amazon.com/ec2/v2/home?#Instances:sort=desc:launchTime)를 클릭하여 EC2 인스턴스 페이지에 접속합니다.
2. 해당 인스턴스를 선택 후, ```작업 (Actions) > 보안 (Security) > IAM 역할 수정 (Modify IAM Role)```을 클릭합니다 (참고: 설정된 언어에 따라 동일한 의미를 가지는 다른 언어로 표시될 수 있습니다).<br>
   ![attach-role.png](../images/cloud9/cloud9-instance-iam-role.png)
3. IAM Role에서 cloud9-admin을 선택한 후, Save 버튼을 클릭합니다.<br>
    > (참고) 여기에 표시되는 화면은 실제로 설정하고 있는 환경과 조금씩 다를 수 있습니다.<br>

    ![modify-role.png](../images/cloud9/modify-role-new2.png)

#### 1.2.4. IDE에서 IAM 설정 업데이트

기본적으로 AWS Cloud9는 IAM 인증 정보 (Credentials)를 동적으로 관리합니다. 해당 인증 정보는 Cloud9 환경을 생성한 Principal의 권한을 상속받아서 필요한 권한이 없을 수 있으며 15분마다 갱신되므로 긴 수행 시간을 가지는 작업의 경우에는 인증 토큰이 만료됨에 따라 실패할 수도 있습니다. 따라서 이를 비활성화하고 앞서 생성한 IAM Role을 Cloud9 환경에 부여하고자 합니다.

- AWS Cloud9 콘솔창에서 생성한 IDE로 다시 접속한 후, 우측 상단에 기어 아이콘을 클릭한 후, 사이드 바에서 "AWS Settings"를 클릭합니다.
- Credentials 항목에서 AWS managed temporary credentials 설정을 비활성화합니다.<br>
  ![disable-managed-credential.png](../images/cloud9/disable-managed-credentials.png)
- Preference tab을 종료합니다.

## 2. Cloud9 통합 환경 설정 파일 실행

Cloud9 설정에 필요한 사항을 통합하여 구성한 쉘 스크립트 파일을 아래와 같이 실행합니다.

여기에는 다음 사항이 포함됩니다.

1. IDE IAM 설정 확인
2. 쿠버네테스 (Amazon EKS) 작업을 위한 Tooling
   * kubectl 설치
   * eksctl 설치
   * k9s 설치
   * Helm 설치
3. AWS CLI 업데이트
4. AWS CDK 업그레이드
5. 기타 도구 설치 및 구성
   * AWS SSM 세션 매니저 플러그인 설치
   * AWS Cloud9 CLI 설치
   * jq 설치하기
   * yq 설치하기
   * bash-completion 설치하기
6. Cloud9 추가 설정하기
7. 디스크 증설
8. CUDA Deep Neural Network (cuDNN) 라이브러리
9. [2023-12-06 추가] Terraform 라이선스 정책 변경으로 인해 Cloud9에서 Terraform이 제거됨으로써 수동 설치


```bash
cd ~/environment/
curl -fsSL https://raw.githubusercontent.com/shkim4u/m2m-travelbuddy/main/cloud9/cloud9.sh | bash
```

## 3. 실습 가이드 및 소스 리포지터리 받기 (git clone)
향후 실습을 도와줄 통합 가이드를 다운로드 받습니다.

```bash
cd ~/environment/
git clone https://github.com/shkim4u/m2m-travelbuddy.git
cd m2m-travelbuddy
```

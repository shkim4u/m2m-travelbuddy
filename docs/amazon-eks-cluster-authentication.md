# Amazon EKS와 AWS IAM 인증자 (Authenticator)에 대한 설명

## 1. Amazon EKS 인증을 위한 AWS IAM 인증자에 간단한 설명
2018년에 Amazon EKS가 출시됨과 동시에, 클러스터에 대해 인증할 수 있는 엔티티로서 AWS IAM 사용자 및 역할에 대한 기본 지원이 포함되었습니다.<br>
인증은 AWS STS (AWS 보안 토큰 서비스)의 GetCallerIdentity 액션에서 릴레이되며, 이 액션은 작업을 호출하는 데 작업을 수행하는데 필요한 자격 증명을 가지는 IAM 사용자 또는 역할에 대한 세부 정보를 반환합니다. 이 인증 흐름은 ```aws-iam-authenticator```라는 쿠버네티스용 AWS IAM 인증자 도구에 의해 구현되고 수행됩니다.<br>
```aws-iam-authenticator``` 도구는 AWS IAM 자격 증명을 사용하여 Kubernetes 클러스터에 인증하는 메커니즘을 만들기 위해 오픈 소스 이니셔티브로 시작되었으며, 추후 클라우드 공급자 특별 관심 그룹 (SIG)에 기부되었습니다.<br>
이 프로젝트는 현재 Amazon EKS 엔지니어가 유지 관리하고 있습니다.<br>
해당 프로젝트의 GitHub 주소는 다음과 같습니다.<br>
* [[AWS IAM Authenticator for Kubernetes]](https://github.com/kubernetes-sigs/aws-iam-authenticator) (https://github.com/kubernetes-sigs/aws-iam-authenticator)

Kubernetes용 AWS IAM 인증자는 모든 Kubernetes 클러스터에 설치할 수 있으며, AWS 클라우드와 온프레미스(Amazon EKS Anywhere)의 모든 EKS 클러스터에 기본적으로 설치되어 있습니다.<br>
클러스터 인프라가 제공자에 의해 관리되는 경우, 최종 사용자는 API 서버 Pod를 포함한 컨트롤 플레인 리소스에 액세스할 수 없습니다. AWS IAM 인증자도 컨트롤 플레인에도 배포되기 때문에 최종 사용자는 관리형 EKS 클러스터의 리소스에 액세스할 수 없지만, CloudWatch에서 로그를 볼 수는 있습니다.

이 설명 글은 AWS IAM 인증자 서버의 전체 백엔드 구현에 대해 자세히 설명하지는 않겠지만, 이 인증자 서버는 API 서버에서 토큰을 수신하고 이를 사용하여 일치하는 ID( 사용자 또는 역할) 세부 정보를 AWS STS (AWS Security Token Service)에 쿼리하는 핵심 구성 요소라는 점을 강조하고 싶습니다. 그런 다음, AWS IAM 인증자 서버는 매핑을 사용하여 AWS ID를 사용자 이름과 그룹이 있는 Kubernetes ID로 변환합니다. 매핑은 "aws-auth"라는 이름의 컨피그맵에 지정되며 클러스터 관리자가 편집할 수 있습니다. 이 컨피그맵의 내용과 구조에 대한 자세한 내용은 위에 적어드린 소스 코드를 살펴봄으로써 좀 더 깊이 파악할 수 있습니다. 또한 이해를 돕는 기본적인 [[AWS 문서]](https://docs.aws.amazon.com/eks/latest/userguide/cluster-auth.html)도 마련되어 있습니다. IAM 인증자 서버는 컨트롤 플레인 인스턴스에서 실행되며, EKS API 서버는 요청의 토큰을 AWS IAM 인증자 서버로 보내는 인증 웹훅 (Webhook)으로 구성됩니다.

이 과정을 간략하게 나타낸 그림 및 순서에 대한 설명은 다음과 같습니다.
![](./assets/amazon-eks-authentication-flow-simple-frame.png)<br>
1. 사용자가 (kubectl 도구 등을 통해) API 서버에 ```get pods```와 같은 요청을 보냄으로써 쿠버네티스 리소스를 가져오려고 합니다. 요청은 "Authorization" 헤더에 토큰을 포함하고 있으며, 이 토큰은 AWS STS에 서명된 요청 (Signed Request)의 Base64 인코딩된 문자열입니다. 이 토큰을 얻는 과정은 아래에 다시 한번 더 자세하게 기술하도록 하겠습니다.

2. API 서버는 사용자로부터 요청을 수신하고 토큰을 추출하여 요청 본문과 함께 AWS IAM 인증자 서버의 /authenticate 엔드포인트로 보냅니다.

3. AWS IAM 인증자 서버는 API 서버로부터 토큰을 수신하고, Base64로 토큰을 디코딩한 후 일련의 유효성 검사를 수행합니다. 모든 유효성 검사를 통과하면 AWS IAM 인증자는 토큰의 서명된 요청을 AWS STS로 보냅니다.

4. AWS STS는 AWS IAM 인증자 서버에서 서명된 요청을 수신하고 서명의 유효성을 검사합니다. 서명이 유효하면 GetCallerIdentityResponse에 <u>**```AWS IAM 아이덴터티(주체; User 혹은 Role)```**</u> 상세 정보를 담아 AWS IAM 인증자 서버로 보냅니다.

5. AWS IAM 인증자 서버는 AWS STS에서 GetCallerIdentityResponse 객체를 수신하고 ```aws-auth``` 컨피그맵의 규칙에 따라 일치하는 Kubernetes ID에 매핑합니다. 결과적으로 매핑되는 Kubernetes ID에는 클러스터 범위의 사용자 이름과 그룹이 있으며, 이 그룹은 RBAC(역할 기반 액세스 제어) 메커니즘에서 권한 부여를 확인하는 데 사용됩니다. AWS IAM 인증자 서버는 이렇게 매핑된 최종 Kubernetes ID를 API 서버로 전송합니다.

6. API 서버는 AWS IAM 인증자 서버로부터 <u>**```쿠버네티스 아이덴터티```**</u>를 수신하고 RBAC를 사용하여 권한을 확인합니다. 해당 ID가 작업을 수행할 권한이 있는 경우, Kubernetes 리소스 응답이 사용자에게 전송됩니다. 이 경우에는 1에서 요청한 대로 파드 목록 (get pods)입니다.

## 2. (TL;DR) Amazon EKS 인증을 위한 AWS IAM 인증자의 동작 추가 설명
IAM 인증자의 동작 원리를 좀 더 자세하게 설명하는 그림과 이에 대한 상세한 설명은 다음과 같다.<br>
![](./assets/amazon-eks-authentication-flow-deep-dive-frame.png)<br>

1. ```kubectl``` 명령이 수행되면 ```KUBECONFIG``` 환경 변수가 가리키는 Config 파일 내의 활성 컨텍스트에 Credential Plugin으로 설정된 AWS CLI를 수행합니다.  Config 파일의 예시 및 AWS CLI 명령은 다음과 같은 형식을 가지고 있습니다. ```KUBECONFIG``` 환경 변수가 설정되어 있지 않으면 기본적으로 ```~/.kube/config``` 파일을 사용합니다.<br>
    1. ```~/.kube/config``` 파일 예시
        ```yaml
        apiVersion: v1
        clusters:
        - cluster:
            certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0F...<생략>
            server: https://B35F030A6D8DC28D54BE1FE3635ABBAA.gr7.ap-northeast-2.eks.amazonaws.com
          name: arn:aws:eks:ap-northeast-2:123456789012:cluster/M2M-EksCluster
        contexts: 
        - context:
            cluster: arn:aws:eks:ap-northeast-2:123456789012:cluster/M2M-EksCluster
            user: arn:aws:eks:ap-northeast-2:123456789012:cluster/M2M-EksCluster
          name: M2M-EksCluster
        current-context: M2M-EksCluster
        kind: Config
        preferences: {}
        users:
        - name: arn:aws:eks:ap-northeast-2:537682470830:cluster/M2M-EksCluster
          user:
            exec:
              apiVersion: client.authentication.k8s.io/v1beta1
              args:
              - --region
              - ap-northeast-2
              - eks
              - get-token
              - --cluster-name
              - M2M-EksCluster
              - --role
                - arn:aws:iam::537682470830:role/M2M-EksCluster-AdminRole
              command: aws
              env:
              - name: AWS_PROFILE
                value: workload
          ``` 
    2. ```aws eks get-token --cluster <클러스터 이름> [--role <AWS IAM Role ARN>]```
    3. Kubernetes Config 파일의 Credential Plugin 규약에 대한 자세한 내용은 [[Kubernetes 문서 > API Access Control > Authentication]](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuration)에서 찾을 수 있습니다.

2. 실제로 ```aws eks get-token --cluster <클러스터 이름> [--role <AWS IAM Role ARN>]``` 명령을 수행해 봄으로써 반환되는 토큰값을 살펴봅니다.<br>
   ```bash
   # EKS 클러스터 이름 설정
   export CLUSTER_NAME=M2M-EksCluster
   
   # 아래는 ~/.kube/config에 Credential Plugin으로서 설정된 AWS CLI 명령어를 실행합니다.
   # kubectl이 실행될 때 묵시적으로 실행되며, 결과로서 얻어지는 토큰이 API Server로 전달됩니다.
   export TOKEN=$(aws eks get-token --cluster-name $CLUSTER_NAME | jq '.status.token' | sed "s/\"//g" | sed "s/k8s-aws-v1\.//g")
   echo $TOKEN
   ```

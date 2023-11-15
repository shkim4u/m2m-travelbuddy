# Amazon EKS와 AWS IAM 인증자 (Authenticator)에 대한 설명

## 1. Amazon EKS 인증을 위한 AWS IAM 인증자에 간단한 설명
2018년에 Amazon EKS가 출시됨과 동시에, 클러스터에 대해 인증할 수 있는 엔티티로서 AWS IAM 사용자 및 역할에 대한 기본 지원이 포함되었습니다.<br>
인증은 AWS STS (AWS 보안 토큰 서비스)의 GetCallerIdentity 액션에서 릴레이되며, 이 액션은 쿠버네테스 작업을 수행하는데 필요한 자격 증명을 가지는 IAM 사용자 또는 역할에 대한 세부 정보를 반환합니다. 이 인증 흐름은 ```aws-iam-authenticator```라는 쿠버네티스용 AWS IAM 인증자 도구에 의해 구현되고 수행됩니다.<br>
```aws-iam-authenticator``` 도구는 AWS IAM 자격 증명을 사용하여 Kubernetes 클러스터에 인증하는 메커니즘을 만들기 위해 오픈 소스 이니셔티브로 시작되었으며, 추후 클라우드 공급자 특별 관심 그룹 (SIG)에 기부되었습니다.<br>
이 프로젝트는 현재 Amazon EKS 엔지니어가 유지 관리하고 있습니다.<br>
해당 프로젝트의 GitHub 주소는 다음과 같습니다.<br>
* [[AWS IAM Authenticator for Kubernetes]](https://github.com/kubernetes-sigs/aws-iam-authenticator) (https://github.com/kubernetes-sigs/aws-iam-authenticator)

Kubernetes용 AWS IAM 인증자는 모든 Kubernetes 클러스터에 설치할 수 있으며, AWS 클라우드와 온프레미스(Amazon EKS Anywhere)의 모든 EKS 클러스터에 기본적으로 설치되어 있습니다.<br>
클러스터 인프라가 제공자에 의해 관리되는 경우, 최종 사용자는 API 서버 Pod를 포함한 컨트롤 플레인 리소스에 액세스할 수 없습니다. AWS IAM 인증자도 컨트롤 플레인에도 배포되기 때문에 최종 사용자는 관리형 EKS 클러스터의 리소스에 액세스할 수 없지만, CloudWatch에서 로그를 볼 수는 있습니다.

이 설명 글은 AWS IAM 인증자 서버의 전체 백엔드 구현에 대해 자세히 설명하지는 않겠지만, 이 인증자 서버는 API 서버에서 토큰을 수신하고 이를 사용하여 일치하는 ID (사용자 또는 역할) 세부 정보를 AWS STS (AWS Security Token Service)에 쿼리하는 핵심 구성 요소라는 점을 강조하고 싶습니다. 그런 다음, AWS IAM 인증자 서버는 매핑을 사용하여 AWS ID를 사용자 이름과 그룹이 있는 Kubernetes ID로 변환합니다. 매핑은 "aws-auth"라는 이름의 컨피그맵에 지정되며 클러스터 관리자가 편집할 수 있습니다. 이 컨피그맵의 내용과 구조에 대한 자세한 내용은 위에 적어드린 소스 코드를 살펴봄으로써 좀 더 깊이 파악할 수 있습니다. 또한 이해를 돕는 기본적인 [[AWS 문서]](https://docs.aws.amazon.com/eks/latest/userguide/cluster-auth.html)도 마련되어 있습니다. IAM 인증자 서버는 컨트롤 플레인 인스턴스에서 실행되며, EKS API 서버는 요청의 토큰을 AWS IAM 인증자 서버로 보내는 인증 웹훅 (Webhook)으로 구성됩니다.

이 과정을 간략하게 나타낸 그림 및 순서에 대한 설명은 다음과 같습니다.
![](./assets/amazon-eks-authentication-flow-simple-frame.png)<br>
1. 사용자가 (kubectl 도구 등을 통해) API 서버에 ```get pods```와 같은 요청을 보냄으로써 쿠버네티스 리소스를 가져오려고 합니다. 요청은 "Authorization" 헤더에 토큰을 포함하고 있으며, 이 토큰은 AWS STS에 서명된 요청 (Signed Request)의 Base64 인코딩된 문자열입니다. 이 토큰을 얻는 과정은 아래에 다시 한번 더 자세하게 기술하도록 하겠습니다.

2. API 서버는 사용자로부터 요청을 수신하고 토큰을 추출하여 요청 본문과 함께 AWS IAM 인증자 서버의 /authenticate 엔드포인트로 보냅니다.

3. AWS IAM 인증자 서버는 API 서버로부터 토큰을 수신하고, Base64로 토큰을 디코딩한 후 일련의 유효성 검사를 수행합니다. 모든 유효성 검사를 통과하면 AWS IAM 인증자는 토큰의 서명된 요청을 AWS STS로 보냅니다.

4. AWS STS는 AWS IAM 인증자 서버에서 서명된 요청을 수신하고 서명의 유효성을 검사합니다. 서명이 유효하면 GetCallerIdentityResponse에 <u>**```AWS IAM 아이덴터티(주체; User 혹은 Role)```**</u> 상세 정보를 담아 AWS IAM 인증자 서버로 보냅니다.

5. AWS IAM 인증자 서버는 AWS STS에서 GetCallerIdentityResponse 객체를 수신하고 ```aws-auth``` 컨피그맵의 규칙에 따라 일치하는 Kubernetes ID에 매핑합니다. 결과적으로 매핑되는 Kubernetes ID에는 클러스터 범위의 사용자 이름과 그룹이 있으며, 이 그룹은 RBAC(역할 기반 액세스 제어) 메커니즘에서 권한 부여를 확인하는 데 사용됩니다. AWS IAM 인증자 서버는 이렇게 매핑된 최종 Kubernetes ID를 API 서버로 전송합니다.

6. API 서버는 AWS IAM 인증자 서버로부터 <u>**```쿠버네티스 아이덴터티```**</u>를 수신하고 RBAC를 사용하여 권한을 확인합니다. 해당 ID가 작업을 수행할 권한이 있는 경우, Kubernetes 리소스 응답이 사용자에게 전송됩니다. 이 경우에는 1에서 요청한 대로 파드 목록 (get pods)입니다.

## 2. (TL;DR) Amazon EKS 인증 과정에서 AWS IAM 인증자 동작에 대한 깊은 설명
### 2.1. AWS IAM 인증자의 단계별 동작 원리
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

2. 실제로 ```aws eks get-token --cluster <클러스터 이름> [--role <AWS IAM Role ARN>]``` 명령을 수행해 봄으로써 반환되는 토큰값 (서명된 요청 URL; Presigned Request URL)을 살펴봅니다.<br>
   ```bash
   # Region 및 Account ID 설정
   export AWS_REGION=ap-northeast-2
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text) && echo $AWS_ACCOUNT_ID

   # EKS 클러스터 이름 및 ARN 설정
   export CLUSTER_NAME=M2M-EksCluster
   export CLUSTER_ARN="arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/${CLUSTER_NAME}" && echo $CLUSTER_ARN
   
   # ~/.kube/config 파일 내의 해당 클러스터에 설정된 사용자 확인
   #kubectl config view -o=jsonpath='{.users}' | jq #(Deprecated)
   export CLUSTER_USER=$(kubectl config view -o jsonpath="{.contexts[?(.context.cluster==\"$CLUSTER_ARN\")].context.user}") && echo $CLUSTER_USER
   
   # 위에서 확인된 사용자의 설정된 Credential Plugin (aws eks get-token) 확인 및 실행
   # 해당 명령은 "서명된 요청 URL (Presigned Request URL)"을 토큰값으로 반환
   export AWS_EKS_EXEC_COMMAND=$(kubectl config view -o=jsonpath="{.users[?(.name==\"$CLUSTER_USER\")].user.exec.command}") && echo $AWS_EKS_EXEC_COMMAND
   export AWS_EKS_EXEC_ARGS=$(kubectl config view -o=jsonpath="{.users[?(.name==\"$CLUSTER_USER\")].user.exec.args[*]}") && echo $AWS_EKS_EXEC_ARGS
   export AWS_EKS_TOKEN_COMMAND="${AWS_EKS_EXEC_COMMAND} ${AWS_EKS_EXEC_ARGS}" && echo $AWS_EKS_TOKEN_COMMAND
   bash -c ${AWS_EKS_TOKEN_COMMAND}
   
   # 반환되는 토큰값 (서명된 요청 URL)을 환경변수로 저장 - Base64로 인코딩된 부분만 발췌
   # (참고) 실제로 ```kubectl```로 전달되는 값은 토큰의 전체 값이며, 여기서는 확인을 위해 Base64 인코됭된 부분만 발췌
   # export TOKEN=$(${AWS_EKS_TOKEN_COMMAND} | jq -r '.status.token' | grep -oP '(?<=k8s-aws-v1.).*')
   export TOKEN=$(bash -c ${AWS_EKS_TOKEN_COMMAND} | jq -r '.status.token' | sed "s/\"//g" | sed "s/k8s-aws-v1\.//g") && echo $TOKEN
   ```
   
   ![](./assets/aws-eks-get-token-01.png)

   > (부가 설명)
   > AWS STS의 GetCallerIdentity API를 호출하기 위해서는 AWS IAM Access Key ID와 Secret Access Key와 같은 AWS IAM Credential (자격 증명)이 필요하지만, ```AWS IAM 인증자``` 웹훅 서버는 어떤 AWS 아이덴터티와 연결될 수 없으며 따라서 이러한 인증 자격을 가지고 있지 않다. 이러한 경우에 Presigned URL을 이용하여 GetCallerIdentity API를 호출하면 AWS IAM 자격 증명없이 호출이 가능하다.


3. AWS STS를 호출하여 얻어진 토큰 (서명된 요청 URL)이 AWS CLI ```aws eks get-token```로 반환됩니다.<br>
4. AWS CLI ```aws eks get-token``` 명령은 AWS STS로부터 반환받은 토큰 (서명된 요청 URL)을 ```kubectl```로 전달합니다.<br>
5. ```kubectl``` 명령은 해당 토큰 (서명된 요청 URL)을 HTTP 헤더에 설정하여 쿠버네테스 API 서버로 요청을 전달합니다.<br>
6. 요청을 받은 쿠버네테스 API 서버는 컨트롤 플레인에 미리 설정된 ```AWS IAM 인증자``` 웹훅 서버로 토큰 (서명된 요청 URL)을 전달합니다.<br>
7. ```AWS IAM 인증자``` 웹훅 서버는 토큰 (서멍된 요청 URL)을 디코딩하고 검증한 후에 해당 URL을 호출함으로써 최초 ```kubectl``` 명령을 호출한 AWS 아이덴터티를 확인 시도합니다. 이 URL에는 ```GetCallerIdentity``` AWS API 호출이 포함되어 있으며, 이 과정은 아래와 유사합니다.<br>
   ```bash
   # URL-safe한 Base64 유틸리티 설치
   # (https://stackoverflow.com/questions/55389211/string-based-data-encoding-base64-vs-base64url)
   # 62, 63번 (0-base) Encoding이 "+", "/" 에서 "-", "_"로 대체
   npm install -g base64-url-cli
   
   # 토큰값을 디코드하여 "서명된 요청 URL"을 복원한 후 환경 변수로 저장
   export DECODED_PRESIGNED_REQUEST_URL=$(base64url decode $TOKEN)
   echo $DECODED_PRESIGNED_REQUEST_URL 

   # (정보 확인) "서명된 요청 URL"을 호출해 본다.
   #curl $DECODED_PRESIGNED_REQUEST_URL
   
   # (정보 확인) "서명된 요청 URL"을 호출할 때 HTTP 헤더에 클러스터 이름을 추가하여야 호출 성공
   curl -H "x-k8s-aws-id: ${CLUSTER_NAME}" $DECODED_PRESIGNED_REQUEST_URL
   ```
   > 서명된 요청 URL의 디코딩된 값은 다음과 유사합니다.<br>
   ***https://sts.ap-northeast-2.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIAXYIVY6U6TOD2QYET%2F20231008%2Fap-northeast-2%2Fsts%2Faws4_request&X-Amz-Date=20231008T151427Z&X-Amz-Expires=60&X-Amz-SignedHeaders=host%3Bx-k8s-aws-id&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEJ%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDmFwLW5vcnRoZWFzdC0yIkgwRgIhAJ1Ob12o8QuswEwftRHBzCfrCl%2FXzT8z58FSGmghB2SAAiEAo8cCvtO0MoiCN4%2FeVcBW8DsKSx4cHE5MMm%2BhJdxud4IqpQIIqP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgw1MzMxNTg0OTE0NTMiDKEPTz4%2BrIaFeVQOlir5AQXHE14SiItVurqW8fwOPNxmuF1%2F3BMciltKF%2BTbEaUN3bKADyAmwfaST90PFdyBcwocPAC0m639mFvDv%2BgwWZ7aMCdNnf%2BjkH9DoP1H6MjT2GueXUrs89Oo58vNkITvx1wcyM%2F%2FqQUcoh54h6IdFQG65GrDm3gFwe7pjlqOlNbUHG9UNFwRLp07FLXSWGefn5dag9kK5WChwjvPjy3p2MIseSNDDihQ4sU1db2rA1AXpaEeHVsdrm46KG63G6s5mr0hzfPHgstKBXt4rp3ZQPCL%2FLMENXo8ySt%2F5FdnyqQnjQkO0UkCb21GD4naIfgVF0TVyuh%2F8PVF1TDTjoupBjqcAXw5jfLSigi663bxU%2FssP%2FXdkL8kLM4HR%2BErfI5dglGLLrMxwZQYVxYM2XKx2MXEK5WN3qHYmcTYLBC1vcU1Z7rlmkVkXvruPVU3jjpBtrl3%2F8tqRNUBzDbX%2FpRE1x02irBNRqGoATD4T3HeTxTmXv23A8CB605PIYUXQB0Ulr6fBUOmlzCNCMFCl2QrWArc%2B9NYm4L%2FOtKIcUWdyw%3D%3D&X-Amz-Signature=8a7d6540d9a048c7bc85fadda0a63f6570defc93022a684c6a25e5ba36039081***

```AWS IAM 인증자``` 웹훅 서버에서 수행하는 검증에는 다음과 같은 것들이 있습니다.<br>
* URL 체계는 HTTPS여야 합니다.
* URL 호스트는 유효한 STS 호스트여야 합니다.
* URL 경로는 "/"여야 합니다.
* 모든 쿼리 매개 변수를 살펴보면서 각 매개 변수 이름이 허용 목록에 있어야 하는지 확인합니다.
* "action" 매개 변수는 "GetCallerIdentity"여야 합니다.
* 클러스터 ID 헤더는 요청의 일부로 서명됩니다.
* "X-Amz-Credential" 매개변수에서 액세스 키 값을 추출합니다.

8. 위 7에 의해 호출된 결과 (서명된 호출 URL)는 ```AWS IAM 인증자``` 웹훅 서버로 반환되며 그 형태는 아래와 같습니다.<br>
   ![](./assets/aws-iam-authenticator-GetCallerIdentity-Presigned-URL.png)

9. ```AWS IAM 인증자``` 웹훅 서버는 ```aws-auth``` ConfigMap에 설정된 정보를 살펴봄으로써, 8번 과정에서 얻어진 AWS 아이덴터티와 (AWS User 혹은 Role) 매핑된 쿠버네테스 아이덴터티가 (User 혹은 Group) 있는지 확인합니다. 만약 매핑된 쿠버네테스 아이덴터티가 발견되면 이 정보를 ```API 서버```로 반환합니다.<br>
   ![](./assets/aws-iam-authenticator-configmap.png)

10. 쿠버네테스 ```API 서버```는 ```AWS IAM 인증자```로부터 전달받은 쿠버네테스 아이덴터티가 RBAC (ClusterRoleBinding/RoleBinding)에 의해 요청된 작업을 수행할 수 있는 권한이 있는지 확인한 후, 권한이 있다면 최종적으로 클라이언트가 (```kubectl``` 등) 요청한 작업의 결과를 클라이언트로 반환합니다.<br>
   ![](./assets/kubernetes-cluster-admin-clusterrolebinding-01.png)<br>
   ![](./assets/kubernetes-cluster-admin-clusterrolebinding-02.png)<br>

### 2.2. Putting all thing together 
위에서 설명된 과정을 결합하여 토큰 (서명된 요청 URL)을 쿠버네테스 ```API 서버``` 호출에 직접 사용해 보면 다음과 같습니다.<br>
> (참고) ```kubectl``` 명령은 단계별 Verbosity를 제공하는데 (--v=<n> 옵션) 아래와 같은 방법으로 Verbosity 별로 실행 내용을 살펴볼 수 있습니다.<br>
> ```kubectl get pods --v=8```

```bash
# Region 및 Account ID 설정
export AWS_REGION=ap-northeast-2
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text) && echo $AWS_ACCOUNT_ID

# EKS 클러스터 이름 및 ARN 설정
export CLUSTER_NAME=M2M-EksCluster
export CLUSTER_ARN="arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/${CLUSTER_NAME}" && echo $CLUSTER_ARN

# ~/.kube/config 파일 내의 해당 클러스터에 설정된 사용자 확인
#kubectl config view -o=jsonpath='{.users}' | jq #(Deprecated)
export CLUSTER_USER=$(kubectl config view -o jsonpath="{.contexts[?(.context.cluster==\"$CLUSTER_ARN\")].context.user}") && echo $CLUSTER_USER

# 위에서 확인된 사용자의 설정된 Credential Plugin (aws eks get-token) 확인 및 실행
# 해당 명령은 "서명된 요청 URL (Presigned Request URL)"을 토큰값으로 반환
export AWS_EKS_EXEC_COMMAND=$(kubectl config view -o=jsonpath="{.users[?(.name==\"$CLUSTER_USER\")].user.exec.command}") && echo $AWS_EKS_EXEC_COMMAND
export AWS_EKS_EXEC_ARGS=$(kubectl config view -o=jsonpath="{.users[?(.name==\"$CLUSTER_USER\")].user.exec.args[*]}") && echo $AWS_EKS_EXEC_ARGS
export AWS_EKS_TOKEN_COMMAND="${AWS_EKS_EXEC_COMMAND} ${AWS_EKS_EXEC_ARGS}" && echo $AWS_EKS_TOKEN_COMMAND
bash -c ${AWS_EKS_TOKEN_COMMAND}

# 반환되는 토큰값 (서명된 요청 URL)을 환경변수로 저장 - Base64로 인코딩된 부분만 발췌
# (참고) 실제로 ```kubectl```로 전달되는 값은 토큰의 전체 값이며, 여기서는 확인을 위해 Base64 인코됭된 부분만 발췌
# export TOKEN=$(${AWS_EKS_TOKEN_COMMAND} | jq -r '.status.token' | grep -oP '(?<=k8s-aws-v1.).*')
export TOKEN=$(bash -c ${AWS_EKS_TOKEN_COMMAND} | jq -r '.status.token' | sed "s/\"//g" | sed "s/k8s-aws-v1\.//g") && echo $TOKEN

### 여기까지가 "kubectl" 호출 시 kubeconfig 내에 설정된 Credential Pluging이 수행되는 과정이다.

### 아래부터가 kubectl 내에서 실제로 수행되는 작업이다.

# Kubernetes API 서버 주소를 확인하고 환경변수로 지정 
export K8S_API_SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_ARN\")].cluster.server}") && echo $K8S_API_SERVER

# Namespace 조회 보는 API 호출
curl -k -X GET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" $K8S_API_SERVER/api/v1/namespaces

# Node 목록을 보는 API 호출
curl -k -X GET -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" $K8S_API_SERVER/api/v1/nodes
```

### 2.3. 결론 (Conclusion)
```AWS IAM 인증자는``` 쿠버네테스 클러스터의 인증을 ```AWS IAM``` 체계와 결합시키는 가교 (Bridge) 역할을 수행합니다. ```정확한 인증 정보를 제공하는 주체만을 선별하고, 또한 인증 정보가 정확한 주체는 반드시 인증됨을 보장하는``` (if and only if) 인증의 원칙을 따르려는 설계를 가지고 있다고 볼 수 있습니다.<br>
```kubeconfig```의 Credential Plugin과 ```AWS IAM 인증자``` 웹훅 서버의 관계를 비유하자면 다음과 같습니다.<br>
* ```kubeconfig```의 Credential Plugin: 신뢰받는 중재자 (Mediator, 즉 AWS STS)에게 인증 표식을 맡기고 이를 확인하게 함으로써 신원을 확인받고자 하는 주체<br>
* ```AWS IAM 인증자``` 웹훅 서버: 인증을 요청하는 모든 주체를 기본적으로 믿지 않으며 (Zero Trust), 신뢰받는 중재자 (AWS STS)에게 맡겨진 인증 주체의 인증 표식을 확인하고 이를 다른 문맥의 인증 주체, 즉 쿠버네테스의 아이덴터티로 변환해 줍니다.

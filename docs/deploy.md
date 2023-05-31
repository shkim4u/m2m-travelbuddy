# TravelBuddy 애플리케이션을 EKS에 배포

## Agenda

1. Bastion 호스트에 접속해서 TravelBuddy 애플리케이션 실행해보기 
   1. Docker 설치 
   2. TravelBuddy 컨테이너 실행
2. EKS에 배포
   1. EKS 배포 형상 (Manifest) 리포지터리 클론하기
   2. Manifest 준비하기
   2. Manifest로 TravelBuddy 배포하기

## 1. Bastion 호스트에 접속해서 TravelBuddy 애플리케이션 실행해보기
Bastion 호스트에 SSM 세션 매니저로 접속하여 다음을 수행합니다.

### 1.1. Docker 설치

```bash
# 인스턴스에 설치한 패키지 및 패키지 캐시를 업데이트
sudo yum update -y

# 최신 Docker Engine 패키지를 설치
sudo amazon-linux-extras install docker

# Docker 서비스를 시작
sudo service docker start

# 시스템이 재부팅될 때마다 Docker 대몬이 시작되도록 하려면 다음 명령을 실행
sudo systemctl enable docker

# sudo를 사용하지 않고도 Docker 명령을 실행할 수 있도록 docker 그룹에 ec2-user를 추가
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker ssm-user

# 만일 docker를 실행했을 때 권한 오류가 발생하면 인스턴스를 재부팅해봅니다.
```

참고: [Amazon Linux 2에 Docker 설치](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-container-image.html#create-container-image-install-docker)

### 1.2. TravelBuddy 컨테이너 실행

#### STEP 1. Docker Login

AWS 콘솔에서 ECR로 이동합니다.<br>
리포지터리에서 `m2m-buildanddeliverystack-repository`으로 이동한 후 `푸시 명령 보기 (View push commands)` 버튼을 클릭하여 표시되는 가이드의 1번 명령어를 복사합니다.<br>
![TravelBuddy ECR Push Command](./assets/travelbuddy-ecr-push-command-step-1.png)

다시 Bastion 호스트의 Shell로 돌아와서 위에서 복사한 명령어를 이용하여 docker login을 실행합니다.
```bash
# (예시) 아래를 자신이 복사한 명령으로 대체하여 실행할 것
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 256878912116.dkr.ecr.ap-northeast-2.amazonaws.com
```
![TravelBuddy ECR Login Success](./assets/travelbuddy-ecr-login-success.png)

#### STEP 2. 환경 변수 설정

```bash
# 아래에 CF로 배포한 환경의 RDS 주소로 대체할 것
# (예시) export RDS_ENDPOINT=travelbuddy-rds-dbinstance-yh3bquza02iz.ch3z4vioqkk9.ap-northeast-2.rds.amazonaws.com
export RDS_ENDPOINT=<RDS_ENDPOINT>
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
export AWS_REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document| grep region |awk -F\" '{print $4}'`
```

#### STEP 3. travelbuddy 컨테이너 실행

```bash
# env.yaml 파일의 내용을 확인하여 환경변수를 주입하여 컨테이너 실행
docker run --rm \
  -e JDBC_CONNECTION_STRING="jdbc:mysql://${RDS_ENDPOINT}:3306/travelbuddy?useSSL=false" \
  -e JDBC_UID=root \
  -e JDBC_PWD=labpassword \
  -dp 8080:8080 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/m2m-buildanddeliverystack-repository:latest

# 컨테이너 이름을 확인
docker ps

# 로그 확인
docker logs <컨테이너 이름>
```

#### STEP 4. travelbuddy 애플리케이션 실행 확인

```bash
# 페이지 요청
curl localhost:8080/travelbuddy/

# html 페이지 응답 확인 (웹브라우저로도 확인 가능)
# <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.# w3.org/TR/html4/loose.dtd">
# <html lang="en">
# <head>
# <meta charset="utf-8">
# [...]
```

#### STEP 5. 정리하기

```bash
# 컨테이너 중지하기
docker stop <컨테이너 이름>
docker rm <컨테이너 이름>
```

## 2. EKS 배포
우리는 앞서 모놀리스 어플리케이션의 배포 체계를 다소 단순한 형태의 Push 기반 GitOps 파이프라인으로 구성할 것이라고 하였습니다.<br>
![Push 기반 GitOps 체계](./assets/M2M-Replatform-Architecture.png)

그리고 어플리케이션을 빌드 및 컨테이너화하여 ECR 리포지터리에 푸시하여 빌드 및 전달 파이프라인을 완료하였고, Bastion 호스트에서 데이터베이스에 접속한 후 어플리케이션이 동작 가능함을 확인하였습니다.

이번에는 배포 Manifest를 작성함으로써 배포 파이프라인 (Push 기반)을 꾸며보도록 하겠습니다.

다행히도 배포 파이프라인을 위한 CodeCommit 리포지터리와 이로부터 Trigger되는 배포 파이프라인은 EKS 클러스터를 CDK로 생성할 때 함께 생성되어 있으므로 우리는 이를 이용하도록 합니다.

### 2.1. EKS 배포 형상 리포지터리를 위한 Manifest 파일 준비하기
이번에는 Bastion 호스트가 아닌 먼저 사용하던 Cloud9 환경을 다시 사용합니다.<br>

```bash
# 1. 배포 매니페스트 파일을 담을 디렉토리 생성
mkdir -p ~/environment/m2m-travelbuddy/applications/TravelBuddy/deploy
cd ~/environment/m2m-travelbuddy/applications/TravelBuddy/deploy

```

### manifest 준비하기

manifests 폴더 (/home/ec2-user/environment/manifests)로 이동하여 아래의 값을 붙여넣습니다. 이 때, 이미지 값에는 ECR에 push한 이미지의 URL 값을 넣습니다.

또한 `<RDS_ENDPOINT>` 값을 생성한 RDS의 값으로 변경합니다.

```bash
cd /home/ec2-user/environment/manifests

cat <<EOF> deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: travelbuddy
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: travelbuddy
  template:
    metadata:
      labels:
        app: travelbuddy
    spec:
      containers:
      - name: travelbuddy
        image: $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/travelbuddy:latest
        imagePullPolicy: Always
        ports:
          - containerPort: 8080
        env:
        - name: JDBC_CONNECTION_STRING
          value: "jdbc:mysql://<RDS_ENDPOINT>:3306/travelbuddy?useSSL=false"
        - name: JDBC_UID
          value: "root"
        - name: JDBC_PWD
          value: "labpassword"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
EOF
```

```bash
cat <<EOF> service.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: travelbuddy-service
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: "/travelbuddy/"
spec:
  selector:
    app: travelbuddy
  type: NodePort
  ports:
    - port: 80 # 서비스가 생성할 포트
      targetPort: 8080 # 서비스가 접근할 pod의 포트
      protocol: TCP
EOF
```

```bash
cat <<EOF> ingress.yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: "travelbuddy-ingress"
    namespace: default
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/group.name: eks-demo-group
      alb.ingress.kubernetes.io/group.order: '1'
spec:
    rules:
    - http:
        paths:
          - path: /contents
            pathType: Prefix
            backend:
              service:
                name: "travelbuddy-service"
                port:
                  number: 80
EOF
```

---

배포 리포지터리는 아직 초기화가 되지 않은 상태이므로 위에서 생성한 ```~/environment/m2m-travelbuddy/application/TravelBuddy/deploy``` 폴더를 아래와 같이 연결하여 배포 파이프라인을 시작한다.<br>
![배포 리포지터리지 초기화되지 않음](./assets/travelbuddy-deploy-repository-not-initialized.png)

1. 배포 리포지터리 URL 확인
![배포 리포지터리 URL 확인](./assets/travelbuddy-deploy-repository-url.png)

2. 위에서 확인 URL을 해당 디렉토리에 연결
```bash
cd ~/environment/m2m-travelbuddy/applications/TravelBuddy/deploy
git init
git branch -M main

# 아래에 위 1에서 확인 URL로 대체할 것.
# (예시) git remote add origin https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/M2M-BuildAndDeliveryStack-DeployStack-DeploySourceRepository
git remote add origin <위 1에서 확인한 CodeCommit Git URL>

git add .
git commit -am "First commit."
git push --set-upstream origin main
```

### manifest로 배포하기

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

다음 명령어 수행 결과를 웹 브라우저에 붙여넣어 확인합니다.

```bash
echo http://$(kubectl get ingress/travelbuddy-ingress -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
```

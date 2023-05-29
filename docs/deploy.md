# TravelBuddy 애플리케이션을 EKS에 배포

## Agenda

- Bastion 호스트에 접속해서 TravelBuddy 애플리케이션 실행해보기
  - Docker 설치
  - TravelBuddy 컨테이너 실행
- EKS 배포
  - manifest 준비하기
  - manifest로 TravelBuddy 배포하기

## Bastion 호스트에 접속해서 TravelBuddy 애플리케이션 실행해보기

EC2 > Instances로 이동하여, bastion 호스트를 선택한 후 Connect 버튼을 클릭하여 SSH client 접속 명령어를 복사합니다.
![ssh.png](./assets/ssh.png)

Cloud9 터미널 창에서 아래 예시와 같이 복사한 명령어를 입력하여 bastion 호스트에 접속합니다.

```bash
ssh -i "m2m-bastion.pem" ec2-user@ec2-43-207-144-210.ap-northeast-1.compute.amazonaws.com
```

### Docker 설치

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

# 만일 docker를 실행했을 때 권한 오류가 발생하면 인스턴스를 재부팅해봅니다.
```

참고: [Amazon Linux 2에 Docker 설치](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/create-container-image.html#create-container-image-install-docker)

### TravelBuddy 컨테이너 실행

#### STEP 1. Docker Login

AWS 콘솔에서 ECR로 이동합니다. Repositories 메뉴에서 `travelbuddy`를 클릭한 후 `View push commands` 버튼을 클릭하여 표시되는 가이드의 1번 명령어를 복사합니다.

다시 bastion 호스트의 SSH shell로 돌아와서 위에서 복사한 명령어를 이용하여 docker login을 실행합니다.

#### STEP 2. 환경 변수 설정

```bash
# CF로 배포한 환경의 RDS 주소
export RDS_ENDPOINT=<RDS_ENDPOINT>
```

#### STEP 3. travelbuddy 컨테이너 실행

```bash
# env.yaml 파일의 내용을 확인하여 환경변수를 주입하여 컨테이너 실행
docker run --rm \
  -e JDBC_CONNECTION_STRING="jdbc:mysql://${RDS_ENDPOINT}:3306/travelbuddy?useSSL=false" \
  -e JDBC_UID=root \
  -e JDBC_PWD=labpassword \
  -dp 8080:8080 <YOUR_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/travelbuddy:latest

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
```

## EKS 배포

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

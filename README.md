# Application Modernization

## 변경 사항<br>
***[2023-06-03]***
1. RDS CloudFormation 템플릿 포함 (Include)
2. FlightSpecial 마이크로서비스를 위한 빌드 파이프라인 추가
   1. ECR 컨테이너 리포지터리
   2. CodeCommit, CodeBuild, CodePipeline
3. FlightSpecial 마이크로서비스를 위한 GitOps 배포 CodeCommit 리포지터리
4. FlightSpecial Polyglot 데이터베이스를 위한 PostgreSQL 자원 생성 CDK Stack 추가


## Agenda

- Sample Application 소개
- Monolith - TravelBuddy 마이그레이션
  - 이론: Monolith란?
  - 실습 환경 구성
  - 실습 1: TravelBuddy 애플리케이션 컨테이너화
  - 실습 2: Database 구성
  - 실습 3: TravelBuddy 애플리케이션을 EKS에 배포
- Microservice - HotelSpecial 애플리케이션
  - 이론: Microservice란?
  - 실습 B: Strangler Fig Pattern - FlightSpecial 애플리케이션을 분리

## "TravleBuddy" 소개
"TravelBuddy"는 관광 및 여행 전문 서비스 회사로서 동명의 "TravelBuddy"라는 애플리케이션을 통해 다양한 관광, 여행, 숙박 관련 서비스를 제공하고 있습니다.<br>

이 회사가 운영하는 "TravelBuddy" 애플리케이션은 사용자 친화적인 기능과 인터페이스를 통해 많은 고객을 유치함으로써 회사의 성장에 크게 기여하였습니다.<br>
하지만 고객이 늘어나고 회사가 성장함에 따라 시스템에 발생하는 장애도 함께 증가하고 있으며, 유연하지 못한 시스템 구조로 인한 신규 서비스 출시 지연은 브지니스 민첩성마저 저하시키고 있습니다.<br>

이 실습에서는 애플리케이션 현대화의 첫 번째 단계로서 기존 온프레미스 (On-Premise)에서 운영하던 가상의 웹 애플리케이션을 AWS 클라우드 환경으로 옮겨서 배포하고자 합니다.<br>
현행 어플리케이션은 Java Spring Boot 기반으로 구현되어 있으며, 고객은 우선 컨테이너를 통한 Replatfom을 통하여 클라우드에서 기능이 잘 동작하는지 확인함으로써 클라우드 이전의 위험성을 줄이고 싶어 합니다.<br>
그리고 이후 점진적으로 애플리케이션 현대화를 수행해 나갈 예정입니다.

## TravelBuddy 마이그레이션
이번 실습을 진행하면서 우리는 [TravelBuddy.zip](https://workshops.devax.academy/monoliths-to-microservices/module1/files/TravelBuddy.zip)라는 가상의 웹 애플리케이션을 활용하여 마이크로서비스 아키텍처로 전환하는 예제로 사용할 것입니다.

![travelbuddy.png](./docs/assets/travelbuddy.png)

이 실습을 통해 다음의 Topic을 다룰 것입니다.
- AWS 환경에서 개발 및 배포 등의 작업을 수행하기 위해서 Cloud9을 사용
- 1단계: 리플랫폼 (Replatform)
  - EKS 클러스터를 생성. 이 때 빌드/전달 (Build/Delivery) 파이프라인 및 배포 (Deploy) 파이프라인도 함께 생성
  - 위 두 파이프라인을 분리함으로써 Push 기반의 GitOps 체계 도입
    - (참고) [데브옵스의 확장 모델](https://www.samsungsds.com/kr/insights/gitops.html)
  - Monolith인 TravelBuddy 애플리케이션을 컨테이너화하고 컨테이너 이미지를 ECR에 푸시
- 2단계: 리팩터 (Refactor Piloting)
  - Monolith 개념을 이해하고 TravelBuddy 애플리케이션을 분석하여 개선 방향을 검토
  - Microservice 개념을 이해하고 HotelSpecial 애플리케이션을 통해 분리하는 과정을 체험
  - (옵션) Pull 기반의 GitOps 구조를 구축 (ArgoCD)
  - FlightSpecial 애플리케이션을 직접 개발하면서 학습 내용을 복습

또한 필요하다면 다음과 같은 주제를 함께 토론해 보면 좋을 것 같습니다.<br>
- 도메인 주도 설계 (Domain-Driven Design)
- Layered Architecture 및 SOLID 원칙
- IRSA (IAM Role for Service Account)

### 실습 환경 구성
- 먼저 [Cloud9 환경 구성하기](./docs/cloud9-latest.md)를 합니다.
- 다음으로 [EKS Cluster를 생성 (CDK 사용)](./docs/eks-cluster-cdk.md)합니다.

### 실습 1: TravelBuddy 애플리케이션 컨테이너화, 빌드 및 전달 (ECR 푸시)

- 아래 가이드를 바탕으로 컨테이너 이미지를 생성합니다.
  - [TravelBuddy 컨테이너화, 빌드 및 전달 (자원이 CDK로 생성된 경우)](./docs/containerize.md) 
  - [TravelBuddy 컨테이너화, 빌드 및 전달 (자원이 Terraform으로 생성된 경우)](./docs/containerize-terraform.md) 

### 실습 2: Database 구성

- 클라우드 환경에 데이터베이슬 구성합니다.
  - [데이터베이스 구성 (자원이 CDK로 생성된 경우)](./docs/database.md)
  - [데이터베이스 구성 (자원이 Terraform으로 생성된 경우)](./docs/database-terraform.md)

### 실습 3: TravelBuddy 애플리케이션을 EKS에 배포

- 컨테이너화 한 TravelBuddy 애플리케이션을 쿠버네테스 환경에 배포합니다.
  -  [EKS에 배포 (CDK로 자원을 생성한 경우)](./docs/deploy.md)
  -  [EKS에 배포 (Terraform으로 자원을 생성한 경우)](./docs/deploy-terraform.md)

## Monolith란?

[Monolith](./docs/monolith.md)의 개념을 간단히 살펴보고 몇 가지 개선 방법을 알아봅니다.

## Microservice란?

[Microservice](./docs/microservices.md)의 개념을 간단히 살펴보고, 어떤 경우에 마이크로서비스가 필요한지 토론해봅니다.

## 실습 4: FlightSpecial Microservice 애플리케이션

- Layered Architecture를 반영한 [Package 구조](./docs/package.md)를 살펴봅니다.
- Docker Compose를 활용하여 Sandbox 환경을 구성하는 방법을 알아봅니다.
- AWS DMS를 통하여 마이크로서비스에서 발생하는 데이터 변경 사항을 레거시 모놀리스 어플리케이션으로 동기화합니다.

## (Optional) 실습 5 (Self-Paced Project): HotelSpecial 애플리케이션을 분리
- FlightSpecial 프로젝트를 참고하여 직접 HotelSpecial 애플리케이션을 제작합니다.
- 이 과정을 통해서 앞에서 학습한 세부 기술들을 익히고 내재화합니다.

## (Optional) 실습 6: FlightSpecial 마이크로서비스 이벤기 기반 아키텍처
Apache Kafka에 FlightSpecial 마이크로서비스의 도메인 이벤트를 Publish해 봅니다. 이 과정에서 IRSA를 Kubernetes Pod에 적용하는 과정도 실무적으로 살펴보도록 합니다.

## 추후 연계 세션: Migration Hub 서비스의 Refactor Space를 활용한 Strangler-Fig Application 체험
- 프론트엔드의 분리와 연계

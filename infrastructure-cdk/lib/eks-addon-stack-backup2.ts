import {aws_eks, aws_iam, Fn, NestedStack, Stack, StackProps, aws_acmpca, aws_certificatemanager} from "aws-cdk-lib";
import {Construct} from "constructs";
import {AlbController} from "aws-cdk-lib/aws-eks";
import {HelmCharts, HelmRepositories} from "../config/helm";
import * as iam from "aws-cdk-lib/aws-iam";
import {InfrastructureEnvironment} from "../bin/infrastructure-environment";

export class EksAddonStack extends Stack {
    constructor(
        scope: Construct,
        id: string,
        clusterName: string,
        // cluster: aws_eks.Cluster,
        // albController: AlbController,
        infrastructureEnvironment: InfrastructureEnvironment,
        props?: StackProps
    ) {
        super(scope, id, props);

        const kubectlRole = aws_iam.Role.fromRoleName(
            this,
            `${clusterName}-${props?.env?.region}-MasterRole`,
            `${clusterName}-${props?.env?.region}-MasterRole`,
            {}
        );

        /*
         * Import from the parent EKS stack output.
         * eg. "arn:aws:iam::252918835262:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/F8641B15A61FF14C64EFAB571287B49D"
         */
        const openIdConnectProviderArn = Fn.importValue(`${clusterName}-OpenIdConnectProviderArn`);
        const openIdConnectProvider = aws_iam.OpenIdConnectProvider.fromOpenIdConnectProviderArn(
            this,
            `${clusterName}-OpenIdConnectProvider`,
            openIdConnectProviderArn
        );

        const cluster = aws_eks.Cluster.fromClusterAttributes(
            this,
            `${clusterName}`,
            {
                clusterName: clusterName,
                kubectlRoleArn: kubectlRole.roleArn,
                openIdConnectProvider: openIdConnectProvider
            }
        );

        const privateCertificate = new aws_certificatemanager.PrivateCertificate(
            this,
            `${clusterName}-Private-Certificate`,
            {
                domainName: 'www.mydemo.co.kr',
                subjectAlternativeNames: ['cool.mydemo.co.kr', 'test.mydemo.co.kr'], // optional
                certificateAuthority: aws_acmpca.CertificateAuthority.fromCertificateAuthorityArn(
                    this,
                    `${clusterName}-CA`,
                    infrastructureEnvironment.privateCertificateAuthorityArn ?? ""
                )
            }
        );

        /*
         * Install helm chart for cert-manager.
         * https://cert-manager.io/docs/release-notes/release-notes-1.12/
         */
        cluster.addHelmChart(
            `${clusterName}-CertManagerChart`,
            {
                repository: HelmRepositories.JETSTACK,
                chart: HelmCharts.CERT_MANAGER,
                release: "cert-manager",
                namespace: "cert-manager",
                createNamespace: true,
                version: "v1.12.1",
                values: {
                    installCRDs: true
                }
            }
        );

        /*
         * Install ArgoCD with helm.
         * Command to change Service Type: ClusterIP -> LoadBalancer
         * kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
         *
         * References:
         * - https://artifacthub.io/packages/helm/argo/argo-cd
         * - https://argo-cd.readthedocs.io/en/stable/getting_started/
         * - https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/
         * - https://github.com/argoproj/argo-helm/blob/438f7a26b7518ec1fc4133f12f58cb0b8d1a2765/charts/argo-cd/templates/argocd-server/service.yaml#L18
         * - https://devocean.sk.com/blog/techBoardDetail.do?ID=163103
         *
         * Read this!
         * - https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/
         */
        cluster.addHelmChart(
            `${clusterName}-ArgoCd`,
            {
                repository: "https://argoproj.github.io/argo-helm",
                chart: "argo-cd",
                release: "argocd",
                namespace: "argocd",
                createNamespace: true,
                // version: "v2.7.3",
                values: {
                    server: {
                        ingress: {
                            enabled: true,
                            annotations: {
                                // Ingress core settings.
                                "kubernetes.io/ingress.class": "alb",
                                "alb.ingress.kubernetes.io/scheme": "internet-facing",
                                "alb.ingress.kubernetes.io/target-type": "ip",
                                "alb.ingress.kubernetes.io/target-group-attributes": "stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=60",
                                // Ingress group settings.
                                // "alb.ingress.kubernetes.io/group.name": "argocd-server",
                                "alb.ingress.kubernetes.io/group.name": "argo",
                                "alb.ingress.kubernetes.io/group.order": "1",
                                // Needed when using TLS.
                                "alb.ingress.kubernetes.io/backend-protocol": "HTTPS",
                                "alb.ingress.kubernetes.io/healthcheck-protocol": "HTTPS",
                                // "alb.ingress.kubernetes.io/listen-ports": '[{"HTTP":80}, {"HTTPS":443}]'
                                "alb.ingress.kubernetes.io/listen-ports": '[{"HTTPS":443}]',
                                "alb.ingress.kubernetes.io/certificate-arn": privateCertificate.certificateArn
                            },
                            paths: ["/"],
                            https: true
                        }
                    }
                }
            }
        );

        /*
         * Install Argo Rollout with helm.
         * References:
         * - https://artifacthub.io/packages/helm/argo/argo-rollouts
         * - https://argo-rollouts.readthedocs.io/en/latest/installation/
         * - https://argo-rollouts.readthedocs.io/en/release-1.5/FAQ/
         */
        cluster.addHelmChart(
            `${clusterName}-ArgoRollout`,
            {
                repository: "https://argoproj.github.io/argo-helm",
                chart: "argo-rollouts",
                release: "argo-rollouts",
                namespace: "argo-rollouts",
                createNamespace: true,
                values: {
                    installCRDs: true,
                    dashboard: {
                        enabled: true,
                        ingress: {
                            enabled: true,
                            annotations: {
                                // Ingress core settings.
                                "kubernetes.io/ingress.class": "alb",
                                "alb.ingress.kubernetes.io/scheme": "internet-facing",
                                "alb.ingress.kubernetes.io/target-type": "ip",
                                "alb.ingress.kubernetes.io/target-group-attributes": "stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=60",
                                "alb.ingress.kubernetes.io/success-codes": "200,404,301,302",
                                // Ingress gorup setting.
                                // "alb.ingress.kubernetes.io/group.name": "argo-rollouts-dashboard",
                                "alb.ingress.kubernetes.io/group.name": "argo",
                                "alb.ingress.kubernetes.io/group.order": "2",
                                paths: ["/rollouts"]
                            }
                        }
                    },
                }
            }
        );

        /*
         * Install Kubernetes metrics server.
         * - https://artifacthub.io/packages/helm/metrics-server/metrics-server
         */
        const metricsServerHelmChart = cluster.addHelmChart(
            `${clusterName}-Metrics-Server`,
            {
                repository: "https://kubernetes-sigs.github.io/metrics-server",
                chart: "metrics-server",
                release: "metrics-server",
                namespace: "kube-system",
                createNamespace: false
            }
        );

        /*
         * Install Kubernetes Dashboard with Helm.
         * - https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard
         *
         * How to connect
         * - https://archive.eksworkshop.com/beginner/040_dashboard/
         * - https://github.com/kubernetes/dashboard/blob/master/charts/helm-chart/kubernetes-dashboard/templates/networking/ingress.yaml
         *
         * (참고)
         * 위의 Ingress Yaml 파일을 보면 Nginx만 Ingress 자원으로 정의하고 있음 -> AWS ALB 미지원!
         * (필독) https://github.com/kubernetes/dashboard/blob/master/docs/common/arguments.md
         *
         * (참고) Kubernetes Dashboard는 다음 경우에만 원격 로그인을 허용 (https://github.com/kubernetes/dashboard/blob/master/docs/user/accessing-dashboard/README.md#login-not-available)
         * - http://localhost/...
         * - http://127.0.0.1/...
         * - https://<domain_name>/...
         *
         * * 설정 후 로그인 방법: https://archive.eksworkshop.com/beginner/040_dashboard/connect/
         * 1. Kubeconfig가 설정된, 혹은 EKS에 접속 가능한 AWS Principal이 설정된 환경에서
         * 2. aws eks get-token --cluster-name M2M-EksCluster --role arn:aws:iam::805178225346:role/M2M-EksCluster-ap-northeast-2-MasterRole | jq -r '.status.token'
         * 3. 위 2의 결과를 로그인 창에 복사 후 로그인
         *
         */
        const kubernetesDashboardHelmChart = cluster.addHelmChart(
            `${clusterName}-Kubernetes-Dashboard`,
            {
                repository: "https://kubernetes.github.io/dashboard/",
                chart: "kubernetes-dashboard",
                version: "v6.0.8",
                release: "kubernetes-dashboard",
                namespace: "kubernetes-dashboard",
                createNamespace: true,
                values: {
                    // This will pass "--auto-generate-certificates=false" argument.
                    protocolHttp: true,
                    service: {
                        externalPort: 9090
                    },
                    extraArgs: [
                        "--insecure-bind-address=0.0.0.0",
                        "--enable-insecure-login",
                        "--enable-skip-login=false",
                        "--system-banner=\"!!! Welcome to AWS ProServe Kubernetes !!!\""
                    ],
                    ingress: {
                        // Maybe in the next version.
                        // nginx: {
                        enabled: true,
                        annotations: {
                            // Ingress core settings.
                            "kubernetes.io/ingress.class": "alb",
                            "alb.ingress.kubernetes.io/scheme": "internet-facing",
                            "alb.ingress.kubernetes.io/target-type": "ip",
                            "alb.ingress.kubernetes.io/target-group-attributes": "stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=60",
                            // Ingress group settings.
                            "alb.ingress.kubernetes.io/group.name": "kubernetes-dashboard",
                            "alb.ingress.kubernetes.io/group.order": "1",
                            // Needed to listen on TLS.
                            "alb.ingress.kubernetes.io/listen-ports": '[{"HTTPS":443}]',
                            "alb.ingress.kubernetes.io/certificate-arn": privateCertificate.certificateArn
                        },
                        // hosts: ["*"],
                        // paths: ["/"],
                        customPaths: [
                            {
                                path: "/",
                                pathType: "Prefix",
                                backend: {
                                    service: {
                                        name: "kubernetes-dashboard",
                                        port: {
                                            number: 9090
                                        }
                                    }
                                }
                            },
                        ]
                    },
                }
            }
        );

        /*
         * Install Istio with Helm.
         * - https://istio-release.storage.googleapis.com/charts
         * - https://istio.io/latest/docs/setup/install/helm/
         * - https://artifacthub.io/packages/helm/istio-official/istiod
         * - https://github.com/aws-quickstart/cdk-eks-blueprints/blob/main/docs/addons/istio-control-plane.md
         */
        // const istioSystemNamespace = cluster.addManifest(
        //     `${clusterName}-Istio-System-Namespace`,
        //     {
        //         apiVersion: 'v1',
        //         kind: 'Namespace',
        //         metadata: {
        //             name: 'istio-system',
        //         }
        //     }
        // );
        const istioBase = cluster.addHelmChart(
            `${clusterName}-Istio-Base`,
            {
                repository: "https://istio-release.storage.googleapis.com/charts",
                chart: "base",
                release: "istio-base",
                namespace: "istio-system",
                createNamespace: true
            }
        );
        // istioBase.node.addDependency(istioSystemNamespace);

        const istioD = cluster.addHelmChart(
            `${clusterName}-Istio-Istiod`,
            {
                repository: "https://istio-release.storage.googleapis.com/charts",
                chart: "istiod",
                release: "istiod",
                namespace: "istio-system",
                createNamespace: false,
                // version: "1.18.0"
            }
        );

        // // Istio gateway namespace.
        // const istioGatewayNamespace = cluster.addManifest(
        //     `${clusterName}-Istio-Gateway-Namespace`,
        //     {
        //         apiVersion: 'v1',
        //         kind: 'Namespace',
        //         metadata: {
        //             name: 'istio-ingress',
        //             labels: {
        //                 // This is needed to prevent "Response object is too long" error due to some error when deploying the istiod pod.
        //                 // , typically caused by ALB controller not installed in advance.
        //                 "istio-injection": "enabled"
        //             }
        //         }
        //     }
        // );

        // https://github.com/istio/istio/blob/master/manifests/charts/gateway/templates/deployment.yaml
        // https://github.com/istio/istio/blob/master/manifests/charts/gateway/README.md
        // https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy
        const istioGateway = cluster.addHelmChart(
            `${clusterName}-Istio-Gateway`,
            {
                repository: "https://istio-release.storage.googleapis.com/charts",
                chart: "gateway",
                release: "istio-ingressgateway",
                namespace: "istio-system",
                createNamespace: false
            }
        );

        istioD.node.addDependency(istioBase);
        // istioD.node.addDependency(albController);
        istioGateway.node.addDependency(istioD);


        // istioGateway.node.addDependency(albController);
        // istioGateway.node.addDependency(istioGatewayNamespace);

        /*
         * EBS CSI Driver for Prometheus.
         * - https://medium.com/gamgyul-tech/container-volumebinding-error-f5fb09431951
         * - https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md
         */
        // const ebsCsiDriverSaRole = new aws_iam.Role(
        //     this,
        //     `${clusterName}-EBS-CSI-Driver-SA-Role`,
        //     {
        //         roleName: "ebs-csi-controller-sa",
        //         assumedBy: new aws_iam.ServicePrincipal('ec2.amazonaws.com')
        //     }
        // );
        // m2mAdminRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AdministratorAccess"));

        const ebsCsiControllerSaOwned = cluster.addServiceAccount(
            `${clusterName}-EBS-CSI-Driver-ServiceAccount`,
            {
                // Default: ebs-csi-controller-sa (see: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml)
                name: 'ebs-csi-controller-sa-owned',
                namespace: 'kube-system'
            }
        );
        // https://github.com/aws/aws-cdk/issues/9898
        ebsCsiControllerSaOwned.role.addManagedPolicy(
            aws_iam.ManagedPolicy.fromAwsManagedPolicyName("service-role/AmazonEBSCSIDriverPolicy")
        );

        const ebsCsiDriverHelmChart = cluster.addHelmChart(
            `${clusterName}-EBS-CSI-Driver`,
            {
                repository: "https://kubernetes-sigs.github.io/aws-ebs-csi-driver",
                chart: "aws-ebs-csi-driver",
                release: "aws-ebs-csi-driver",
                namespace: "kube-system",
                createNamespace: false,
                values: {
                    controller: {
                        serviceAccount: {
                            create: false,
                            name: ebsCsiControllerSaOwned.serviceAccountName
                        },
                    },
                    node: {
                        tolerateAllTaints: true
                    },
                    storageClasses: [{
                        name: "gp3",
                        annotations: {
                            "storageclass.kubernetes.io/is-default-class": "true"
                        },
                        volumeBindingMode: "WaitForFirstConsumer",
                        reclaimPolicy: "Delete",
                        allowVolumeExpansion: true,
                        parameters: {
                            type: "gp3",
                            "csi.storage.k8s.io/fstype": "ext4"
                        }
                    }]
                }
            }
        );
        ebsCsiDriverHelmChart.node.addDependency(ebsCsiControllerSaOwned);

        /*
         * Install Prometheus.
         * - https://artifacthub.io/packages/helm/prometheus-community/prometheus
         */
        const prometheus = cluster.addHelmChart(
            `${clusterName}-Prometheus`,
            {
                repository: "https://prometheus-community.github.io/helm-charts",
                chart: "prometheus",
                release: "prometheus",
                namespace: "prometheus",
                createNamespace: true,
                values: {
                    ingress: {
                        enabled: true
                    }
                }
            }
        );
        // prometheus.node.addDependency(albController);
        prometheus.node.addDependency(metricsServerHelmChart);
        prometheus.node.addDependency(ebsCsiDriverHelmChart);

        /*
         * Install Kiali.
         * - https://kiali.io/docs/installation/installation-guide/install-with-helm/
         * - https://kiali.io/docs/installation/installation-guide/accessing-kiali/
         * - https://artifacthub.io/packages/olm/community-operators/kiali
         *
         * Kiali 접근
         * - https://pre-v1-41.kiali.io/documentation/v1.24/installation-guide/#_helm_chart
         * - https://pre-v1-41.kiali.io/documentation/v1.24/faq/#how-do-i-access-kiai
         * - https://github.com/kiali/kiali-operator/blob/master/roles/default/kiali-deploy/templates/kubernetes/ingress.yaml
         * - https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
         * - https://github.com/seanlee10/container-expert-workshop/tree/main/02_kubernetes/11_istio
         *
         * Kiali Operator의 단점:
         * - Kiali 등 다른 자원의 수명주기를 관리해 준다고 하나, CDK 스택이 지워질 때 함께 삭제되지는 않음
         * - 추후 재생성 시 Conflict을 막기 위해서 수동으로 삭제해 주어야 함.
         * - Kiali를 단독으로 설치하는 것을 고려할 것.
         */
        const kialiOperator = cluster.addHelmChart(
            `${clusterName}-Kiali`,
            {
                repository: "https://kiali.org/helm-charts",
                chart: "kiali-operator",
                release: "kiali-operator",
                namespace: "kiali-operator",
                // namespace: "istio-system",
                createNamespace: true,
                values: {
                    // Kiali Operator will deploy Kiali server if below is specified.
                    cr: {
                        create: true,
                        namespace: "istio-system",
                        // See: https://kiali.io/docs/installation/installation-guide/advanced-install-options/
                        spec: {
                            deployment: {
                                replicas: 2,
                                // Why the hell doesn't below take effect?
                                // Just create ingress on my own.
                                // See: https://github.com/kiali/kiali-operator.git/crd-docs/cr/kiali.io_v1alpha1_kiali.yaml
                                ingress: {
                                    enabled: true,
                                    // Suppress default "nginx"
                                    class_name: "",
                                    override_yaml: {
                                        metadata: {
                                            annotations: {
                                                "kubernetes.io/ingress.class": "alb",
                                                "alb.ingress.kubernetes.io/scheme": "internet-facing",
                                                "alb.ingress.kubernetes.io/target-type": "ip",
                                                "alb.ingress.kubernetes.io/group.name": "kaili",
                                                "alb.ingress.kubernetes.io/group.order": "1"
                                            }
                                        },
                                        spec: {
                                            rules: [
                                                {
                                                    http: {
                                                        paths: [
                                                            {
                                                                path: "/kiali",
                                                                pathType: "Prefix",
                                                                backend: {
                                                                    serviceName: "kiali",
                                                                    servicePort: 20001
                                                                }
                                                            }
                                                        ]
                                                    }
                                                }
                                            ]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        );
        kialiOperator.node.addDependency(istioBase);
        kialiOperator.node.addDependency(prometheus);

        // const kialiIngress = cluster.addManifest(
        //     `${clusterName}-Kiali-Ingress`,
        //     {
        //         apiVersion: "networking.k8s.io/v1",
        //         kind: "Ingress",
        //         metadata: {
        //             name: "kiali-ingress",
        //             // Just set for a while.
        //             namespace: "istio-system",
        //             labels: {
        //                 "app.kubernetes.io/part-of": "kiali",
        //             },
        //             annotations: {
        //                 "kubernetes.io/ingress.class": "alb",
        //                 "alb.ingress.kubernetes.io/scheme": "internet-facing",
        //                 "alb.ingress.kubernetes.io/target-type": "ip",
        //                 "alb.ingress.kubernetes.io/target-group-attributes": "stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=60",
        //                 "alb.ingress.kubernetes.io/success-codes": "200,404,301,302",
        //                 "alb.ingress.kubernetes.io/group.name": "kiali",
        //                 "alb.ingress.kubernetes.io/group.order": "1"
        //             }
        //         },
        //         spec: {
        //             rules: [
        //                 {
        //                     http: {
        //                         paths: [
        //                             {
        //                                 path: "/kiali",
        //                                 pathType: "Prefix",
        //                                 backend: {
        //                                     service: {
        //                                         name: "kiali",
        //                                         port: {
        //                                             number: 20001
        //                                         }
        //                                     }
        //                                 }
        //                             }
        //                         ]
        //                     }
        //                 }
        //             ]
        //         }
        //     }
        // );
        // kialiIngress.node.addDependency(kialiOperator);
    }
}

import {aws_eks, aws_iam, Fn, NestedStack, Stack, StackProps, aws_acmpca, aws_certificatemanager} from "aws-cdk-lib";
import {Construct} from "constructs";
import {AlbController} from "aws-cdk-lib/aws-eks";
import {HelmCharts, HelmRepositories} from "../config/helm";
import * as iam from "aws-cdk-lib/aws-iam";

export class EksAddonStack extends Stack {
    constructor(
        scope: Construct,
        id: string,
        clusterName: string,
        // cluster: aws_eks.Cluster,
        // albController: AlbController,
        props: StackProps
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

        /*
         * Create a private certificate for various ALB using HTTPS.
         * (주의) 자원 생성 후 Enable해 주어야 한다.
         * 1. CDK 배포 -> Private CA에서 오류 발생함 (CA가 Activation되지 않았으므로).
         * 2. AWS ACM 콘솔에서 해당 Private CA -> 인증서 설치
         * 3. 설치된 인증서를 복사하여 아래 cfnCertificateAuthorityActivation 변수의 certificate 값을 수정.
         * 4. CDK 재배포
         */
        // const cfnCertificateAuthority = new aws_acmpca.CfnCertificateAuthority(
        //     this,
        //     `${clusterName}-Cfn-CA`,
        //     {
        //         type: 'ROOT',
        //         keyAlgorithm: 'RSA_2048',
        //         signingAlgorithm: 'SHA256WITHRSA',
        //         subject: {
        //             country: 'KR',
        //             organization: 'My Demo Organization',
        //             organizationalUnit: 'My Demo Team',
        //             distinguishedNameQualifier: 'mydemo.co.kr',
        //             state: 'Seoul',
        //             commonName: 'mydemo.co.kr',
        //             // serialNumber: 'string',
        //             locality: 'Gangnam-gu',
        //             // title: 'string',
        //             // surname: 'string',
        //             // givenName: 'string',
        //             // initials: 'DG',
        //             // pseudonym: 'string',
        //             // generationQualifier: 'DBG',
        //         },
        //     }
        // );

        // const cfnCertificateAuthorityActivation = new aws_acmpca.CfnCertificateAuthorityActivation(
        //     this,
        //     `${clusterName}-Cfn-CA-Activation`,
        //     {
        //         certificate: "-----BEGIN CERTIFICATE-----\n" +
        //             "MIID+jCCAuKgAwIBAgIQdVW+tvjdsQgSy5v9UdBo7DANBgkqhkiG9w0BAQsFADCB\n" +
        //             "ljELMAkGA1UEBhMCS1IxHTAbBgNVBAoMFE15IERlbW8gT3JnYW5pemF0aW9uMRUw\n" +
        //             "EwYDVQQLDAxNeSBEZW1vIFRlYW0xFTATBgNVBC4TDG15ZGVtby5jby5rcjEOMAwG\n" +
        //             "A1UECAwFU2VvdWwxFTATBgNVBAMMDG15ZGVtby5jby5rcjETMBEGA1UEBwwKR2Fu\n" +
        //             "Z25hbS1ndTAeFw0yMzA3MDcwNjI0MDNaFw0zMzA3MDcwNzIzNTZaMIGWMQswCQYD\n" +
        //             "VQQGEwJLUjEdMBsGA1UECgwUTXkgRGVtbyBPcmdhbml6YXRpb24xFTATBgNVBAsM\n" +
        //             "DE15IERlbW8gVGVhbTEVMBMGA1UELhMMbXlkZW1vLmNvLmtyMQ4wDAYDVQQIDAVT\n" +
        //             "ZW91bDEVMBMGA1UEAwwMbXlkZW1vLmNvLmtyMRMwEQYDVQQHDApHYW5nbmFtLWd1\n" +
        //             "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAi+qqplXHzmBVDwl/F9Sl\n" +
        //             "BpuXslBx8HZ5enWgNr9VDYMufLeu9Vlvb1RF63Z2BJSK6pTk3y9yevBOogHpghoE\n" +
        //             "ufO99qsofcnsErDQUZs504QzjKRon2XIEMXjavD2RYViTk9+zDPWeSi5nA32yZSy\n" +
        //             "1kj2mJUNVHRBxv86hsfydYgE4tA5mCuV3Is5ZFwN+RsAQyueIeCg9zSvzViTzrHu\n" +
        //             "yyVTtxY76zkyaFlx660fs5TxfBfeR41P1sTMLyxqOanKYhIuG85CiRB6zay/O9Bn\n" +
        //             "90NnZVsI3ikOdTniOkcha6yJyzlGj9Ueycgak7FsFzJNmDPGKrK9BJmiqSQiE1CD\n" +
        //             "1wIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSqxicHDavlxla+\n" +
        //             "s5z5rjYnx6Bj9jAOBgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQELBQADggEBABC7\n" +
        //             "hcl6kpMKGrdYwN+BqacBfMzf67CCnsPr4XTv6T8vbD7wRlNnprTAon5D9F/3IDqp\n" +
        //             "zO4JB/lzR/SnDY5ODCbH9zr7lD8nLJZmlPQtlBPyZ36d6VMB+CoEr0131/E61Kdc\n" +
        //             "OdEAMXyFxNKDIreY7mhfwhAdiF8EihLdsMeUnYlZvY1EjWO4ksIqh1wIj7v3O09E\n" +
        //             "Iq5s1hR2wzBqYS7QUUvUZ0ph1U9baG1AOvR2CnMRkoy8/skBvwS2NqHuxxjeimVN\n" +
        //             "cjsLGnujtZAkx5ByKldblAlMpvT1lb3kAhsJDwp2Sm+uRCjshG2KJUEg8/QU0p1I\n" +
        //             "vuWvLwuFmOSNXvQoD7M=\n" +
        //             "-----END CERTIFICATE-----",
        //         certificateAuthorityArn: cfnCertificateAuthority.attrArn
        //     }
        // );

        // const certificateAuthority = aws_acmpca.CertificateAuthority.fromCertificateAuthorityArn(
        //     this,
        //     `${clusterName}-CA`,
        //     cfnCertificateAuthority.attrArn
        // );

        const privateCertificate = new aws_certificatemanager.PrivateCertificate(
            this,
            `${clusterName}-Private-Certificate`,
            {
                domainName: 'www.mydemo.co.kr',
                subjectAlternativeNames: ['cool.mydemo.co.kr', 'test.mydemo.co.kr'], // optional
                certificateAuthority: aws_acmpca.CertificateAuthority.fromCertificateAuthorityArn(
                    this,
                    `${clusterName}-CA`,
                    // (중요) 자신의 CA 값으로 대체할 것
                    "arn:aws:acm-pca:ap-northeast-2:805178225346:certificate-authority/6dcddf84-a068-4fe1-8240-a376c7ae9765"
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
                    // installCRDs: true,
                    // To be compliant with JSON notation, we need to write as follows to apply 'server.service.type': 'LoadBalancer'.
                    // server: {
                    //     service: {
                    //         type: "LoadBalancer"
                    //     }
                    // }

                    // configs: {
                    //     params: {
                    //         server: {
                    //             insecure: true
                    //         }
                    //     }
                    // },
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
                                "alb.ingress.kubernetes.io/group.name": "argocd-server",
                                "alb.ingress.kubernetes.io/group.order": "1",
                                // Needed when using TLS.
                                // "alb.ingress.kubernetes.io/backend-protocol": "HTTPS",
                                "alb.ingress.kubernetes.io/healthcheck-protocol": "HTTPS",
                                // "alb.ingress.kubernetes.io/listen-ports": '[{"HTTP":80}, {"HTTPS":443}]'
                                "alb.ingress.kubernetes.io/listen-ports": '[{"HTTPS":443}]',
                                "alb.ingress.kubernetes.io/certificate-arn": privateCertificate.certificateArn
                            },
                            // hosts: [
                            //     "*"
                            // ],
                            // paths: [
                            //     {
                            //         path: "/",
                            //         pathType: "Prefix"
                            //     }
                            // ]
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
                        service: {
                            type: "LoadBalancer"
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
         */
        const kubernetesDashboardHelmChart = cluster.addHelmChart(
            `${clusterName}-Kubernetes-Dashboard`,
            {
                repository: "https://kubernetes.github.io/dashboard/",
                chart: "kubernetes-dashboard",
                release: "kubernetes-dashboard",
                namespace: "kubernetes-dashboard",
                createNamespace: true,
                values: {
                    ingress: {
                        // Will create ingress later below.
                        enabled: false
                    }
                }
            }
        );

        /*
         * Disabled for a while.
         * Uncomment and tune if you need it.
         */
        /*
        const dashboardAlbIngress = cluster.addManifest(
            `${clusterName}-Kubernetes-Dashboard-Ingress`,
            {
                apiVersion: "networking.k8s.io/v1",
                kind: "Ingress",
                metadata: {
                    name: "kubernetes-dashboard",
                    namespace: "kubernetes-dashboard",
                    labels: {
                        "app.kubernetes.io/part-of": "kubernetes-dashboard",
                    },
                    annotations: {
                        "kubernetes.io/ingress.class": "alb",
                        "alb.ingress.kubernetes.io/scheme": "internet-facing",
                        "alb.ingress.kubernetes.io/target-type": "ip",
                        "alb.ingress.kubernetes.io/group.name": "kubernetes-dashboard",
                        "alb.ingress.kubernetes.io/group.order": "1"
                    }
                },
                spec: {
                    rules: [
                        {
                            http: {
                                paths: [
                                    {
                                        path: "/",
                                        pathType: "Prefix",
                                        backend: {
                                            service: {
                                                name: "kubernetes-dashboard-web",
                                                port: {
                                                    name: "web"
                                                }
                                            }
                                        }
                                    },
                                    {
                                        path: "/api",
                                        pathType: "Prefix",
                                        backend: {
                                            service: {
                                                name: "kubernetes-dashboard-api",
                                                port: {
                                                    name: "api"
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    ]
                }
            }
        );
        dashboardAlbIngress.node.addDependency(kubernetesDashboardHelmChart);
        */

        /*
         * Install Istio with Helm.
         * - https://istio-release.storage.googleapis.com/charts
         * - https://istio.io/latest/docs/setup/install/helm/
         * - https://artifacthub.io/packages/helm/istio-official/istiod
         * - https://github.com/aws-quickstart/cdk-eks-blueprints/blob/main/docs/addons/istio-control-plane.md
         */
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
        const istioD = cluster.addHelmChart(
            `${clusterName}-Istio-Istiod`,
            {
                repository: "https://istio-release.storage.googleapis.com/charts",
                chart: "istiod",
                release: "istiod",
                namespace: "istio-system",
                createNamespace: true,
                // version: "1.18.0"
            }
        );

        // Istio gateway namespace.
        const istioGatewayNamespace = cluster.addManifest(
            `${clusterName}-Istio-Gateway-Namespace`,
            {
                apiVersion: 'v1',
                kind: 'Namespace',
                metadata: {
                    name: 'istio-ingress',
                    labels: {
                        // This is needed to prevent "Response object is too long" error due to some error when deploying the istiod pod.
                        // , typically caused by ALB controller not installed in advance.
                        "istio-injection": "enabled"
                    }
                }
            }
        );

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
         */
        const kiali = cluster.addHelmChart(
            `${clusterName}-Kiali`,
            {
                repository: "https://kiali.org/helm-charts",
                chart: "kiali-operator",
                release: "kiali-operator",
                // namespace: "kiali-operator",
                namespace: "istio-system",
                createNamespace: true,
                values: {
                    // cr: {
                    //     create: true,
                    //     namespace: "istio-system"
                    // },
                    kiali_vars: {
                        deployment: {
                            ingress: {
                                enabled: true,
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
        );
        kiali.node.addDependency(istioBase);
        kiali.node.addDependency(prometheus);

    }
}

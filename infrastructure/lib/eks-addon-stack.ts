import {aws_eks, aws_iam, NestedStack, Stack, StackProps} from "aws-cdk-lib";
import {Construct} from "constructs";
import {AlbController} from "aws-cdk-lib/aws-eks";

export class EksAddonStack extends NestedStack {
    constructor(
        scope: Construct,
        id: string,
        clusterName: string,
        cluster: aws_eks.Cluster,
        albController: AlbController,
        props: StackProps
    ) {
        super(scope, id, props);


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
         */
        cluster.addHelmChart(
            `${clusterName}-Kubernetes-Dashboard`,
            {
                repository: "https://kubernetes.github.io/dashboard/",
                chart: "kubernetes-dashboard",
                release: "kubernetes-dashboard",
                namespace: "kubernetes-dashboard",
                createNamespace: true,
                values: {
                    ingress: {
                        enabled: true
                    }
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

        const istioGateway = cluster.addHelmChart(
            `${clusterName}-Istio-Gateway`,
            {
                repository: "https://istio-release.storage.googleapis.com/charts",
                chart: "gateway",
                release: "istio-gateway",
                namespace: "istio-ingress",
                createNamespace: false
            }
        );

        istioD.node.addDependency(istioBase);
        istioD.node.addDependency(albController);
        istioGateway.node.addDependency(istioBase);
        istioGateway.node.addDependency(albController);
        istioGateway.node.addDependency(istioGatewayNamespace);

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
        ebsCsiControllerSaOwned.role.addManagedPolicy(
            aws_iam.ManagedPolicy.fromAwsManagedPolicyName("service-role/AmazonEBSCSIDriverPolicy")
        );

        const ebsCsiDriver = cluster.addHelmChart(
            `${clusterName}-EBS-CSI-Driver`,
            {
                repository: "https://kubernetes-sigs.github.io/aws-ebs-csi-driver",
                chart: "aws-ebs-csi-driver",
                release: "aws-ebs-csi-driver",
                namespace: "kube-system",
                createNamespace: false,
                values: {
                    serviceAccount: {
                        create: false,
                        name: ebsCsiControllerSaOwned.serviceAccountName
                    },
                    node: {
                        tolerateAllTaints: true
                    },
                    storageClasses: {
                        name: "gp3",
                        annotations: {
                            "storageclass.kubernetes.io/is-default-class": true
                        },
                        volumeBindingMode: "WaitForFirstConsumer",
                        reclaimPolicy: "Delete",
                        allowVolumeExpansion: true,
                        parameters: {
                            type: "gp3",
                            "csi.storage.k8s.io/fstype": "ext4"
                        }
                    }
                }
            }
        );

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
        prometheus.node.addDependency(ebsCsiDriver);

        /*
         * Install Kiali.
         * - https://kiali.io/docs/installation/installation-guide/install-with-helm/
         * - https://artifacthub.io/packages/olm/community-operators/kiali
         */
        const kiali = cluster.addHelmChart(
            `${clusterName}-Kiali`,
            {
                repository: "https://kiali.org/helm-charts",
                chart: "kiali-operator",
                release: "kiali-operator",
                namespace: "kiali-operator",
                createNamespace: true,
                values: {
                    cr: {
                        create: true,
                        namespace: "istio-system"
                    }
                }
            }
        );
        kiali.node.addDependency(istioBase);
        kiali.node.addDependency(prometheus);

    }
}

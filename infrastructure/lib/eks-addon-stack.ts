import {aws_eks, NestedStack, Stack, StackProps} from "aws-cdk-lib";
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
                repository: "https://kubernetes-sigs.github.io/metrics-server/",
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
        const istioGateway = cluster.addHelmChart(
            `${clusterName}-Istio-Gateway`,
            {
                repository: "https://istio-release.storage.googleapis.com/charts",
                chart: "gateway",
                release: "istio-gateway",
                namespace: "istio-ingress",
                createNamespace: true
            }
        );
        istioD.node.addDependency(istioBase);
        istioGateway.node.addDependency(istioBase);
        istioGateway.node.addDependency(albController);

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

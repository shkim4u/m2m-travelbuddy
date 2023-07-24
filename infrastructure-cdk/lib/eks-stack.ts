import * as cdk from 'aws-cdk-lib';
import {aws_ec2, aws_eks, aws_iam, Duration, Stack, StackProps} from 'aws-cdk-lib';
import {Construct} from "constructs";
import {AlbController, ClusterLoggingTypes, KubernetesVersion} from "aws-cdk-lib/aws-eks";
import {KubectlV26Layer} from '@aws-cdk/lambda-layer-kubectl-v26';
import {HelmCharts, HelmRepositories} from "../config/helm";
import {InfrastructureEnvironment} from "../bin/infrastructure-environment";
import {AMIFamily, ArchType, Karpenter} from "./karpenter";
import {InstanceClass, InstanceSize, InstanceType} from "aws-cdk-lib/aws-ec2";
import {EksAddonStack} from "./eks-addon-stack";

export class EksStack extends Stack {
    public readonly eksCluster: aws_eks.Cluster;
    public readonly eksDeployRole: aws_iam.Role;
    public readonly albController: AlbController;
    public readonly addonStack: EksAddonStack;

    constructor(
        scope: Construct,
        id: string,
        vpc: aws_ec2.IVpc,
        publicSubnets: aws_ec2.ISubnet[],
        privateSubnets: aws_ec2.ISubnet[],
        clusterName: string,
        serviceName: string,
        clusterAdminIamUsers: string[],
        clusterAdminIamRoles: string[],
        infrastructureEnvironment: InfrastructureEnvironment,
        props: StackProps
    ) {
        super(scope, id, props);

        const eksClusterRole = new aws_iam.Role(
            this,
            `${clusterName}-${props?.env?.region}-ClusterRole`,
            {
                roleName: `${clusterName}-${props?.env?.region}-ClusterRole`,
                assumedBy: new aws_iam.ServicePrincipal('eks.amazonaws.com'),
                managedPolicies: [
                    aws_iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEKSClusterPolicy')
                ]
            }
        );

        const eksMastersRole = new aws_iam.Role(
            this,
            `${clusterName}-${props?.env?.region}-MasterRole`,
            {
                roleName: `${clusterName}-${props?.env?.region}-MasterRole`,
                assumedBy: new aws_iam.AccountPrincipal(this.account)
            }
        );

        // 👇 Create a security group for EKS cluster and node group.
        const clusterSecurityGroup = new aws_ec2.SecurityGroup(
            this,
            `${clusterName}-SecurityGroup`, {
                vpc,
                allowAllOutbound: true,
                description: "Security group for EKS cluster",
            }
        );

        clusterSecurityGroup.addIngressRule(
            aws_ec2.Peer.anyIpv4(),
            aws_ec2.Port.tcp(22),
            'Allow SSH',
        );

        clusterSecurityGroup.addIngressRule(
            // aws_ec2.Peer.ipv4('10.220.0.0/19'),
            // aws_ec2.Peer.ipv4(vpcCidr ?? "10.220.0.0/19"),
            aws_ec2.Peer.ipv4(vpc.vpcCidrBlock),
            aws_ec2.Port.allTraffic(),
            'Allow all traffic from inside VPC'
        );
        clusterSecurityGroup.addIngressRule(
            clusterSecurityGroup,
            aws_ec2.Port.allTraffic(),
            'Allow from this (self-referencing)'
        );

        /*
         * EKS 클러스터를 CDK로 생성 후 Destory시에 Stuck 이슈
         *
         * The cluster is actually destroyed only after the manifests are deleted because of the natural dependency between them. The problem here is that the deletion of manifests is asynchronous, and we currently do not wait for them to be completed before signaling CloudFormation that the resource has been deleted.
         * We already have an issue for this that we plan to address to address soon.
         */
        const eksCluster = new aws_eks.Cluster(
            this,
            `${clusterName}`,
            {
                clusterName: clusterName,
                role: eksClusterRole,
                mastersRole: eksMastersRole,
                version: KubernetesVersion.V1_26,
                kubectlLayer: new KubectlV26Layer(this, 'kubectl'),
                outputClusterName: true,
                endpointAccess: aws_eks.EndpointAccess.PUBLIC_AND_PRIVATE,
                vpc: vpc,
                vpcSubnets: [
                    {
                        subnets: privateSubnets
                    }
                ],
                defaultCapacity: 0,
                // defaultCapacityInstance: aws_ec2.InstanceType.of(aws_ec2.InstanceClass.M5, aws_ec2.InstanceSize.XLARGE),
                outputMastersRoleArn: true,
                securityGroup: clusterSecurityGroup,
                clusterLogging: [
                    ClusterLoggingTypes.API,
                    ClusterLoggingTypes.AUDIT,
                    ClusterLoggingTypes.AUTHENTICATOR,
                    ClusterLoggingTypes.CONTROLLER_MANAGER,
                    ClusterLoggingTypes.SCHEDULER
                ]
            }
        );

        /*
         * Service-linked role (SLR) for EKS node group.
         */
        const slrEksNodeGroup = new aws_iam.CfnServiceLinkedRole(
            this,
            'EksNodeGroupSLR',
            {
                awsServiceName: "eks-nodegroup.amazonaws.com"
            }
        );
        // For Karpenter.
        const spotInstanceServiceLinkedRole = new aws_iam.CfnServiceLinkedRole(
            this,
            'EksSpotInstanceSLR',
            {
                awsServiceName: "spot.amazonaws.com"
            }
        );

        /*
         * IAM for managed node group.
         * [2023-06-01] Custom managed node group setting is commented out for simplicity.
         */
        const eksNodeRole = new aws_iam.Role(
            this,
            `${clusterName}-${props?.env?.region}-NodeRole`,
            {
                roleName: `${clusterName}-${props?.env?.region}-NodeRole`,
                assumedBy: new aws_iam.ServicePrincipal("ec2.amazonaws.com")
            }
        );

        eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEC2ContainerRegistryPowerUser"));
        eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEC2ContainerRegistryReadOnly"));
        eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEKS_CNI_Policy"));
        eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonEKSWorkerNodePolicy"));
        eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("CloudWatchAgentServerPolicy"));
        eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonSSMManagedInstanceCore"));
        // eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AmazonSSMFullAccess"));
        // eksNodeRole.addManagedPolicy(aws_iam.ManagedPolicy.fromAwsManagedPolicyName("SecretsManagerReadWrite"));

        /*
         * Managed node group.
         */
        const eksNodeGroup = new aws_eks.Nodegroup(
            this,
            `${clusterName}-NodeGroup`,
            {
                cluster: eksCluster,
                amiType: aws_eks.NodegroupAmiType.AL2_X86_64,
                // amiType: eks.NodegroupAmiType.AL2_X86_64_GPU,
                nodegroupName: `${clusterName}-NodeGroup`,
                instanceTypes: [new aws_ec2.InstanceType('m5.4xlarge')],
                minSize: 2,
                maxSize: 4,
                desiredSize: 2,
                diskSize: 100,
                capacityType: aws_eks.CapacityType.ON_DEMAND,
                subnets: {
                    subnets: privateSubnets
                },
                nodeRole: eksNodeRole
            }
        );
        eksNodeGroup.node.addDependency(slrEksNodeGroup);

        if (infrastructureEnvironment.useKarpenter) {
            // Enable Karpenter.
            this.enableKarpenter(eksCluster, clusterName);
        } else {
            // Enable cluster autoscaler.
            this.enableClusterAutoscaler(eksCluster, eksNodeGroup, clusterName);
        }

        // Add an existing user to the master role of Kubernetes for convenience use at AWS console.
        // this.addClusterAdminIamUser(eksCluster, clusterAdminIamUser);
        // this.addClusterAdminIamRole(eksCluster, clusterAdminIamRole);
        // this.addClusterAdminIamRole(eksCluster, "TeamRole");

        clusterAdminIamUsers.forEach(userName => this.addClusterAdminIamUser(eksCluster, userName));
        clusterAdminIamRoles.forEach(roleName => this.addClusterAdminIamRole(eksCluster, roleName));


        // Add service namespace.
        serviceName = serviceName.toLowerCase();
        const serviceNamespace = eksCluster.addManifest(
            `${clusterName}-Namespace`,
            {
                apiVersion: 'v1',
                kind: 'Namespace',
                metadata: {
                    name: serviceName.toLowerCase(),
                    // Inject Istio Envoy proxy.
                    labels: {
                        "istio-injection": "enabled"
                    }
                }
            }
        );

        /*
         * Load balancer controller.
         * Steps below are referred from the EKS documentation at: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
         * And here: https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.aws_eks.AlbController.html
         */
        this.albController = new aws_eks.AlbController(
            this,
            `${clusterName}-Load-Balancer-Controller`,
            {
                cluster: eksCluster,
                version: aws_eks.AlbControllerVersion.V2_5_1
            }
        );

        /**
         * [2023-06-04] Add service account for pod and a role for that.
         */
        // Add flightspecials namespace.
        const flightSpecialNamespace = eksCluster.addManifest(
            `${clusterName}-Namespace-FlightSpecials`,
            {
                apiVersion: 'v1',
                kind: 'Namespace',
                metadata: {
                    name: 'flightspecials',
                    // Inject Istio Envoy proxy.
                    labels: {
                        "istio-injection": "enabled"
                    }
                }
            }
        );

        const flightSpecialsPodServiceAccount = eksCluster.addServiceAccount(
            `${clusterName}-FlightSpecials-PodServiceAccount`,
            {
                name: 'flightspecials-service-account',
                namespace: 'flightspecials'
            }
        );
        // Service Account가 'flightspecials' Namespace에 의존하므로 이를 설정한다.
        flightSpecialsPodServiceAccount.node.addDependency(flightSpecialNamespace);
        flightSpecialsPodServiceAccount.addToPrincipalPolicy(
            new aws_iam.PolicyStatement(
                {
                    effect: aws_iam.Effect.ALLOW,
                    actions: [
                        'secretsmanager:GetSecretValue',
                        'secretsmanager:DescribeSecret'
                        // '*'
                    ],
                    resources: [
                        '*'
                    ]
                }
            )
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-FlightSpeials-PodServiceAccountName`, {
                value: flightSpecialsPodServiceAccount.serviceAccountName
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-FlightSpecials-PodServiceAccountRoleArn`, {
                value: flightSpecialsPodServiceAccount.role.roleArn
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-FlightSpecials-PodServiceAccountRoleName`, {
                value: flightSpecialsPodServiceAccount.role.roleName
            }
        );

        this.eksCluster = eksCluster;

        /**
         * Role for push-based pipeline.
         */
        this.eksDeployRole = this.createEksDeployRole(
            this,
            `${clusterName}-${props?.env?.region}-EksDeployRole`,
            eksCluster,
            this.account
        );

        // Print.
        new cdk.CfnOutput(
            this,
            `${clusterName}-EksClusterName`, {
                value: this.eksCluster.clusterName
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-EksEndPoint`, {
                value: this.eksCluster.clusterEndpoint
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-EksDeployRoleArn`, {
                value: this.eksDeployRole.roleArn
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-OpenIdConnectProviderArn`,
            {
                exportName: `${clusterName}-OpenIdConnectProviderArn`,
                value: this.eksCluster.openIdConnectProvider.openIdConnectProviderArn
            }
        );
    }

    addClusterAdminIamUser(cluster: aws_eks.Cluster, iamUserName: string) {
        if (iamUserName) {
            const iamUser = aws_iam.User.fromUserName(this, `${cluster.clusterName}-AdminIamUser-${iamUserName}`, iamUserName);
            cluster.awsAuth.addUserMapping(
                iamUser,
                {
                    username: "admin-user",
                    groups: ['system:masters']
                }
            );
        }
    }

    addClusterAdminIamRole(cluster: aws_eks.Cluster, iamRoleName: string) {
        if (iamRoleName) {
            const iamRole = aws_iam.Role.fromRoleName(this, `${cluster.clusterName}-AdminIamRole-${iamRoleName}`, iamRoleName);
            cluster.awsAuth.addRoleMapping(
                iamRole,
                {
                    username: "admin-role",
                    groups: ['system:masters']
                }
            );
        }
    }

    createEksDeployRole(scope: Construct, id: string, eksCluster: aws_eks.Cluster, account?: string): aws_iam.Role {
        const role = new aws_iam.Role(
            scope,
            id, {
                roleName: id,		// Let's use id as the role name.
                /*
                 * Let's just allow wider scope of this account to assume this role for quick demo.
                 */
                assumedBy: new aws_iam.AccountRootPrincipal(),
                managedPolicies: [
                    // Just used AdminPolicy for limited time. Strongly apply above managed policies.
                    aws_iam.ManagedPolicy.fromAwsManagedPolicyName("AdministratorAccess")
                ]
            }
        );

        eksCluster.awsAuth.addMastersRole(role);

        return role;
    }

    /**
     * [2023-06-19] Enable Karpenter as cluster autoscaler.
     * @param eksCluster
     * @param clusterName
     * @private
     */
    private enableKarpenter(cluster: aws_eks.Cluster, clusterName: string) {
        const karpenter = new Karpenter(
            this,
            `${clusterName}-Karpenter`,
            {
                cluster: cluster,
                vpc: cluster.vpc,
            }
        );

        // Default provisioner.
        // Note: Default provisioner has no cpu/mem limits, nor will cleanup provisioned resources. Use with caution!!!
        // See: https://karpenter.sh/v0.28/concepts/deprovisioning/
        // karpenter.addProvisioner(`${clusterName}-Karpenter-Provisioner-Default`);

        // Custom provisioner.
        karpenter.addProvisioner(
            `${clusterName}-Karpenter-Provisioner-Custom`,
            {
                requirements: {
                    archTypes: [ArchType.AMD64],
                    instanceTypes: [
                        InstanceType.of(InstanceClass.M5, InstanceSize.XLARGE4),
                        InstanceType.of(InstanceClass.C5, InstanceSize.XLARGE4),
                        InstanceType.of(InstanceClass.R5, InstanceSize.XLARGE4),
                        InstanceType.of(InstanceClass.T3, InstanceSize.XLARGE4),
                    ],
                    restrictInstanceTypes: [
                        InstanceType.of(InstanceClass.G5, InstanceSize.LARGE)
                    ]
                },
                // ttlSecondsAfterEmpty: Duration.minutes(10),
                ttlSecondsUntilExpired: Duration.days(90),
                labels: {
                    billing: "aws-proserve"
                },
                limits: {
                    cpu: "250",
                    mem: "1000Gi"
                },
                consolidation: true,
                provider: {
                    amiFamily: AMIFamily.AL2,
                    tags: {
                        Provider: 'Karpenter'
                    }
                }
            }
        );
    }

    /**
     * [2023-06-18] Enable cluster autoscaler.
     * References:
     * - Workshop: https://catalog.us-east-1.prod.workshops.aws/workshops/9c0aa9ab-90a9-44a6-abe1-8dff360ae428/ko-KR/100-scaling/200-cluster-scaling
     * - Compatibility: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler#releases
     */
    enableClusterAutoscaler(cluster: aws_eks.Cluster, nodeGroup: aws_eks.Nodegroup, clusterName: string, version: string = "v1.26.2") {
        const autoscalerPolicyStatement = new aws_iam.PolicyStatement();
        autoscalerPolicyStatement.addResources("*");
        autoscalerPolicyStatement.addActions(
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
        );

        /*
         * CfnJson object to wrap the clusterName as a CDK token (a value that is still not resolved) cannot be used
         * as a key in tags.
         * By doing this, the tag operation is delayed until the clusterName is resolved.
         */
        // const clusterName = new CfnJson(this, "clusterName", { value: cluster.clusterName, });

        const autoscalerPolicy = new aws_iam.Policy(
            this,
            `${clusterName}-Cluster-Autoscaler-Policy`,
            {
                policyName: "ClusterAutoscalerPolicy",
                statements: [autoscalerPolicyStatement],
            }
        );
        // Fallback to node permission.
        autoscalerPolicy.attachToRole(nodeGroup.role);

        cdk.Tags.of(nodeGroup).add(`k8s.io/cluster-autoscaler/${clusterName}`, "owned", { applyToLaunchedInstances: true });
        cdk.Tags.of(nodeGroup).add("k8s.io/cluster-autoscaler/enabled", "true", { applyToLaunchedInstances: true });

        // Create the service account with annotated IAM role (IRSA) for least privilege.
        const clusterAutoscalerServiceAccount = cluster.addServiceAccount(
            `${clusterName}-Cluster-Autoscaler-Service-Account`,
            {
                name: 'cluster-autoscaler',
                namespace: 'kube-system',
                labels: {
                    "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                    "k8s-app": "cluster-autoscaler",
                },
            }
        );
        clusterAutoscalerServiceAccount.addToPrincipalPolicy(autoscalerPolicyStatement);
        new cdk.CfnOutput(
            this,
            `${clusterName}-Cluster-Autoscaler-Service-Account-Name`, {
                value: clusterAutoscalerServiceAccount.serviceAccountName
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-Cluster-Autoscaler-Service-Account-Role-Arn`, {
                value: clusterAutoscalerServiceAccount.role.roleArn
            }
        );
        new cdk.CfnOutput(
            this,
            `${clusterName}-Cluster-Autoscaler-Service-Account-Role-Name`, {
                value: clusterAutoscalerServiceAccount.role.roleName
            }
        );

        const autoscalerManifiest = new aws_eks.KubernetesManifest(
            this,
            `${clusterName}-Cluster-Autoscaler`, {
            cluster,
            // For the latest manifest, refer to: https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
            manifest: [
                // {
                //     apiVersion: "v1",
                //     kind: "ServiceAccount",
                //     metadata: {
                //         name: "cluster-autoscaler",
                //         namespace: "kube-system",
                //         labels: {
                //             "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                //             "k8s-app": "cluster-autoscaler",
                //         },
                //     },
                // },
                {
                    apiVersion: "rbac.authorization.k8s.io/v1",
                    kind: "ClusterRole",
                    metadata: {
                        name: "cluster-autoscaler",
                        namespace: "kube-system",
                        labels: {
                            "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                            "k8s-app": "cluster-autoscaler",
                        },
                    },
                    rules: [
                        {
                            apiGroups: [""],
                            resources: ["events", "endpoints"],
                            verbs: ["create", "patch"],
                        },
                        {
                            apiGroups: [""],
                            resources: ["pods/eviction"],
                            verbs: ["create"],
                        },
                        {
                            apiGroups: [""],
                            resources: ["pods/status"],
                            verbs: ["update"],
                        },
                        {
                            apiGroups: [""],
                            resources: ["endpoints"],
                            resourceNames: ["cluster-autoscaler"],
                            verbs: ["get", "update"],
                        },
                        {
                            apiGroups: ["coordination.k8s.io"],
                            resources: ["leases"],
                            verbs: ["watch", "list", "get", "patch", "create", "update"],
                        },
                        {
                            apiGroups: [""],
                            resources: ["nodes"],
                            verbs: ["watch", "list", "get", "update"],
                        },
                        {
                            apiGroups: [""],
                            resources: ["namespaces", "pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"],
                            verbs: ["watch", "list", "get"],
                        },
                        {
                            apiGroups: ["extensions"],
                            resources: ["replicasets", "daemonsets"],
                            verbs: ["watch", "list", "get"],
                        },
                        {
                            apiGroups: ["policy"],
                            resources: ["poddisruptionbudgets"],
                            verbs: ["watch", "list"],
                        },
                        {
                            apiGroups: ["apps"],
                            resources: ["statefulsets", "replicasets", "daemonsets"],
                            verbs: ["watch", "list", "get"],
                        },
                        {
                            apiGroups: ["storage.k8s.io"],
                            resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"],
                            verbs: ["watch", "list", "get"],
                        },
                        {
                            apiGroups: ["batch", "extensions"],
                            resources: ["jobs"],
                            verbs: ["get", "list", "watch", "patch"],
                        },
                        {
                            apiGroups: ["coordination.k8s.io"],
                            resources: ["leases"],
                            verbs: ["create"],
                        },
                        {
                            apiGroups: ["coordination.k8s.io"],
                            resourceNames: ["cluster-autoscaler"],
                            resources: ["leases"],
                            verbs: ["get", "update"],
                        },
                    ],
                },
                {
                    apiVersion: "rbac.authorization.k8s.io/v1",
                    kind: "Role",
                    metadata: {
                        name: "cluster-autoscaler",
                        namespace: "kube-system",
                        labels: {
                            "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                            "k8s-app": "cluster-autoscaler",
                        },
                    },
                    rules: [
                        {
                            apiGroups: [""],
                            resources: ["configmaps"],
                            verbs: ["create", "list", "watch"],
                        },
                        {
                            apiGroups: [""],
                            resources: ["configmaps"],
                            resourceNames: ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"],
                            verbs: ["delete", "get", "update", "watch"],
                        },
                    ],
                },
                {
                    apiVersion: "rbac.authorization.k8s.io/v1",
                    kind: "ClusterRoleBinding",
                    metadata: {
                        name: "cluster-autoscaler",
                        namespace: "kube-system",
                        labels: {
                            "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                            "k8s-app": "cluster-autoscaler",
                        },
                    },
                    roleRef: {
                        apiGroup: "rbac.authorization.k8s.io",
                        kind: "ClusterRole",
                        name: "cluster-autoscaler",
                    },
                    subjects: [
                        {
                            kind: "ServiceAccount",
                            name: "cluster-autoscaler",
                            namespace: "kube-system",
                        },
                    ],
                },
                {
                    apiVersion: "rbac.authorization.k8s.io/v1",
                    kind: "RoleBinding",
                    metadata: {
                        name: "cluster-autoscaler",
                        namespace: "kube-system",
                        labels: {
                            "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                            "k8s-app": "cluster-autoscaler",
                        },
                    },
                    roleRef: {
                        apiGroup: "rbac.authorization.k8s.io",
                        kind: "Role",
                        name: "cluster-autoscaler",
                    },
                    subjects: [
                        {
                            kind: "ServiceAccount",
                            name: "cluster-autoscaler",
                            namespace: "kube-system",
                        },
                    ],
                },
                {
                    apiVersion: "apps/v1",
                    kind: "Deployment",
                    metadata: {
                        name: "cluster-autoscaler",
                        namespace: "kube-system",
                        labels: {
                            app: "cluster-autoscaler",
                        },
                        annotations: {
                            "cluster-autoscaler.kubernetes.io/safe-to-evict": "false",
                        },
                    },
                    spec: {
                        replicas: 1,
                        selector: {
                            matchLabels: {
                                app: "cluster-autoscaler",
                            },
                        },
                        template: {
                            metadata: {
                                labels: {
                                    app: "cluster-autoscaler",
                                },
                                annotations: {
                                    "prometheus.io/scrape": "true",
                                    "prometheus.io/port": "8085",
                                },
                            },
                            spec: {
                                serviceAccountName: "cluster-autoscaler",
                                containers: [
                                    {
                                        image: "registry.k8s.io/autoscaling/cluster-autoscaler:" + version,
                                        name: "cluster-autoscaler",
                                        resources: {
                                            limits: {
                                                cpu: "100m",
                                                memory: "600Mi",
                                            },
                                            requests: {
                                                cpu: "100m",
                                                memory: "600Mi",
                                            },
                                        },
                                        command: [
                                            "./cluster-autoscaler",
                                            "--v=4",
                                            "--stderrthreshold=info",
                                            "--cloud-provider=aws",
                                            "--skip-nodes-with-local-storage=false",
                                            "--expander=least-waste",
                                            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/" + cluster.clusterName,
                                            "--balance-similar-node-groups",
                                            "--skip-nodes-with-system-pods=false",
                                        ],
                                        volumeMounts: [
                                            {
                                                name: "ssl-certs",
                                                mountPath: "/etc/ssl/certs/ca-certificates.crt",
                                                readOnly: true,
                                            },
                                        ],
                                        imagePullPolicy: "Always",
                                        securityContext: {
                                            allowPrivilegeEscalation: false,
                                            capabilities: {
                                                drop: [
                                                    "ALL"
                                                ]
                                            },
                                            readOnlyRootFilesystem: true
                                        }
                                    },
                                ],
                                volumes: [
                                    {
                                        name: "ssl-certs",
                                        hostPath: {
                                            path: "/etc/ssl/certs/ca-bundle.crt",
                                        },
                                    },
                                ],
                            },
                        },
                    },
                },
            ],
        });
        autoscalerManifiest.node.addDependency(clusterAutoscalerServiceAccount);
    }
}

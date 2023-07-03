import {aws_ec2, aws_msk, Stack, StackProps} from "aws-cdk-lib";
import {Construct} from "constructs";

export class MskStack extends Stack {
    private mskCluster: aws_msk.CfnCluster;

    constructor(
        scope: Construct,
        id: string,
        vpc: aws_ec2.IVpc,
        subnets: aws_ec2.ISubnet[],
        props: StackProps
    ) {
        super(scope, id, props);

        /*
         * Security group for MSK.
         */
        const mskSecurityGroup = new aws_ec2.SecurityGroup(
            this,
            `${id}-MSK-SecurityGroup`,
            {
                vpc,
                allowAllOutbound: true,
                description: "Security group for MSK cluster"
            }
        );

        // Self-referencing rule.
        mskSecurityGroup.addIngressRule(
            mskSecurityGroup,
            aws_ec2.Port.allTraffic(),
            "Within this Kafka cluster"
        );
        mskSecurityGroup.addIngressRule(
            aws_ec2.Peer.ipv4(vpc.vpcCidrBlock),
            aws_ec2.Port.tcp(9092),
            "Kafka communication (Plaintext)"
        );
        mskSecurityGroup.addIngressRule(
            aws_ec2.Peer.ipv4(vpc.vpcCidrBlock),
            aws_ec2.Port.tcp(9094),
            "Kafka communication (TLS)"
        );
        mskSecurityGroup.addIngressRule(
            aws_ec2.Peer.ipv4(vpc.vpcCidrBlock),
            aws_ec2.Port.tcp(2181),
            "Kafka ZooKeeper"
        );

        const subnetsString = subnets.map(
            (subnet, index) => subnet.subnetId
        );
        const mskCluster = new aws_msk.CfnCluster(
            this,
            `${id}-MSK-Cluster`,
            {
                clusterName: `${id}-MSK-Cluster`,
                kafkaVersion: "2.8.1",
                numberOfBrokerNodes: (subnets.length * 2),
                brokerNodeGroupInfo: {
                    clientSubnets: subnetsString,
                    instanceType: "kafka.m5.large",
                    securityGroups: [mskSecurityGroup.securityGroupId],
                },
                encryptionInfo: {
                    encryptionInTransit: {
                        inCluster: true,
                        clientBroker: "TLS"
                    }
                },
                clientAuthentication: {
                    sasl: {
                        iam: {
                            enabled: true
                        }
                    }
                },
                // clientAuthentication: {
                //     sasl: {
                //         iam: {
                //             enabled: false,
                //         },
                //         scram: {
                //             enabled: false,
                //         },
                //     },
                //     tls: {
                //         certificateAuthorityArnList: ['certificateAuthorityArnList'],
                //         enabled: false,
                //     },
                //     unauthenticated: {
                //         enabled: false,
                //     },
                // },
                enhancedMonitoring: "PER_TOPIC_PER_BROKER",
                tags: {
                    "Description": "MSK Cluster for M2M project",
                    "Owner": "AWS ProServe",
                }
            }
        );

        this.mskCluster = mskCluster;
    }
}

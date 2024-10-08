import {aws_ec2, aws_logs, aws_msk, Stack, StackProps, RemovalPolicy} from "aws-cdk-lib";
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

        const logGroup = new aws_logs.LogGroup(
            this,
            `${id}-MSK-CloudWatch-LogGroup`,
            {
                logGroupName: `/m2m/msk/${id}-MSK-Cluster`,
                retention: aws_logs.RetentionDays.ONE_WEEK,
                removalPolicy: RemovalPolicy.DESTROY
            }
        );

        /*
         * Security group for MSK.
         * https://docs.aws.amazon.com/msk/latest/developerguide/port-info.html
         * https://docs.aws.amazon.com/msk/latest/developerguide/iam-access-control.html
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
            aws_ec2.Port.tcp(9096),
            "Kafka communication (SASL/SCRAM)"
        );
        mskSecurityGroup.addIngressRule(
            aws_ec2.Peer.ipv4(vpc.vpcCidrBlock),
            aws_ec2.Port.tcp(9098),
            "Kafka communication (IAM)"
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
                loggingInfo: {
                    brokerLogs: {
                        cloudWatchLogs: {
                            enabled: true,
                            // The properties below are optional
                            logGroup: logGroup.logGroupName,
                        },
                        // firehose: {
                        //     enabled: false,
                        //
                        //     // the properties below are optional
                        //     deliveryStream: 'deliveryStream',
                        // },
                        // s3: {
                        //     enabled: false,
                        //
                        //     // the properties below are optional
                        //     bucket: 'bucket',
                        //     prefix: 'prefix',
                        // },
                    },
                },
                tags: {
                    "Description": "MSK Cluster for M2M project",
                    "Owner": "AWS ProServe",
                }
            }
        );

        this.mskCluster = mskCluster;
    }
}

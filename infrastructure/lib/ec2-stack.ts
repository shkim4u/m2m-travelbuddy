import * as cdk from 'aws-cdk-lib';
import {Construct} from "constructs";
import {aws_ec2, Stack, StackProps} from "aws-cdk-lib";
import {Role} from "aws-cdk-lib/aws-iam";

export class Ec2Stack extends Stack {
  constructor(
    scope: Construct,
    id: string,
    vpc: aws_ec2.IVpc,
    publicSubnets: aws_ec2.ISubnet[],
    role: Role,
    props: StackProps
  ) {
    super(scope, id, props);

    /*
     * Create a security group for a bastion host.
     */
    const rdsBastionSecurityGroup = new aws_ec2.SecurityGroup(
      this,
      `${id}-Bastion-SecurityGroup`,
      {
        vpc,
        allowAllOutbound: true,
        description: 'Security group for a bastion host',
      }
    );

    /*
     * Create the bastion host.
     */
    const rdsBastion = new aws_ec2.Instance(
      this,
      `${id}-${props?.env?.region}-RdsBastion`,
      {
        instanceName: "RDS-Bastion",
        vpc: vpc,
        vpcSubnets: {
          // subnetType: aws_ec2.SubnetType.PUBLIC,
          subnets: [
            publicSubnets[0]
          ]
        },
        role: role,
        securityGroup: rdsBastionSecurityGroup,
        instanceType: aws_ec2.InstanceType.of(
          aws_ec2.InstanceClass.M5,
          aws_ec2.InstanceSize.XLARGE,
        ),
        machineImage: new aws_ec2.AmazonLinuxImage(
          {
            generation: aws_ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
          }
        ),
      }
    );

    /**
     * Outputs
     */
    new cdk.CfnOutput(
      this,
      `${id}-Rds-Bastion-PublicIp`, {
        value: rdsBastion.instancePublicIp
      }
    );

    new cdk.CfnOutput(
      this,
      `${id}-Rds-Bastion-PrivateIp`, {
        value: rdsBastion.instancePrivateIp
      }
    );

  }
}

#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import {InfrastructureEnvironment} from "./infrastructure-environment";
import {NetworkStack} from "../lib/network-stack";
import {EksStack} from "../lib/eks-stack";
import {BuildDeliveryStack} from "../lib/build-delivery-stack";
import {SsmStack} from "../lib/ssm-stack";
import {IamStack} from "../lib/iam-stack";
import {Ec2Stack} from "../lib/ec2-stack";
import {RdsLegacyStack} from "../lib/rds-legacy-stack";
import * as net from "net";
import {FlightSpecialDatabaseStack} from "../lib/flightspecial-database-stack";
import {MskStack} from "../lib/msk-stack";

const app = new cdk.App();

/**
 * CDK_INTEG_XXX are set when producing the environment-aware values and CDK_DEFAULT_XXX is passed in through from the CLI in actual deployment.
 */
const env = {
    region: app.node.tryGetContext('region') || process.env.CDK_INTEG_REGION || process.env.CDK_DEFAULT_REGION,
    account: app.node.tryGetContext('account') || process.env.CDK_INTEG_ACCOUNT || process.env.CDK_DEFAULT_ACCOUNT,
};

/**
 * Basic VPC info for EKS clusters.
 * (참고) 아래에서 반드시 EKS Admin User와 Admin Role을 자신의 환경에 맞게 설정한다.
 * (참고) 설정하지 않아도 EKS 클러스터 생성 후에도 kubectl로 접근할 수 있다. 방법은?
 */
const infrastructureEnvironment: InfrastructureEnvironment = {
    stackNamePrefix: "M2M",
    vpcCidr: "10.220.0.0/19",
    useKarpenter: true,
    cidrPublicSubnetAZa: "10.220.0.0/22",
    cidrPublicSubnetAZc: "10.220.12.0/22",
    cidrPrivateSubnetAZa: "10.220.4.0/22",
    cidrPrivateSubnetAZc: "10.220.8.0/22",
    eksClusterAdminIamUsers: ["admin"],
    eksClusterAdminIamRoles: ["TeamRole", "cloud9-admin"],
};

/**
 * IAM stack.
 */
const iamStack = new IamStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-IamStack`,
    {
        env
    }
);


/**
 * Network stack.
 */
let networkStack: NetworkStack | undefined = undefined;
networkStack = new NetworkStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-NetworkStack`,
    infrastructureEnvironment,
    {
        env
    }
);

/**
 * RDS bastion instances and some possible others.
 */
const ec2Stack = new Ec2Stack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-Ec2Stack`,
    networkStack.vpc,
    networkStack.eksPublicSubnets,
    iamStack.adminRole,
    {
        env
    }
);

/**
 * EKS Cluster Stack.
 */
const eksStarck = new EksStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-EksStack`,
    networkStack.vpc,
    networkStack.eksPublicSubnets,
    networkStack.eksPrivateSubnets,
    `${infrastructureEnvironment.stackNamePrefix}-EksCluster`,
    "m2m",
    infrastructureEnvironment.eksClusterAdminIamUsers ?? [],
    infrastructureEnvironment.eksClusterAdminIamRoles ?? [],
    infrastructureEnvironment,
    {
        env
    }
);
eksStarck.addDependency(networkStack);

/**
 * Build and delivery stack.
 */
const buildAndDeliveryStack = new BuildDeliveryStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-BuildAndDeliveryStack`,
    eksStarck.eksCluster,
    eksStarck.eksDeployRole,
    {
        env
    }
);
buildAndDeliveryStack.addDependency(eksStarck);

/**
 * FlightSpecial build and delivery stack.
 */
const flightspecialBuildandDeliveryStack = new BuildDeliveryStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-FlightSpecialCICDStack`,
    eksStarck.eksCluster,
    eksStarck.eksDeployRole,
    {
        env
    }
);
flightspecialBuildandDeliveryStack.addDependency(eksStarck);

/**
 * SSM Stack.
 */
const ssmStack = new SsmStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-SsmStack`,
    {
        env
    }
);

/**
 * [2023-06-03] RDS legacy stack for legacy TravelBuddy application.
 */
const rdsLegacyStack = new RdsLegacyStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-RdsLegacyStack`,
    networkStack.vpc,
    networkStack.eksPrivateSubnets,
    {
        env
    }
);
rdsLegacyStack.addDependency(networkStack);

/**
 * [2023-06-03] Postgres Database stack for FlightSpecial microservice.
 */
const flightspecialDatabaseStack = new FlightSpecialDatabaseStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-FlightSpecialDatabaseStack`,
    networkStack.vpc,
    networkStack.eksPrivateSubnets,
    {
        env
    }
);
flightspecialDatabaseStack.addDependency(networkStack);

/**
 * Amazon MSK (Managed Streaming for Kafka) stack.
 */
const mskStack = new MskStack(
    app,
    `${infrastructureEnvironment.stackNamePrefix}-MskStack`,
    networkStack.vpc,
    networkStack.eksPrivateSubnets,
    {
        env
    }
);
mskStack.addDependency(networkStack);

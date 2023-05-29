#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import {InfrastructureEnvironment} from "./infrastructure-environment";
import {NetworkStack} from "../lib/network-stack";
import {EksStack} from "../lib/eks-stack";
import {BuildDeliveryStack} from "../lib/build-delivery-stack";

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
 */
const infrastructureEnvironment: InfrastructureEnvironment = {
  stackNamePrefix: "M2M",
  vpcCidr: "10.220.0.0/19",
  cidrPublicSubnetAZa: "10.220.0.0/22",
  cidrPublicSubnetAZc: "10.220.12.0/22",
  cidrPrivateSubnetAZa: "10.220.4.0/22",
  cidrPrivateSubnetAZc: "10.220.8.0/22",
  eksClusterAdminIamUser: "shkim4u",
  eksClusterAdminIamRole: "m2m-admin",
};

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
  infrastructureEnvironment.eksClusterAdminIamUser ?? "",
  infrastructureEnvironment.eksClusterAdminIamRole ?? "",
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

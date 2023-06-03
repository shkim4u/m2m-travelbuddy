import {Duration, RemovalPolicy, Stack, StackProps} from "aws-cdk-lib";
import {InstanceClass, InstanceSize, InstanceType, ISubnet, IVpc} from "aws-cdk-lib/aws-ec2";
import {Credentials, DatabaseInstance, DatabaseInstanceEngine, PostgresEngineVersion} from "aws-cdk-lib/aws-rds";
import {Construct} from "constructs";
import {deployEnv, isProductionDeployEnv, KnownDeployEnv, projectEnvSpecificName} from "./env-utils";
import * as cdk from "aws-cdk-lib";
import {Secret} from "aws-cdk-lib/aws-secretsmanager";

export class FlightSpecialDatabaseStack extends Stack {
    static readonly databasePort = 5432;
    static readonly databaseName = `dso`;

    readonly databaseInstance: DatabaseInstance;

    constructor(
        scope: Construct,
        id: string,
        vpc: IVpc,
        privateSubnets: ISubnet[],
        props: StackProps,
    ) {
        super(scope, id, props);

        const databaseUserName = "postgres";
        // const databasePassword = "P@ssw0rd";
        const databaseCredentialSecretName = `flightspecial_db_credentials_${deployEnv()}`;

        const databaseCredentials = Credentials.fromGeneratedSecret(
            databaseUserName,
            {
                secretName: databaseCredentialSecretName
            }
        );

        this.databaseInstance = new DatabaseInstance(
            this,
            projectEnvSpecificName('postgres-db'),
            {
                databaseName: FlightSpecialDatabaseStack.databaseName,
                engine: DatabaseInstanceEngine.postgres({version: PostgresEngineVersion.VER_15_2}),
                instanceType: InstanceType.of(InstanceClass.M5, InstanceSize.XLARGE),
                instanceIdentifier: projectEnvSpecificName('postgres-db'),
                credentials: databaseCredentials,
                port: FlightSpecialDatabaseStack.databasePort,
                maxAllocatedStorage: 200,
                vpc,
                vpcSubnets: {
                    subnets: privateSubnets
                },
                deletionProtection: deployEnv() == KnownDeployEnv.prod,
                removalPolicy: removalPolicyAppropriateForEnv(),
                backupRetention: databaseBackupRetentionDaysForEnv(),
                copyTagsToSnapshot: true,
                iamAuthentication: true
            }
        );

        /**
         * Outputs
         */
        new cdk.CfnOutput(
            this,
            `${id}-FlightSpecial-DB-Endpoint`, {
                value: this.databaseInstance.dbInstanceEndpointAddress
            }
        );
        new cdk.CfnOutput(
            this,
            `${id}-FlightSpecial-DB-Port`, {
                value: this.databaseInstance.dbInstanceEndpointPort
            }
        );

        // new cdk.CfnOutput(
        //     this,
        //     `${id}-FlightSpecial-DB-User`, {
        //         value: Secret.fromSecretNameV2(this.databaseInstance.secret!, "username")
        //     }
        // );
        // new cdk.CfnOutput(
        //     this,
        //     `${id}-FlightSpecial-DB-Password`, {
        //         value: Secret.fromSecretsManager(this.databaseInstance.secret!, "password")
        //     }
        // );
    }
}

export function removalPolicyAppropriateForEnv() {
    return isProductionDeployEnv() ? RemovalPolicy.RETAIN : RemovalPolicy.DESTROY;
}

export function databaseBackupRetentionDaysForEnv() {
    return isProductionDeployEnv() ? Duration.days(14) : Duration.days(1)
}


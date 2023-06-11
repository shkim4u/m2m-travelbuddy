
const DEPLOY_ENV: DeployEnv = process.env.DEPLOY_ENV || 'test';

export enum KnownDeployEnv {
    prod = 'prod',
    stage = 'stage',
    test = 'test'
}

export function deployEnv(): DeployEnv {
    return DEPLOY_ENV;
}

export type DeployEnv = KnownDeployEnv | string

export const PROJECT_NAME = "flightspecials";

export function projectEnvSpecificName(name: string = ""): string {
    const prefix = PROJECT_NAME.replace('_', '-') + "-" + DEPLOY_ENV;
    if (name.startsWith(prefix)) {
        return name
    } else {
        return `${prefix}-${name}`
    }
}

export function isProductionDeployEnv() {
    return deployEnv() == KnownDeployEnv.prod
}

const rawDeploymentMode = (process.env.NEXT_PUBLIC_DEPLOYMENT_MODE || 'local').toLowerCase();
const backendFlagEnabled = process.env.NEXT_PUBLIC_ENABLE_SUBSCRIPTION_BACKEND === 'true';

export type DeploymentMode = 'local' | 'cloud';

export const getDeploymentMode = (): DeploymentMode => {
  return rawDeploymentMode === 'local' ? 'local' : 'cloud';
};

export const isLocalMode = (): boolean => getDeploymentMode() === 'local';

export const isCloudMode = (): boolean => !isLocalMode();

export const isSubscriptionBackendEnabled = (): boolean => {
  if (isLocalMode()) {
    return false;
  }
  return backendFlagEnabled;
};

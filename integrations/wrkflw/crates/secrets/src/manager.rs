use crate::{
    config::{SecretConfig, SecretProviderConfig},
    providers::{env::EnvironmentProvider, file::FileProvider, SecretProvider, SecretValue},
    rate_limit::RateLimiter,
    validation::{validate_provider_name, validate_secret_name},
    SecretError, SecretResult,
};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

/// Cached secret entry
#[derive(Debug, Clone)]
struct CachedSecret {
    value: SecretValue,
    expires_at: chrono::DateTime<chrono::Utc>,
}

/// Central secret manager that coordinates multiple providers
pub struct SecretManager {
    config: SecretConfig,
    providers: HashMap<String, Box<dyn SecretProvider>>,
    cache: Arc<RwLock<HashMap<String, CachedSecret>>>,
    rate_limiter: RateLimiter,
}

impl SecretManager {
    /// Create a new secret manager with the given configuration
    pub async fn new(config: SecretConfig) -> SecretResult<Self> {
        let mut providers: HashMap<String, Box<dyn SecretProvider>> = HashMap::new();

        // Initialize providers based on configuration
        for (name, provider_config) in &config.providers {
            // Validate provider name
            validate_provider_name(name)?;

            let provider: Box<dyn SecretProvider> = match provider_config {
                SecretProviderConfig::Environment { prefix } => {
                    Box::new(EnvironmentProvider::new(prefix.clone()))
                }
                SecretProviderConfig::File { path } => Box::new(FileProvider::new(path.clone())),
                // Cloud providers are planned for future implementation
                // #[cfg(feature = "vault-provider")]
                // SecretProviderConfig::Vault { url, auth, mount_path } => {
                //     Box::new(crate::providers::vault::VaultProvider::new(
                //         url.clone(),
                //         auth.clone(),
                //         mount_path.clone(),
                //     ).await?)
                // }
            };

            providers.insert(name.clone(), provider);
        }

        let rate_limiter = RateLimiter::new(config.rate_limit.clone());

        Ok(Self {
            config,
            providers,
            cache: Arc::new(RwLock::new(HashMap::new())),
            rate_limiter,
        })
    }

    /// Create a new secret manager with default configuration
    pub async fn default() -> SecretResult<Self> {
        Self::new(SecretConfig::default()).await
    }

    /// Get a secret by name using the default provider
    pub async fn get_secret(&self, name: &str) -> SecretResult<SecretValue> {
        validate_secret_name(name)?;
        self.get_secret_from_provider(&self.config.default_provider, name)
            .await
    }

    /// Get a secret from a specific provider
    pub async fn get_secret_from_provider(
        &self,
        provider_name: &str,
        name: &str,
    ) -> SecretResult<SecretValue> {
        validate_provider_name(provider_name)?;
        validate_secret_name(name)?;

        // Check rate limit
        let rate_limit_key = format!("{}:{}", provider_name, name);
        self.rate_limiter.check_rate_limit(&rate_limit_key).await?;

        // Check cache first if caching is enabled
        if self.config.enable_caching {
            let cache_key = format!("{}:{}", provider_name, name);

            {
                let cache = self.cache.read().await;
                if let Some(cached) = cache.get(&cache_key) {
                    if chrono::Utc::now() < cached.expires_at {
                        return Ok(cached.value.clone());
                    }
                }
            }
        }

        // Get provider
        let provider = self
            .providers
            .get(provider_name)
            .ok_or_else(|| SecretError::provider_not_found(provider_name))?;

        // Get secret from provider
        let secret = provider.get_secret(name).await?;

        // Cache the result if caching is enabled
        if self.config.enable_caching {
            let cache_key = format!("{}:{}", provider_name, name);
            let expires_at = chrono::Utc::now()
                + chrono::Duration::seconds(self.config.cache_ttl_seconds as i64);

            let cached_secret = CachedSecret {
                value: secret.clone(),
                expires_at,
            };

            let mut cache = self.cache.write().await;
            cache.insert(cache_key, cached_secret);
        }

        Ok(secret)
    }

    /// List all available secrets from all providers
    pub async fn list_all_secrets(&self) -> SecretResult<HashMap<String, Vec<String>>> {
        let mut all_secrets = HashMap::new();

        for (provider_name, provider) in &self.providers {
            match provider.list_secrets().await {
                Ok(secrets) => {
                    all_secrets.insert(provider_name.clone(), secrets);
                }
                Err(_) => {
                    // Some providers may not support listing, ignore errors
                    all_secrets.insert(provider_name.clone(), vec![]);
                }
            }
        }

        Ok(all_secrets)
    }

    /// Check health of all providers
    pub async fn health_check(&self) -> HashMap<String, SecretResult<()>> {
        let mut results = HashMap::new();

        for (provider_name, provider) in &self.providers {
            let result = provider.health_check().await;
            results.insert(provider_name.clone(), result);
        }

        results
    }

    /// Clear the cache
    pub async fn clear_cache(&self) {
        let mut cache = self.cache.write().await;
        cache.clear();
    }

    /// Get configuration
    pub fn config(&self) -> &SecretConfig {
        &self.config
    }

    /// Check if a provider exists
    pub fn has_provider(&self, name: &str) -> bool {
        self.providers.contains_key(name)
    }

    /// Get provider names
    pub fn provider_names(&self) -> Vec<String> {
        self.providers.keys().cloned().collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_secret_manager_creation() {
        let config = SecretConfig::default();
        let manager = SecretManager::new(config).await;
        assert!(manager.is_ok());

        let manager = manager.unwrap();
        assert!(manager.has_provider("env"));
        assert!(manager.has_provider("file"));
    }

    #[tokio::test]
    async fn test_secret_manager_environment_provider() {
        // Use unique secret name to avoid test conflicts
        let test_secret_name = format!("TEST_SECRET_MANAGER_{}", std::process::id());
        std::env::set_var(&test_secret_name, "manager_test_value");

        let manager = SecretManager::default().await.unwrap();
        let result = manager
            .get_secret_from_provider("env", &test_secret_name)
            .await;

        assert!(result.is_ok());
        let secret = result.unwrap();
        assert_eq!(secret.value(), "manager_test_value");

        std::env::remove_var(&test_secret_name);
    }

    #[tokio::test]
    async fn test_secret_manager_caching() {
        // Use unique secret name to avoid test conflicts
        let test_secret_name = format!("CACHE_TEST_SECRET_{}", std::process::id());
        std::env::set_var(&test_secret_name, "cached_value");

        let config = SecretConfig {
            enable_caching: true,
            cache_ttl_seconds: 60, // 1 minute
            ..Default::default()
        };

        let manager = SecretManager::new(config).await.unwrap();

        // First call should hit the provider
        let result1 = manager
            .get_secret_from_provider("env", &test_secret_name)
            .await;
        assert!(result1.is_ok());

        // Remove the environment variable
        std::env::remove_var(&test_secret_name);

        // Second call should hit the cache and still return the value
        let result2 = manager
            .get_secret_from_provider("env", &test_secret_name)
            .await;
        assert!(result2.is_ok());
        assert_eq!(result2.unwrap().value(), "cached_value");

        // Clear cache and try again - should fail now
        manager.clear_cache().await;
        let result3 = manager
            .get_secret_from_provider("env", &test_secret_name)
            .await;
        assert!(result3.is_err());
    }

    #[tokio::test]
    async fn test_secret_manager_health_check() {
        let manager = SecretManager::default().await.unwrap();
        let health_results = manager.health_check().await;

        assert!(health_results.contains_key("env"));
        assert!(health_results.contains_key("file"));

        // Environment provider should be healthy
        assert!(health_results.get("env").unwrap().is_ok());
    }
}

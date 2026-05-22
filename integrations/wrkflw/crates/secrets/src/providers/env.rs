use crate::{
    validation::validate_secret_value, SecretError, SecretProvider, SecretResult, SecretValue,
};
use async_trait::async_trait;
use std::collections::HashMap;

/// Environment variable secret provider
pub struct EnvironmentProvider {
    prefix: Option<String>,
}

impl EnvironmentProvider {
    /// Create a new environment provider
    pub fn new(prefix: Option<String>) -> Self {
        Self { prefix }
    }
}

impl Default for EnvironmentProvider {
    fn default() -> Self {
        Self::new(None)
    }
}

impl EnvironmentProvider {
    /// Get the full environment variable name
    fn get_env_name(&self, name: &str) -> String {
        match &self.prefix {
            Some(prefix) => format!("{}{}", prefix, name),
            None => name.to_string(),
        }
    }
}

#[async_trait]
impl SecretProvider for EnvironmentProvider {
    async fn get_secret(&self, name: &str) -> SecretResult<SecretValue> {
        let env_name = self.get_env_name(name);

        match std::env::var(&env_name) {
            Ok(value) => {
                // Validate the secret value
                validate_secret_value(&value)?;

                let mut metadata = HashMap::new();
                metadata.insert("source".to_string(), "environment".to_string());
                metadata.insert("env_var".to_string(), env_name);

                Ok(SecretValue::with_metadata(value, metadata))
            }
            Err(std::env::VarError::NotPresent) => Err(SecretError::not_found(name)),
            Err(std::env::VarError::NotUnicode(_)) => Err(SecretError::InvalidFormat(format!(
                "Environment variable '{}' contains invalid Unicode",
                env_name
            ))),
        }
    }

    async fn list_secrets(&self) -> SecretResult<Vec<String>> {
        let mut secrets = Vec::new();

        for (key, _) in std::env::vars() {
            if let Some(prefix) = &self.prefix {
                if key.starts_with(prefix) {
                    secrets.push(key[prefix.len()..].to_string());
                }
            } else {
                // Without a prefix, we can't distinguish secrets from regular env vars
                // So we'll return an error suggesting the use of a prefix
                return Err(SecretError::internal(
                    "Cannot list secrets from environment without a prefix. Configure a prefix like 'WRKFLW_SECRET_'"
                ));
            }
        }

        Ok(secrets)
    }

    fn name(&self) -> &str {
        "environment"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_environment_provider_basic() {
        let provider = EnvironmentProvider::default();

        // Use unique secret name to avoid test conflicts
        let test_secret_name = format!("TEST_SECRET_{}", std::process::id());
        std::env::set_var(&test_secret_name, "test_value");

        let result = provider.get_secret(&test_secret_name).await;
        assert!(result.is_ok());

        let secret = result.unwrap();
        assert_eq!(secret.value(), "test_value");
        assert_eq!(
            secret.metadata.get("source"),
            Some(&"environment".to_string())
        );

        // Clean up
        std::env::remove_var(&test_secret_name);
    }

    #[tokio::test]
    async fn test_environment_provider_with_prefix() {
        let provider = EnvironmentProvider::new(Some("WRKFLW_SECRET_".to_string()));

        // Use unique secret name to avoid test conflicts
        let test_secret_name = format!("API_KEY_{}", std::process::id());
        let full_env_name = format!("WRKFLW_SECRET_{}", test_secret_name);
        std::env::set_var(&full_env_name, "secret_api_key");

        let result = provider.get_secret(&test_secret_name).await;
        assert!(result.is_ok());

        let secret = result.unwrap();
        assert_eq!(secret.value(), "secret_api_key");

        // Clean up
        std::env::remove_var(&full_env_name);
    }

    #[tokio::test]
    async fn test_environment_provider_not_found() {
        let provider = EnvironmentProvider::default();

        let result = provider.get_secret("NONEXISTENT_SECRET").await;
        assert!(result.is_err());

        match result.unwrap_err() {
            SecretError::NotFound { name } => {
                assert_eq!(name, "NONEXISTENT_SECRET");
            }
            _ => panic!("Expected NotFound error"),
        }
    }
}

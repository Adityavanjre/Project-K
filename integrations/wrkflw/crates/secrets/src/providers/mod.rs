use crate::{SecretError, SecretResult};
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub mod env;
pub mod file;

// Cloud provider modules are planned for future implementation
// #[cfg(feature = "vault-provider")]
// pub mod vault;

// #[cfg(feature = "aws-provider")]
// pub mod aws;

// #[cfg(feature = "azure-provider")]
// pub mod azure;

// #[cfg(feature = "gcp-provider")]
// pub mod gcp;

/// A secret value with metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecretValue {
    /// The actual secret value
    value: String,
    /// Optional metadata about the secret
    pub metadata: HashMap<String, String>,
    /// When this secret was retrieved (for caching)
    pub retrieved_at: chrono::DateTime<chrono::Utc>,
}

impl SecretValue {
    /// Create a new secret value
    pub fn new(value: impl Into<String>) -> Self {
        Self {
            value: value.into(),
            metadata: HashMap::new(),
            retrieved_at: chrono::Utc::now(),
        }
    }

    /// Create a new secret value with metadata
    pub fn with_metadata(value: impl Into<String>, metadata: HashMap<String, String>) -> Self {
        Self {
            value: value.into(),
            metadata,
            retrieved_at: chrono::Utc::now(),
        }
    }

    /// Get the secret value
    pub fn value(&self) -> &str {
        &self.value
    }

    /// Check if this secret has expired based on TTL
    pub fn is_expired(&self, ttl_seconds: u64) -> bool {
        let now = chrono::Utc::now();
        let elapsed = now.signed_duration_since(self.retrieved_at);
        elapsed.num_seconds() > ttl_seconds as i64
    }
}

/// Trait for secret providers
#[async_trait]
pub trait SecretProvider: Send + Sync {
    /// Get a secret by name
    async fn get_secret(&self, name: &str) -> SecretResult<SecretValue>;

    /// List available secrets (optional, for providers that support it)
    async fn list_secrets(&self) -> SecretResult<Vec<String>> {
        Err(SecretError::internal(
            "list_secrets not supported by this provider",
        ))
    }

    /// Check if the provider is healthy/accessible
    async fn health_check(&self) -> SecretResult<()> {
        // Default implementation tries to get a non-existent secret
        // If it returns NotFound, the provider is healthy
        match self.get_secret("__health_check__").await {
            Err(SecretError::NotFound { .. }) => Ok(()),
            Err(e) => Err(e),
            Ok(_) => Ok(()), // Surprisingly, the health check secret exists
        }
    }

    /// Get the provider name
    fn name(&self) -> &str;
}

use thiserror::Error;

/// Result type for secret operations
pub type SecretResult<T> = Result<T, SecretError>;

/// Errors that can occur during secret operations
#[derive(Error, Debug)]
pub enum SecretError {
    #[error("Secret not found: {name}")]
    NotFound { name: String },

    #[error("Secret provider '{provider}' not found")]
    ProviderNotFound { provider: String },

    #[error("Authentication failed for provider '{provider}': {reason}")]
    AuthenticationFailed { provider: String, reason: String },

    #[error("Network error accessing secret provider: {0}")]
    NetworkError(String),

    #[error("Invalid secret configuration: {0}")]
    InvalidConfig(String),

    #[error("Encryption error: {0}")]
    EncryptionError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("JSON parsing error: {0}")]
    JsonError(#[from] serde_json::Error),

    #[error("YAML parsing error: {0}")]
    YamlError(#[from] serde_yaml::Error),

    #[error("Invalid secret value format: {0}")]
    InvalidFormat(String),

    #[error("Secret operation timeout")]
    Timeout,

    #[error("Permission denied accessing secret: {name}")]
    PermissionDenied { name: String },

    #[error("Internal error: {0}")]
    Internal(String),

    #[error("Invalid secret name: {reason}")]
    InvalidSecretName { reason: String },

    #[error("Secret value too large: {size} bytes (max: {max_size} bytes)")]
    SecretTooLarge { size: usize, max_size: usize },

    #[error("Rate limit exceeded: {0}")]
    RateLimitExceeded(String),
}

impl SecretError {
    /// Create a new NotFound error
    pub fn not_found(name: impl Into<String>) -> Self {
        Self::NotFound { name: name.into() }
    }

    /// Create a new ProviderNotFound error
    pub fn provider_not_found(provider: impl Into<String>) -> Self {
        Self::ProviderNotFound {
            provider: provider.into(),
        }
    }

    /// Create a new AuthenticationFailed error
    pub fn auth_failed(provider: impl Into<String>, reason: impl Into<String>) -> Self {
        Self::AuthenticationFailed {
            provider: provider.into(),
            reason: reason.into(),
        }
    }

    /// Create a new InvalidConfig error
    pub fn invalid_config(msg: impl Into<String>) -> Self {
        Self::InvalidConfig(msg.into())
    }

    /// Create a new Internal error
    pub fn internal(msg: impl Into<String>) -> Self {
        Self::Internal(msg.into())
    }
}

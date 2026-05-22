// Copyright 2024 wrkflw contributors
// SPDX-License-Identifier: MIT

//! Input validation utilities for secrets management

use crate::{SecretError, SecretResult};
use regex::Regex;

/// Maximum allowed secret value size (1MB)
pub const MAX_SECRET_SIZE: usize = 1024 * 1024;

/// Maximum allowed secret name length
pub const MAX_SECRET_NAME_LENGTH: usize = 255;

lazy_static::lazy_static! {
    /// Valid secret name pattern: alphanumeric, underscores, hyphens, dots
    static ref SECRET_NAME_PATTERN: Regex = Regex::new(r"^[a-zA-Z0-9_.-]+$").unwrap();
}

/// Validate a secret name
pub fn validate_secret_name(name: &str) -> SecretResult<()> {
    if name.is_empty() {
        return Err(SecretError::InvalidSecretName {
            reason: "Secret name cannot be empty".to_string(),
        });
    }

    if name.len() > MAX_SECRET_NAME_LENGTH {
        return Err(SecretError::InvalidSecretName {
            reason: format!(
                "Secret name too long: {} characters (max: {})",
                name.len(),
                MAX_SECRET_NAME_LENGTH
            ),
        });
    }

    if !SECRET_NAME_PATTERN.is_match(name) {
        return Err(SecretError::InvalidSecretName {
            reason: "Secret name can only contain letters, numbers, underscores, hyphens, and dots"
                .to_string(),
        });
    }

    // Check for potentially dangerous patterns
    if name.starts_with('.') || name.ends_with('.') {
        return Err(SecretError::InvalidSecretName {
            reason: "Secret name cannot start or end with a dot".to_string(),
        });
    }

    if name.contains("..") {
        return Err(SecretError::InvalidSecretName {
            reason: "Secret name cannot contain consecutive dots".to_string(),
        });
    }

    // Reserved names
    let reserved_names = [
        "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8",
        "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
    ];

    if reserved_names.contains(&name.to_uppercase().as_str()) {
        return Err(SecretError::InvalidSecretName {
            reason: format!("'{}' is a reserved name", name),
        });
    }

    Ok(())
}

/// Validate a secret value
pub fn validate_secret_value(value: &str) -> SecretResult<()> {
    let size = value.len();

    if size > MAX_SECRET_SIZE {
        return Err(SecretError::SecretTooLarge {
            size,
            max_size: MAX_SECRET_SIZE,
        });
    }

    // Check for null bytes which could cause issues
    if value.contains('\0') {
        return Err(SecretError::InvalidFormat(
            "Secret value cannot contain null bytes".to_string(),
        ));
    }

    Ok(())
}

/// Validate a provider name
pub fn validate_provider_name(name: &str) -> SecretResult<()> {
    if name.is_empty() {
        return Err(SecretError::InvalidConfig(
            "Provider name cannot be empty".to_string(),
        ));
    }

    if name.len() > 64 {
        return Err(SecretError::InvalidConfig(format!(
            "Provider name too long: {} characters (max: 64)",
            name.len()
        )));
    }

    if !name
        .chars()
        .all(|c| c.is_alphanumeric() || c == '_' || c == '-')
    {
        return Err(SecretError::InvalidConfig(
            "Provider name can only contain letters, numbers, underscores, and hyphens".to_string(),
        ));
    }

    Ok(())
}

/// Sanitize input for logging to prevent log injection attacks
pub fn sanitize_for_logging(input: &str) -> String {
    input
        .chars()
        .map(|c| match c {
            '\n' | '\r' | '\t' => ' ',
            c if c.is_control() => '?',
            c => c,
        })
        .collect()
}

/// Check if a string might be a secret based on common patterns
pub fn looks_like_secret(value: &str) -> bool {
    if value.len() < 8 {
        return false;
    }

    // Check for high entropy (random-looking strings)
    let unique_chars: std::collections::HashSet<char> = value.chars().collect();
    let entropy_ratio = unique_chars.len() as f64 / value.len() as f64;

    if entropy_ratio > 0.6 && value.len() > 16 {
        return true;
    }

    // Check for common secret patterns
    let secret_patterns = [
        r"^[A-Za-z0-9+/=]{40,}$", // Base64-like
        r"^[a-fA-F0-9]{32,}$",    // Hex strings
        r"^[A-Z0-9]{20,}$",       // All caps alphanumeric
        r"^sk_[a-zA-Z0-9_-]+$",   // Stripe-like keys
        r"^pk_[a-zA-Z0-9_-]+$",   // Public keys
        r"^rk_[a-zA-Z0-9_-]+$",   // Restricted keys
    ];

    for pattern in &secret_patterns {
        if let Ok(regex) = Regex::new(pattern) {
            if regex.is_match(value) {
                return true;
            }
        }
    }

    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_secret_name() {
        // Valid names
        assert!(validate_secret_name("API_KEY").is_ok());
        assert!(validate_secret_name("database-password").is_ok());
        assert!(validate_secret_name("service.token").is_ok());
        assert!(validate_secret_name("GITHUB_TOKEN_123").is_ok());

        // Invalid names
        assert!(validate_secret_name("").is_err());
        assert!(validate_secret_name("name with spaces").is_err());
        assert!(validate_secret_name("name/with/slashes").is_err());
        assert!(validate_secret_name(".hidden").is_err());
        assert!(validate_secret_name("ending.").is_err());
        assert!(validate_secret_name("double..dot").is_err());
        assert!(validate_secret_name("CON").is_err());
        assert!(validate_secret_name(&"a".repeat(300)).is_err());
    }

    #[test]
    fn test_validate_secret_value() {
        // Valid values
        assert!(validate_secret_value("short_secret").is_ok());
        assert!(validate_secret_value("").is_ok()); // Empty is allowed
        assert!(validate_secret_value(&"a".repeat(1000)).is_ok());

        // Invalid values
        assert!(validate_secret_value(&"a".repeat(MAX_SECRET_SIZE + 1)).is_err());
        assert!(validate_secret_value("secret\0with\0nulls").is_err());
    }

    #[test]
    fn test_validate_provider_name() {
        // Valid names
        assert!(validate_provider_name("env").is_ok());
        assert!(validate_provider_name("file").is_ok());
        assert!(validate_provider_name("aws-secrets").is_ok());
        assert!(validate_provider_name("vault_prod").is_ok());

        // Invalid names
        assert!(validate_provider_name("").is_err());
        assert!(validate_provider_name("name with spaces").is_err());
        assert!(validate_provider_name("name/with/slashes").is_err());
        assert!(validate_provider_name(&"a".repeat(100)).is_err());
    }

    #[test]
    fn test_sanitize_for_logging() {
        assert_eq!(sanitize_for_logging("normal text"), "normal text");
        assert_eq!(sanitize_for_logging("line\nbreak"), "line break");
        assert_eq!(sanitize_for_logging("tab\there"), "tab here");
        assert_eq!(sanitize_for_logging("carriage\rreturn"), "carriage return");
    }

    #[test]
    fn test_looks_like_secret() {
        // Should detect as secrets
        assert!(looks_like_secret("sk_test_abcdefghijklmnop1234567890"));
        assert!(looks_like_secret("abcdefghijklmnopqrstuvwxyz123456"));
        assert!(looks_like_secret("ABCDEF1234567890ABCDEF1234567890"));
        assert!(looks_like_secret(
            "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY3ODkw"
        ));

        // Should not detect as secrets
        assert!(!looks_like_secret("short"));
        assert!(!looks_like_secret("this_is_just_a_regular_variable_name"));
        assert!(!looks_like_secret("hello world this is plain text"));
    }
}

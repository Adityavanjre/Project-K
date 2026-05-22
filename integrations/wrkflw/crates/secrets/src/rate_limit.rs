// Copyright 2024 wrkflw contributors
// SPDX-License-Identifier: MIT

//! Rate limiting for secret access operations

use crate::{SecretError, SecretResult};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;

/// Rate limiter configuration
#[derive(Debug, Clone)]
pub struct RateLimitConfig {
    /// Maximum requests per time window
    pub max_requests: u32,
    /// Time window duration
    pub window_duration: Duration,
    /// Whether to enable rate limiting
    pub enabled: bool,
}

impl Default for RateLimitConfig {
    fn default() -> Self {
        Self {
            max_requests: 100,
            window_duration: Duration::from_secs(60), // 1 minute
            enabled: true,
        }
    }
}

/// Track requests for a specific key
#[derive(Debug)]
struct RequestTracker {
    requests: Vec<Instant>,
    first_request: Instant,
}

impl RequestTracker {
    fn new() -> Self {
        let now = Instant::now();
        Self {
            requests: Vec::new(),
            first_request: now,
        }
    }

    fn add_request(&mut self, now: Instant) {
        if self.requests.is_empty() {
            self.first_request = now;
        }
        self.requests.push(now);
    }

    fn cleanup_old_requests(&mut self, window_duration: Duration, now: Instant) {
        let cutoff = now - window_duration;
        self.requests.retain(|&req_time| req_time > cutoff);

        if let Some(&first) = self.requests.first() {
            self.first_request = first;
        }
    }

    fn request_count(&self) -> usize {
        self.requests.len()
    }
}

/// Rate limiter for secret access operations
pub struct RateLimiter {
    config: RateLimitConfig,
    trackers: Arc<RwLock<HashMap<String, RequestTracker>>>,
}

impl RateLimiter {
    /// Create a new rate limiter with the given configuration
    pub fn new(config: RateLimitConfig) -> Self {
        Self {
            config,
            trackers: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Check if a request should be allowed for the given key
    pub async fn check_rate_limit(&self, key: &str) -> SecretResult<()> {
        if !self.config.enabled {
            return Ok(());
        }

        let now = Instant::now();
        let mut trackers = self.trackers.write().await;

        // Clean up old requests for existing tracker
        if let Some(tracker) = trackers.get_mut(key) {
            tracker.cleanup_old_requests(self.config.window_duration, now);

            // Check if we're over the limit
            if tracker.request_count() >= self.config.max_requests as usize {
                let time_until_reset = self.config.window_duration - (now - tracker.first_request);
                return Err(SecretError::RateLimitExceeded(format!(
                    "Rate limit exceeded. Try again in {} seconds",
                    time_until_reset.as_secs()
                )));
            }

            // Add the current request
            tracker.add_request(now);
        } else {
            // Create new tracker and add first request
            let mut tracker = RequestTracker::new();
            tracker.add_request(now);
            trackers.insert(key.to_string(), tracker);
        }

        Ok(())
    }

    /// Reset rate limit for a specific key
    pub async fn reset_rate_limit(&self, key: &str) {
        let mut trackers = self.trackers.write().await;
        trackers.remove(key);
    }

    /// Clear all rate limit data
    pub async fn clear_all(&self) {
        let mut trackers = self.trackers.write().await;
        trackers.clear();
    }

    /// Get current request count for a key
    pub async fn get_request_count(&self, key: &str) -> usize {
        let trackers = self.trackers.read().await;
        trackers.get(key).map(|t| t.request_count()).unwrap_or(0)
    }

    /// Get rate limit configuration
    pub fn config(&self) -> &RateLimitConfig {
        &self.config
    }
}

impl Default for RateLimiter {
    fn default() -> Self {
        Self::new(RateLimitConfig::default())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::time::Duration;

    #[tokio::test]
    async fn test_rate_limit_basic() {
        let config = RateLimitConfig {
            max_requests: 3,
            window_duration: Duration::from_secs(1),
            enabled: true,
        };
        let limiter = RateLimiter::new(config);

        // First 3 requests should succeed
        assert!(limiter.check_rate_limit("test_key").await.is_ok());
        assert!(limiter.check_rate_limit("test_key").await.is_ok());
        assert!(limiter.check_rate_limit("test_key").await.is_ok());

        // 4th request should fail
        assert!(limiter.check_rate_limit("test_key").await.is_err());
    }

    #[tokio::test]
    async fn test_rate_limit_different_keys() {
        let config = RateLimitConfig {
            max_requests: 2,
            window_duration: Duration::from_secs(1),
            enabled: true,
        };
        let limiter = RateLimiter::new(config);

        // Different keys should have separate limits
        assert!(limiter.check_rate_limit("key1").await.is_ok());
        assert!(limiter.check_rate_limit("key1").await.is_ok());
        assert!(limiter.check_rate_limit("key2").await.is_ok());
        assert!(limiter.check_rate_limit("key2").await.is_ok());

        // Both keys should now be at their limit
        assert!(limiter.check_rate_limit("key1").await.is_err());
        assert!(limiter.check_rate_limit("key2").await.is_err());
    }

    #[tokio::test]
    async fn test_rate_limit_reset() {
        let config = RateLimitConfig {
            max_requests: 1,
            window_duration: Duration::from_secs(60), // Long window
            enabled: true,
        };
        let limiter = RateLimiter::new(config);

        // Use up the limit
        assert!(limiter.check_rate_limit("test_key").await.is_ok());
        assert!(limiter.check_rate_limit("test_key").await.is_err());

        // Reset and try again
        limiter.reset_rate_limit("test_key").await;
        assert!(limiter.check_rate_limit("test_key").await.is_ok());
    }

    #[tokio::test]
    async fn test_rate_limit_disabled() {
        let config = RateLimitConfig {
            max_requests: 1,
            window_duration: Duration::from_secs(1),
            enabled: false,
        };
        let limiter = RateLimiter::new(config);

        // All requests should succeed when disabled
        for _ in 0..10 {
            assert!(limiter.check_rate_limit("test_key").await.is_ok());
        }
    }

    #[tokio::test]
    async fn test_get_request_count() {
        let config = RateLimitConfig {
            max_requests: 5,
            window_duration: Duration::from_secs(1),
            enabled: true,
        };
        let limiter = RateLimiter::new(config);

        assert_eq!(limiter.get_request_count("test_key").await, 0);

        limiter.check_rate_limit("test_key").await.unwrap();
        assert_eq!(limiter.get_request_count("test_key").await, 1);

        limiter.check_rate_limit("test_key").await.unwrap();
        assert_eq!(limiter.get_request_count("test_key").await, 2);
    }
}

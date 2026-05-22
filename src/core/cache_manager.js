/**
 * KALI Cache Manager — v1.0 SOVEREIGN
 * Dynamic memory layer with TTL to prevent repetitive model queries.
 */

class CacheManager {
    constructor(defaultTtlMs = 300000) { // 5 minutes default TTL
        this.cache = new Map();
        this.defaultTtlMs = defaultTtlMs;
    }

    set(key, data, ttlMs = this.defaultTtlMs) {
        const expiresAt = Date.now() + ttlMs;
        this.cache.set(key, { data, expiresAt });
    }

    get(key) {
        const entry = this.cache.get(key);
        if (!entry) return null;

        if (Date.now() > entry.expiresAt) {
            this.cache.delete(key);
            return null; // Expired
        }

        return entry.data;
    }

    invalidate(key) {
        this.cache.delete(key);
    }

    clear() {
        this.cache.clear();
    }

    cleanup() {
        const now = Date.now();
        for (const [key, entry] of this.cache.entries()) {
            if (now > entry.expiresAt) {
                this.cache.delete(key);
            }
        }
    }
}

// Global Singleton Instance
const cacheInstance = new CacheManager();

// Run cleanup every minute
setInterval(() => cacheInstance.cleanup(), 60000);

module.exports = cacheInstance;

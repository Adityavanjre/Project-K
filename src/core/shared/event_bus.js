/**
 * KALI Event Bus — v1.0 SOVEREIGN
 * Centralized global event emitter to decouple core components.
 */

const { EventEmitter } = require('events');

class EventBus extends EventEmitter {
    constructor() {
        super();
        this.setMaxListeners(50); 
        this.eventCount = 0;
        this.lastReset = Date.now();
        this.throughput = 0;
        
        this.on('newListener', (event) => {
            const count = this.listenerCount(event);
            if (count >= 15) {
                console.warn(`[EventBus] CRITICAL WARNING: Event '${event}' has ${count + 1} listeners. Potential Memory Leak!`);
            }
        });

        // 🔱 THROUGHPUT TRACKING
        this.on('event:emitted', () => {
            this.eventCount++;
            const now = Date.now();
            if (now - this.lastReset > 1000) {
                this.throughput = this.eventCount;
                this.eventCount = 0;
                this.lastReset = now;
            }
        });
    }

    emit(event, ...args) {
        super.emit(event, ...args);
        super.emit('event:emitted', { event });
    }

    getThroughput() {
        return this.throughput;
    }
}

// Export as singleton
module.exports = new EventBus();

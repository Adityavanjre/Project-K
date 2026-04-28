//
//  Atomic.hpp
//  RxFoundation
//
//  Created by closure on 10/30/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Atomic_hpp
#define Atomic_hpp

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/Memory.hpp>
#include <RxFoundation/NotCopyableInterface.hpp>

#if DEPLOYMENT_TARGET_MACOSX

#include <libkern/OSAtomic.h>
#include <os/lock.h>
#if __HAS_DISPATCH__
#include <dispatch/dispatch.h>
#endif

#elif DEPLOYMENT_TARGET_ANDROID

#include <semaphore.h>
#include <pthread.h>

#endif

#include <mutex>

namespace Rx {
    class LockingInterface : public virtual NotCopyableInterface {
    public:
        LockingInterface() {}
        virtual ~LockingInterface() {}
    public:
        virtual bool tryLock() { return false; }
        virtual void lock() = 0;
        virtual void unlock() = 0;
    private:
    };
    
    template<typename T>
    class LockGuard : public NotCopyableInterface {
    public:
        LockGuard(T &_lockImpl) : _lockImpl(_lockImpl) {
            _lockImpl.lock();
        }
        ~LockGuard() {
            _lockImpl.unlock();
        }
        
        T *getLock() const RX_NOEXCEPT {
            return &_lockImpl;
        }
        
    private:
        T &_lockImpl;
    };
    
    template <typename T>
    class LockGuard<T *> : public NotCopyableInterface {
    public:
        LockGuard(T *_lockImpl) : _lockImpl(_lockImpl) {
            _lockImpl->lock();
        }
        ~LockGuard() {
            _lockImpl->unlock();
        }
    private:
        T *_lockImpl;
    };
    
    class SpinLock : public LockingInterface {
    public:
        bool tryLock() override;
        void lock() override;
        void unlock() override;
    protected:
        std::atomic_flag locked = ATOMIC_FLAG_INIT;
    };
    
    class MutexLock : public LockingInterface {
    public:
        MutexLock() RX_NOEXCEPT;
        virtual ~MutexLock();
        bool tryLock() override;
        void lock() override;
        void unlock() override;
        
        typedef pthread_mutex_t *native_handle_type;
        RX_INLINE_VISIBILITY native_handle_type getNativeHandle() RX_NOEXCEPT {
            return &_impl;
        }
    private:
        pthread_mutex_t _impl;
    };
    
    static_assert(std::is_nothrow_default_constructible<MutexLock>::value,
                  "the default constructor for Rx::MutexLock must be nothrow");
    
    class ConditionVariable {
    private:
#ifndef _LIBCPP_CXX03_LANG
        pthread_cond_t _condition = PTHREAD_COND_INITIALIZER;
#else
        pthread_cond_t _condition;
#endif
    public:
        RX_INLINE_VISIBILITY
#ifndef _LIBCPP_CXX03_LANG
        constexpr ConditionVariable() RX_NOEXCEPT = default;
#else
        ConditionVariable() RX_NOEXCEPT {
            _condition = (decltype(pthread_cond_t))PTHREAD_COND_INITIALIZER;
        }
#endif
        ~ConditionVariable();
        
        void notifyOne() RX_NOEXCEPT;
        void notifyAll() RX_NOEXCEPT;
        
        void wait(LockGuard<MutexLock> &lock) RX_NOEXCEPT;
    private:
        ConditionVariable(const ConditionVariable &) = delete;
        ConditionVariable(ConditionVariable &&) = delete;
        ConditionVariable& operator=(const ConditionVariable &) = delete;
    };
    
    static_assert(std::is_nothrow_default_constructible<ConditionVariable>::value,
                  "the default constructor for Rx::ConditionVariable must be nothrow");
    
    class ReadWriteLock : public NotCopyableInterface {
    public:
        ReadWriteLock() RX_NOEXCEPT;
        virtual ~ReadWriteLock();
        
        void lockRead() RX_NOEXCEPT;
        void unlockRead() RX_NOEXCEPT;
        bool tryLockRead() RX_NOEXCEPT;
        
        void lockWrite() RX_NOEXCEPT;
        void unlockWrite() RX_NOEXCEPT;
        bool tryLockWrite() RX_NOEXCEPT;
        
        bool isWriting() const RX_NOEXCEPT;
        bool isReading() const RX_NOEXCEPT;
        
    private:
        mutable MutexLock _mutex;
        ConditionVariable _condition;
        Int64 _reader;
        Int64 _writer;
        Int64 _pending;
    };
    
    class Semaphore {
        Semaphore(Semaphore &&value) = delete;
        Semaphore(const Semaphore &value) = delete;
        Semaphore &operator=(const Semaphore &value) = delete;
    public:
        Semaphore(Integer value = 0);
        ~Semaphore();
    public:
        void signal();
        bool wait(UInt64 timeout = ~0ull);
    private:
#if DEPLOYMENT_TARGET_MACOSX
        dispatch_object_t _impl;
#elif DEPLOYMENT_TARGET_ANDROID
        sem_t _impl;
#endif
    };
    
    struct __Atomics {
    private:
        __Atomics() {}
        ~__Atomics() {}
        __Atomics(const __Atomics &) = delete;
    public:
    };
    
#if DEPLOYMENT_TARGET_ANDROID
    struct AndroidAtomics : public __Atomics {
        static RX_INLINE_VISIBILITY Int32 InterlockedIncrement(volatile Int32 *Value) {
            return __sync_fetch_and_add(Value, 1) + 1;
        }
        
        static RX_INLINE_VISIBILITY Int64 InterlockedIncrement(volatile Int64 *Value) {
            return __sync_fetch_and_add(Value, 1) + 1;
        }
        
        static RX_INLINE_VISIBILITY Int32 InterlockedDecrement(volatile Int32 *Value) {
            return __sync_fetch_and_sub(Value, 1) - 1;
        }
        
        static RX_INLINE_VISIBILITY Int64 InterlockedDecrement(volatile Int64 *Value) {
            return __sync_fetch_and_sub(Value, 1) - 1;
        }
        
        static RX_INLINE_VISIBILITY Int32 InterlockedAdd(volatile Int32 *Value, Int32 Amount) {
            return __sync_fetch_and_add(Value, Amount);
        }
        
        static RX_INLINE_VISIBILITY Int64 InterlockedAdd(volatile Int64 *Value, Int64 Amount) {
            return __sync_fetch_and_add(Value, Amount);
        }
        
        static RX_INLINE_VISIBILITY Int32 InterlockedExchange(volatile Int32 *Value, Int32 Exchange) {
            return __sync_lock_test_and_set(Value,Exchange);
        }
        
        static RX_INLINE_VISIBILITY Int64 InterlockedExchange(volatile Int64 *Value, Int64 Exchange) {
            return __sync_lock_test_and_set(Value, Exchange);
        }
        
        static RX_INLINE_VISIBILITY void* InterlockedExchangePtr(void **Dest, void *Exchange) {
            return __sync_lock_test_and_set(Dest, Exchange);
        }
        
        static RX_INLINE_VISIBILITY Int32 InterlockedCompareExchange(volatile Int32 *Dest, Int32 Exchange, Int32 Comperand) {
            return __sync_val_compare_and_swap(Dest, Comperand, Exchange);
        }
        
#if __LP64__
        static RX_INLINE_VISIBILITY Int64 InterlockedCompareExchange(volatile Int64 *Dest, Int64 Exchange, Int64 Comperand) {
            return __sync_val_compare_and_swap(Dest, Comperand, Exchange);
        }
#endif
        
        static RX_INLINE_VISIBILITY void* InterlockedCompareExchangePointer(void **Dest, void *Exchange, void *Comperand) {
            return __sync_val_compare_and_swap(Dest, Comperand, Exchange);
        }
        
    };
    using Atomics = AndroidAtomics;
#elif DEPLOYMENT_TARGET_MACOSX
    
    struct DarwinAtomics : public __Atomics {
#pragma clang diagnsotic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        static RX_INLINE_VISIBILITY Int32 InterlockedIncrement(volatile Int32 *Value) {
            return (Int32)OSAtomicIncrement32Barrier((Int32 *)Value);
        }

        static RX_INLINE_VISIBILITY Int32 InterlockedDecrement(volatile Int32 *Value) {
            return (Int32)OSAtomicDecrement32Barrier((Int32 *)Value);
        }

        static RX_INLINE_VISIBILITY Int32 InterlockedAdd(volatile Int32 *Value, Int32 Amount) {
            return OSAtomicAdd32Barrier((Int32)Amount, (Int32 *)Value) - Amount;
        }

        static RX_INLINE_VISIBILITY Int32 InterlockedExchange(volatile Int32 *Value, Int32 Exchange) {
            Int32 RetVal;

            do {
                RetVal = *Value;
            }
            while (!OSAtomicCompareAndSwap32Barrier(RetVal, Exchange, (Int32 *) Value));

            return RetVal;
        }


        static RX_INLINE_VISIBILITY void *InterlockedExchangePtr( void* *Dest, void *Exchange) {
            void *RetVal;

            do {
                RetVal = *Dest;
            }
            while (!OSAtomicCompareAndSwapPtrBarrier(RetVal, Exchange, Dest));

            return RetVal;
        }

        static RX_INLINE_VISIBILITY Int32 InterlockedCompareExchange(volatile Int32 *Dest, Int32 Exchange, Int32 Comparand) {
            Int32 RetVal;

            do {
                if (OSAtomicCompareAndSwap32Barrier(Comparand, Exchange, (Int32 *) Dest)) {
                    return Comparand;
                }
                RetVal = *Dest;
            }
            while (RetVal == Comparand);

            return RetVal;
        }

        static RX_INLINE_VISIBILITY Int64 InterlockedCompareExchange(volatile Int64 *Dest, Int64 Exchange, Int64 Comparand) {
            Int64 RetVal;

            do {
                if (OSAtomicCompareAndSwap64Barrier(Comparand, Exchange, (Int64 *) Dest)) {
                    return Comparand;
                }
                RetVal = *Dest;
            }
            while (RetVal == Comparand);

            return RetVal;
        }


        static RX_INLINE_VISIBILITY Int64 InterlockedExchange(volatile Int64 *Value, Int64 Exchange) {
            Int64 RetVal;

            do {
                RetVal = *Value;
            }
            while (!OSAtomicCompareAndSwap64Barrier(RetVal, Exchange, (Int64 *) Value));

            return RetVal;
        }

        static RX_INLINE_VISIBILITY Int64 InterlockedIncrement(volatile Int64 *Value) {
            return (Int64)OSAtomicIncrement64Barrier((Int64 *)Value);
        }

        static RX_INLINE_VISIBILITY Int64 InterlockedDecrement(volatile Int64 *Value) {
            return (Int64)OSAtomicDecrement64Barrier((Int64 *)Value);
        }

        static RX_INLINE_VISIBILITY Int64 InterlockedAdd(volatile Int64 *Value, Int64 Amount) {
            return OSAtomicAdd64Barrier((Int64)Amount, (Int64 *)Value) - Amount;
        }

        static RX_INLINE_VISIBILITY void *InterlockedCompareExchangePointer( void* *Dest, void *Exchange, void *Comparand) {
            void *RetVal;

            do {
                if (OSAtomicCompareAndSwapPtrBarrier(Comparand, Exchange, Dest)) {
                    return Comparand;
                }
                RetVal = *Dest;
            }
            while (RetVal == Comparand);

            return RetVal;
        }
#pragma clang diagnsotic pop
    };
    using Atomics = DarwinAtomics;
#endif
}

#endif /*Atomic_hpp*/

//
//  Port.hpp
//  RxFoundation
//
//  Created by closure on 5/9/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef Port_hpp
#define Port_hpp

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/CrashReporter.hpp>
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
#include <sys/param.h>
#include <mach/mach.h>
#elif DEPLOYMENT_TARGET_WINDOWS || TARGET_OS_CYGWIN
#include <process.h>
#endif

namespace Rx {
    // In order to reuse most of the code across Mach and Windows v1 RunLoopSources, we define a
    // simple abstraction layer spanning Mach ports and Windows HANDLES
#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI
    
    template <typename T>
    class PortBase {
    public:
        using value_type = T;
        PortBase() = delete;
        
        explicit PortBase(value_type value) RX_NOEXCEPT : _value(value) {}
        PortBase(PortBase &&value) RX_NOEXCEPT : _value(value._value) {
            value._value = value_type();
        }
        
        virtual ~PortBase() {}
        
        RX_INLINE_VISIBILITY bool operator==(const PortBase<T> &value) const RX_NOEXCEPT {
            return getValue() == value.getValue();
        }
        
        RX_INLINE_VISIBILITY const value_type &getValue() const RX_NOEXCEPT {
            return _value;
        }
        
        RX_INLINE_VISIBILITY value_type getValue() RX_NOEXCEPT {
            return _value;
        }
        
        RX_INLINE_VISIBILITY operator value_type() const RX_NOEXCEPT {
            return getValue();
        }
        
        RX_INLINE_VISIBILITY void swap(PortBase<T> &value) RX_NOEXCEPT {
            _value = value.getValue();
            value._value = value_type();
        }
        
    protected:
        value_type _value;
    };
    
    class Port : public PortBase<mach_port_t> {
    public:
        static Port Null;
        static Port allocate();
        static uint32_t processPortCount(void);
        
        Port(value_type _ = value_type());
        Port(const Port &_);
        Port(Port &&_);
        ~Port();
        
        void free() RX_NOEXCEPT {
            if (getValue() != Null.getValue()) {
                mach_port_destroy(mach_task_self(), getValue());
                _value = Null.getValue();
            }
        }
        
        operator bool() const {
            return getValue() != Null.getValue();
        }
        
    public:
        uint32_t send(uint32_t msg_id, OptionFlags options, uint32_t timeout);
        

    protected:
        friend class PortSet;
    };
    
    class PortSet : public Port {
    public:
        static PortSet allocate();
        
        PortSet(value_type _ = value_type());
        PortSet(PortSet &&_);
        ~PortSet();
        
        kern_return_t insert(const Port &port);
        kern_return_t remove(const Port &port);
        void swap(PortSet &);
    private:
    };
    
#elif DEPLOYMENT_TARGET_WINDOWS || TARGET_OS_CYGWIN
    
    class Port : public PortBase<HANDLE> {
    public:
        static Port Null;
    };
#define CFPORT_NULL NULL
    
    // A simple dynamic array of HANDLEs, which grows to a high-water mark
    typedef struct ___CFPortSet {
        uint16_t	used;
        uint16_t	size;
        HANDLE	*handles;
        CFLock_t lock;		// insert and remove must be thread safe, like the Mach calls
    } *__CFPortSet;
    
    CF_INLINE __CFPort __CFPortAllocate(void) {
        return CreateEventA(NULL, true, false, NULL);
    }
    
    CF_INLINE void __CFPortFree(__CFPort port) {
        CloseHandle(port);
    }
#endif
}

#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_EMBEDDED || DEPLOYMENT_TARGET_EMBEDDED_MINI || DEPLOYMENT_TARGET_WINDOWS || TARGET_OS_CYGWIN
template <>
struct std::less<Rx::Port> {
    bool operator()(const Rx::Port &lhs, const Rx::Port &rhs) const {
        return lhs.getValue() < rhs.getValue();
    }
};

#endif

#endif /* Port_hpp */

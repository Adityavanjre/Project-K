//
//  RxBase.hpp
//  RxFoundation
//
//  Created by closure on 9/24/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef RxBase_h
#define RxBase_h

#include <RxFoundation/DeploymentAvailability.hpp>
#include <RxFoundation/RxBaseMacro.hpp>
#include <sys/types.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#include <setjmp.h>
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdint.h>

#if DEPLOYMENT_TARGET_ANDROID

#include <wctype.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <utime.h>

typedef float Float32;
typedef double Float64;

#elif DEPLOYMENT_TARGET_MACOSX

#include <MacTypes.h>

#endif

#if defined(__STDC_VERSION__) && (199901L <= __STDC_VERSION__)

#include <inttypes.h>
#include <stdbool.h>

#endif

namespace Rx {
#if   (TARGET_OS_MAC)||(TARGET_OS_IPHONE)
    
#define MACOSX
    
#elif TARGET_OS_WIN
#define YES 1
#define NO  0
#endif
    
#if __LP64__
    typedef unsigned long long TypeID;
    typedef unsigned long long OptionFlags;
    typedef unsigned long long HashCode;
    typedef signed long long Index;
#else
    typedef unsigned long TypeID;
    typedef unsigned long OptionFlags;
    typedef unsigned long HashCode;
    typedef signed long Index;
#endif
    
    typedef double TimeInterval;
    
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
#ifndef YES
#define YES (BOOL)1
#endif
#ifndef NO
#define NO (BOOL)0
#endif
#ifndef nill
#define nill nil
#endif
    
#if __STDC_VERSION__ < 11
    
    typedef unsigned char                   UInt8;
    typedef signed char                     SInt8;
    typedef unsigned short                  UInt16;
    typedef signed short                    SInt16;
    
#if __LP64__
    typedef unsigned int                    UInt32;
    typedef signed int                      SInt32;
    typedef unsigned long long              UInt64;
    typedef long long                       SInt64;
#else
    typedef unsigned int                    UInt32;
    typedef signed int                      SInt32;
    typedef unsigned long long              UInt64;
    typedef long long                       SInt64;
#endif
    typedef SInt8                           Int8;
    typedef SInt16                          Int16;
    typedef SInt32                          Int32;
    typedef SInt64                          Int64;
    
    typedef UInt32                          UnicodeScalarValue;
    typedef UInt32                          UTF32Char;
    typedef UInt16                          UniChar;
    typedef UInt16                          UTF16Char;
    typedef UInt8                           UTF8Char;
    typedef UniChar *                       UniCharPtr;
    typedef unsigned long                   UniCharCount;
    typedef UniCharCount *                  UniCharCountPtr;
    
#endif
    
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
    typedef Int64 Integer;
    typedef UInt64 UInteger;
    typedef double Float;
#else
    typedef Int32 Integer;
    typedef UInt32 UInteger;
    typedef float Float;
#endif
    
    typedef TimeInterval AbsoluteTime;
    
    typedef uintptr_t Pointer;
    
    typedef enum {
        WriteFileDefault = 0,
        WriteFileAutomatically = 1
    } WriteFileMode;
    
    enum {
        NotFound = -1
    };
    
    enum {
        CompareLessThan = -1,
        CompareEqualTo = 0,
        CompareGreaterThan = 1
    };
    typedef Integer ComparisonResult;
    
    typedef ComparisonResult (*ComparatorFunction)(const void *val1, const void *val2, void *context);
    
    typedef struct Range {
        Range(Index loc = 0, Index len = 0) RX_NOEXCEPT :
        location(loc), length(len) {
        }
        
        Range(const Range &) RX_NOEXCEPT = default;
        Range(Range &&) RX_NOEXCEPT = default;
        
        Range operator=(const Range &rhs) RX_NOEXCEPT {
            location = rhs.location;
            length = rhs.length;
            return *this;
        }
        
        bool operator==(const Range &rhs) const RX_NOEXCEPT {
            return location == rhs.location && length == rhs.length;
        }
        
        Index location;
        Index length;
    } Range;
    
    RX_INLINE Range RxMakeRange(Index location, Index length) RX_NOEXCEPT {
        Range range;
        range.location = location;
        range.length = length;
        return range;
    }
    
    typedef RX_ENUM(Integer, ComparisonOrder) {OrderedAscending = -1L, OrderedSame, OrderedDescending};
}

#include <RxFoundation/Memory.hpp>
#include <RxFoundation/type_traits.hpp>

#if DEPLOYMENT_TARGET_MACOSX || DEPLOYMENT_TARGET_IPHONEOS
#define __HAS_DISPATCH__ 1
#else
#define __HAS_DISPATCH__ 0
#endif

#if DEPLOYMENT_TARGET_ANDROID

#include <android/api-level.h>
typedef	int		kern_return_t;
#define KERN_SUCCESS			0

#define KERN_INVALID_ADDRESS		1
/* Specified address is not currently valid.
 */

#define KERN_PROTECTION_FAILURE		2
/* Specified memory is valid, but does not permit the
 * required forms of access.
 */

#define KERN_NO_SPACE			3
/* The address range specified is already in use, or
 * no address range of the size specified could be
 * found.
 */

#define KERN_INVALID_ARGUMENT		4
/* The function requested was not applicable to this
 * type of argument, or an argument is invalid
 */

#define KERN_FAILURE			5
/* The function could not be performed.  A catch-all.
 */

#define KERN_RESOURCE_SHORTAGE		6
/* A system resource could not be allocated to fulfill
 * this request.  This failure may not be permanent.
 */

#define KERN_NOT_RECEIVER		7
/* The task in question does not hold receive rights
 * for the port argument.
 */

#define KERN_NO_ACCESS			8
/* Bogus access restriction.
 */

#define KERN_MEMORY_FAILURE		9
/* During a page fault, the target address refers to a
 * memory object that has been destroyed.  This
 * failure is permanent.
 */

#define KERN_MEMORY_ERROR		10
/* During a page fault, the memory object indicated
 * that the data could not be returned.  This failure
 * may be temporary; future attempts to access this
 * same data may succeed, as defined by the memory
 * object.
 */

#define	KERN_ALREADY_IN_SET		11
/* The receive right is already a member of the portset.
 */

#define KERN_NOT_IN_SET			12
/* The receive right is not a member of a port set.
 */

#define KERN_NAME_EXISTS		13
/* The name already denotes a right in the task.
 */

#define KERN_ABORTED			14
/* The operation was aborted.  Ipc code will
 * catch this and reflect it as a message error.
 */

#define KERN_INVALID_NAME		15
/* The name doesn't denote a right in the task.
 */

#define	KERN_INVALID_TASK		16
/* Target task isn't an active task.
 */

#define KERN_INVALID_RIGHT		17
/* The name denotes a right, but not an appropriate right.
 */

#define KERN_INVALID_VALUE		18
/* A blatant range error.
 */

#define	KERN_UREFS_OVERFLOW		19
/* Operation would overflow limit on user-references.
 */

#define	KERN_INVALID_CAPABILITY		20
/* The supplied (port) capability is improper.
 */

#define KERN_RIGHT_EXISTS		21
/* The task already has send or receive rights
 * for the port under another name.
 */

#define	KERN_INVALID_HOST		22
/* Target host isn't actually a host.
 */

#define KERN_MEMORY_PRESENT		23
/* An attempt was made to supply "precious" data
 * for memory that is already present in a
 * memory object.
 */

#define KERN_MEMORY_DATA_MOVED		24
/* A page was requested of a memory manager via
 * memory_object_data_request for an object using
 * a MEMORY_OBJECT_COPY_CALL strategy, with the
 * VM_PROT_WANTS_COPY flag being used to specify
 * that the page desired is for a copy of the
 * object, and the memory manager has detected
 * the page was pushed into a copy of the object
 * while the kernel was walking the shadow chain
 * from the copy to the object. This error code
 * is delivered via memory_object_data_error
 * and is handled by the kernel (it forces the
 * kernel to restart the fault). It will not be
 * seen by users.
 */

#define KERN_MEMORY_RESTART_COPY	25
/* A strategic copy was attempted of an object
 * upon which a quicker copy is now possible.
 * The caller should retry the copy using
 * vm_object_copy_quickly. This error code
 * is seen only by the kernel.
 */

#define KERN_INVALID_PROCESSOR_SET	26
/* An argument applied to assert processor set privilege
 * was not a processor set control port.
 */

#define KERN_POLICY_LIMIT		27
/* The specified scheduling attributes exceed the thread's
 * limits.
 */

#define KERN_INVALID_POLICY		28
/* The specified scheduling policy is not currently
 * enabled for the processor set.
 */

#define KERN_INVALID_OBJECT		29
/* The external memory manager failed to initialize the
 * memory object.
 */

#define KERN_ALREADY_WAITING		30
/* A thread is attempting to wait for an event for which
 * there is already a waiting thread.
 */

#define KERN_DEFAULT_SET		31
/* An attempt was made to destroy the default processor
 * set.
 */

#define KERN_EXCEPTION_PROTECTED	32
/* An attempt was made to fetch an exception port that is
 * protected, or to abort a thread while processing a
 * protected exception.
 */

#define KERN_INVALID_LEDGER		33
/* A ledger was required but not supplied.
 */

#define KERN_INVALID_MEMORY_CONTROL	34
/* The port was not a memory cache control port.
 */

#define KERN_INVALID_SECURITY		35
/* An argument supplied to assert security privilege
 * was not a host security port.
 */

#define KERN_NOT_DEPRESSED		36
/* thread_depress_abort was called on a thread which
 * was not currently depressed.
 */

#define KERN_TERMINATED			37
/* Object has been terminated and is no longer available
 */

#define KERN_LOCK_SET_DESTROYED		38
/* Lock set has been destroyed and is no longer available.
 */

#define KERN_LOCK_UNSTABLE		39
/* The thread holding the lock terminated before releasing
 * the lock
 */

#define KERN_LOCK_OWNED			40
/* The lock is already owned by another thread
 */

#define KERN_LOCK_OWNED_SELF		41
/* The lock is already owned by the calling thread
 */

#define KERN_SEMAPHORE_DESTROYED	42
/* Semaphore has been destroyed and is no longer available.
 */

#define KERN_RPC_SERVER_TERMINATED	43
/* Return from RPC indicating the target server was
 * terminated before it successfully replied
 */

#define KERN_RPC_TERMINATE_ORPHAN	44
/* Terminate an orphaned activation.
 */

#define KERN_RPC_CONTINUE_ORPHAN	45
/* Allow an orphaned activation to continue executing.
 */

#define	KERN_NOT_SUPPORTED		46
/* Empty thread activation (No thread linked to it)
 */

#define	KERN_NODE_DOWN			47
/* Remote node down or inaccessible.
 */

#define KERN_NOT_WAITING		48
/* A signalled thread was not actually waiting. */

#define	KERN_OPERATION_TIMED_OUT        49
/* Some thread-oriented operation (semaphore_wait) timed out
 */

#define KERN_CODESIGN_ERROR		50
/* During a page fault, indicates that the page was rejected
 * as a result of a signature check.
 */

#define KERN_POLICY_STATIC		51
/* The requested property cannot be changed at this time.
 */

#define KERN_INSUFFICIENT_BUFFER_SIZE	52
/* The provided buffer is of insufficient size for the requested data.
 */

#define	KERN_RETURN_MAX			0x100
/* Maximum return value allowable
 */
#endif

#endif /* RxBase_h */

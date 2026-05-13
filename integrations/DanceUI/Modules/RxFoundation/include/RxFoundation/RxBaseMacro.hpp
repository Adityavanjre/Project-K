//
//  RxBaseMacro.hpp
//  RxFoundation
//
//  Created by closure on 11/30/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef RxBaseMacro_h
#define RxBaseMacro_h

#if defined(__cplusplus)
#define RxExtern extern "C"
#else
#define RxExtern extern
#endif

#ifndef RXExport
#if TARGET_OS_WIN32
#if !defined(RX_EXPORT)
#if defined(RX_BUILDING_RS) && defined(__cplusplus)
#define RX_EXPORT extern "C" __declspec(dllexport)
#elif defined(RX_BUILDING_RS) && !defined(__cplusplus)
#define RX_EXPORT extern __declspec(dllexport)
#elif defined(__cplusplus)
#define RX_EXPORT extern "C" __declspec(dllimport)
#else
#define RX_EXPORT extern __declspec(dllimport)
#endif
#endif
#else
#define RX_EXPORT RxExtern
#endif
#define RxExport RX_EXPORT
#endif

#if !defined(RX_INLINE)
#if defined(__GNUC__)
#define RX_INLINE __inline__ __attribute__((always_inline))
#elif defined(__MWERKS__) || defined(__cplusplus)
#define RX_INLINE inline
#elif defined(_MSC_VER)
#define RX_INLINE  __inline
#elif TARGET_OS_WIN32
#define RX_INLINE __inline__
#endif
#endif

#ifndef RX_DISABLE_VISIBILITY_ANNOTATIONS
//#define RX_DISABLE_VISIBILITY_ANNOTATIONS
#endif

#if !defined(RX_INLINE_VISIBILITY)
    #if !defined(RX_DISABLE_VISIBILITY_ANNOTATIONS)
        #define RX_INLINE_VISIBILITY __attribute__ ((__visibility__("hidden"), __always_inline__))
    #else
        #define RX_INLINE_VISIBILITY RX_INLINE
    #endif
#endif

#ifndef RxInline
#define RxInline RX_INLINE
#endif

#ifndef RxPrivate
#define RxPrivate  __private_extern__
#endif

#if (__cplusplus && __cplusplus >= 201103L && (__has_extension(cxx_strong_enums) || __has_feature(objc_fixed_enum))) || (!__cplusplus && __has_feature(objc_fixed_enum))
#define RX_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#if (__cplusplus)
#define RX_OPTIONS(_type, _name) _type _name; enum : _type
#else
#define RX_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif
#else
#define RX_ENUM(_type, _name) _type _name; enum
#define RX_OPTIONS(_type, _name) _type _name; enum
#endif

#if TARGET_OS_WIN32
#define nil ((void*)0)
#elif TARGET_OS_MAC
#include <MacTypes.h>
#ifndef __MACTYPES__
#define nil ((void*)0)
#endif
#elif __ANDROID_NDK__
#endif

#ifndef RxCheck
#define RxCheck(x) assert(x && #x)
#endif

#define __RX_COMPILE_YEAR__	(__DATE__[7] * 1000 + __DATE__[8] * 100 + __DATE__[9] * 10 + __DATE__[10] - 53328)
#define __RX_COMPILE_MONTH__	((__DATE__[1] + __DATE__[2] == 207) ? 1 : \
(__DATE__[1] + __DATE__[2] == 199) ? 2 : \
(__DATE__[1] + __DATE__[2] == 211) ? 3 : \
(__DATE__[1] + __DATE__[2] == 226) ? 4 : \
(__DATE__[1] + __DATE__[2] == 218) ? 5 : \
(__DATE__[1] + __DATE__[2] == 227) ? 6 : \
(__DATE__[1] + __DATE__[2] == 225) ? 7 : \
(__DATE__[1] + __DATE__[2] == 220) ? 8 : \
(__DATE__[1] + __DATE__[2] == 213) ? 9 : \
(__DATE__[1] + __DATE__[2] == 215) ? 10 : \
(__DATE__[1] + __DATE__[2] == 229) ? 11 : \
(__DATE__[1] + __DATE__[2] == 200) ? 12 : 0)
#define __RX_COMPILE_DAY__	(__DATE__[4] * 10 + __DATE__[5] - (__DATE__[4] == ' ' ? 368 : 528))
#define __RX_COMPILE_DATE__	(__RX_COMPILE_YEAR__ * 10000 + __RX_COMPILE_MONTH__ * 100 + __RX_COMPILE_DAY__)

#define __RX_COMPILE_HOUR__	(__TIME__[0] * 10 + __TIME__[1] - 528)
#define __RX_COMPILE_MINUTE__	(__TIME__[3] * 10 + __TIME__[4] - 528)
#define __RX_COMPILE_SECOND__	(__TIME__[6] * 10 + __TIME__[7] - 528)
#define __RX_COMPILE_TIME__	(__RX_COMPILE_HOUR__ * 10000 + __RX_COMPILE_MINUTE__ * 100 + __RX_COMPILE_SECOND__)

#define __RX_COMPILE_SECOND_OF_DAY__	(__RX_COMPILE_HOUR__ * 3600 + __RX_COMPILE_MINUTE__ * 60 + __RX_COMPILE_SECOND__)

// __RX_COMPILE_DAY_OF_EPOCH__ works within Gregorian years 2001 - 2099; the epoch is of course CF's epoch
#define __RX_COMPILE_DAY_OF_EPOCH__	((__RX_COMPILE_YEAR__ - 2001) * 365 + (__RX_COMPILE_YEAR__ - 2001) / 4 \
+ ((__DATE__[1] + __DATE__[2] == 207) ? 0 : \
(__DATE__[1] + __DATE__[2] == 199) ? 31 : \
(__DATE__[1] + __DATE__[2] == 211) ? 59 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 226) ? 90 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 218) ? 120 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 227) ? 151 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 225) ? 181 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 220) ? 212 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 213) ? 243 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 215) ? 273 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 229) ? 304 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
(__DATE__[1] + __DATE__[2] == 200) ? 334 + (__RX_COMPILE_YEAR__ % 4 == 0) : \
365 + (__RX_COMPILE_YEAR__ % 4 == 0)) \
+ __RX_COMPILE_DAY__)

#ifndef  __RX_INIT_ROUTINE
#define  __RX_INIT_ROUTINE(s) __attribute__ ((constructor((s))))
#endif

#ifndef  __RX_FINAL_ROUTINE
#define  __RX_FINAL_ROUTINE(s) __attribute__ ((destructor((s))))
#endif

#ifndef  RX_INIT_ROUTINE
#define  RX_INIT_ROUTINE __attribute__ ((constructor))
#endif

#ifndef  RX_FINAL_ROUTINE
#define  RX_FINAL_ROUTINE __attribute__ ((destructor))
#endif

#if DEPLOYMENT_TARGET_WINDOWS
#define RX_STACK_BUFFER_DECL(T, N, C) T *N = (T *)_alloca((C) * sizeof(T))
#else
#define RX_STACK_BUFFER_DECL(T, N, C) T N[C]
#endif

#ifndef LLVM_ENABLE_ABI_BREAKING_CHECKS
#define LLVM_ENABLE_ABI_BREAKING_CHECKS 1
#endif

#ifndef _LIBCPP_HAS_NO_NOEXCEPT
#  define RX_NOEXCEPT noexcept
#  define RX_NOEXCEPT_(x) noexcept(x)
#else
#  define RX_NOEXCEPT throw()
#  define RX_NOEXCEPT_(x)
#endif

#endif /* RxBaseMacro_h */

// Copyright (c) 2025 ByteDance Ltd. and/or its affiliates
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <RxCoreComponents/RxCoreComponents.h>
#include <RxCoreComponents/metamacros.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RxAnnotationSegmentName "__DATA"

#define RxAnnotationEncodingAction "__ACTION__"

/// Xcode 13.3 don't handle __VA_OPT__ correctly.
/// mark RX_VA_OPT_SUPPORTED as 0 to activate builtin logic.
#if defined(RX_VA_OPT_SUPPORTED)
#undefine RX_VA_OPT_SUPPORTED
#endif

#define RX_VA_OPT_SUPPORTED     0

#ifdef DEBUG
#define __RX_ANNOTATION_DEBUG__
#else
#endif

#undef __RX_ANNOTATION_DEBUG__

typedef __unsafe_unretained NSString *RxAnnotationLiteralString;

typedef struct {
    const RxAnnotationLiteralString *category;
    const RxAnnotationLiteralString *collection;
    const RxAnnotationLiteralString *name;
#ifdef __RX_ANNOTATION_DEBUG__
    const RxAnnotationLiteralString *file;
#endif
    const void *value;
    const char **encoding;
#ifdef __RX_ANNOTATION_DEBUG__
    const uint64_t line;
#endif
} rx_annotation_entry;

#if __has_feature(address_sanitizer)

typedef uintptr_t *uptr;

struct __asan_global_source_location {
    const char *filename;
    int line_no;
    int column_no;
};

// This structure describes an instrumented global variable.
struct __asan_global {
    uptr beg;                // The address of the global.
    uptr size;               // The original size of the global.
    uptr size_with_redzone;  // The size with the redzone.
    const char *name;        // Name as a C string.
    const char *module_name; // Module name as a C string. This pointer is a
    // unique identifier of a module.
    uptr has_dynamic_init;   // Non-zero if the global has dynamic initializer.
    struct __asan_global_source_location *location;  // Source location of a global,
    // or NULL if it is unknown.
    uptr odr_indicator;      // The address of the ODR indicator symbol.
};

typedef struct {
    const RxAnnotationLiteralString *category;
    const RxAnnotationLiteralString *collection;
    const RxAnnotationLiteralString *name;
#ifdef __RX_ANNOTATION_DEBUG__
    const RxAnnotationLiteralString *file;
#endif
    const void *value;
    const char **encoding;
#ifdef __RX_ANNOTATION_DEBUG__
    const uint64_t line;
#endif
    const void *padding[7]; // struct __asan_global
} rx_annotation_entry_santitize_address;
#endif

#if __has_feature(address_sanitizer)
typedef rx_annotation_entry_santitize_address rx_annotation_entry_t;
#else
typedef rx_annotation_entry rx_annotation_entry_t;
#endif

// cast to a pointer to a block, dereferenece said pointer, call said block
#define rx_annotation_entry_block_field(type, entry, field) (*(type (^__unsafe_unretained (*))(void))(entry->field))()

extern NSString *_RxAnnotationIdentifier(rx_annotation_entry_t *entry);

#if __has_feature(objc_arc)
#define _RxAnnotationRelease(x)
#else
#define _RxAnnotationRelease(x) [x release]
#endif

#define __RxAnnotationStringify_(X) # X
#define __RxAnnotationStringify(X) __RxAnnotationStringify_(X)
#define __RxAnnotationConcat_(X, Y) X ## Y
#define __RxAnnotationConcat(X, Y) __RxAnnotationConcat_(X, Y)

#if !defined(RX_STATIC_ASSERT)

#if !defined(__RX_STATIC_ASSERT__)
#if defined(__cplusplus) && __has_extension(cxx_static_assert)
#define __RX_STATIC_ASSERT__(constant_expression, description_) static_assert(constant_expression, description_)
#elif !defined(__cplusplus) && __has_extension(c_static_assert)
#define __RX_STATIC_ASSERT__(constant_expression, description_) _Static_assert(constant_expression, description_)
#else
#define __RX_STATIC_ASSERT__(constant_expression, description_)
#endif
#endif // __RX_STATIC_ASSERT__

#define RX_STATIC_ASSERT(const_expression) __RX_STATIC_ASSERT__(const_expression, #const_expression)

#endif // RX_STATIC_ASSERT

#if !defined(__RX_IS_TYPES_COMPATIBLE__)

#if !defined(__cplusplus)
#define __RX_IS_TYPES_COMPATIBLE__(type_, supertype_) __builtin_types_compatible_p(supertype_, type_)
#else
#define __RX_IS_TYPES_COMPATIBLE__(type_, supertype_) std::is_convertible<type_, supertype_>::value
#endif

#endif // __RX_IS_TYPES_COMPATIBLE__

#if !defined(__RX_CLASS_IS_SUBCLASS_OF_CLASS__)

#define __RX_CLASS_IS_SUBCLASS_OF_CLASS__(class_, superclass_) \
class superclass_;\
@class class_;\
__RX_STATIC_ASSERT__(__RX_IS_TYPES_COMPATIBLE__(class_ *, superclass_ *), __RxAnnotationStringify(class_) " is not a " __RxAnnotationStringify(superclass_))

#endif // __RX_CLASS_IS_SUBCLASS_OF_CLASS__

#if !defined(__RX_CLASS_IS_CONFORMS_TO_PROTOCOL__)

#define __RX_CLASS_IS_CONFORMS_TO_PROTOCOL__(class_, protocol_) \
class class_;\
@protocol protocol_;\
__RX_STATIC_ASSERT__(__RX_IS_TYPES_COMPATIBLE__(class_ *, id<protocol_>), __RxAnnotationStringify(class_) " is not a " __RxAnnotationStringify(protocol_))

#endif // __RX_CLASS_IS_CONFORMS_TO_PROTOCOL__

#define __RxAnnotationKeyPathStringifyClass(class_, property_) \
(((void)(NO && ((void)[((class_ *)0) property_], NO)), @__RxAnnotationStringify(class_)))

#define __RxAnnotationProcessorValidationStringify(class_) \
(((void)(NO && ((void)[class_ handleAnnotationSection:(RxAnnotationSection *)nil], NO)), @__RxAnnotationStringify(class_)))

#define __RxAnnotationKeyPathStringify(class_, property_) \
(((void)(NO && ((void)[((class_ *)0) property_], NO)), @__RxAnnotationStringify(class_)__RxAnnotationStringify(.)__RxAnnotationStringify(property_)))

#define __RxAnnotationIndex(_0, _1_, _2_, _3_, _4_, _5_, _6_, _7_, _8_, _9_, _10_, _11_, _12_, _13_, _14_, _15_, _16_, _17_, _18_, _19_, _20_, _21_, _22_, _23_, _24_, _25_, _26_, _27_, _28_, _29_, _30_, _31_, _32_, _33_, _34_, _35_, _36, _37, _38, _39, _40, _41, _42, _43, _44, _45, _46, _47, _48, _49, _50, _51, _52, _53, _54, _55, _56, _57, _58, _59, _60, _61, _62, _63, _64, _65, _66, _67, _68, _69, _70, value, ...) value

#define __RxAnnotationIndexCount(...) __RxAnnotationIndex(0, ## __VA_ARGS__, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)

#ifndef RX_VA_OPT_SUPPORTED

#define __TEST_THIRD_ARG__(a, b, c, ...) c
#define __RX_VA_OPT_SUPPORTED_INTERNAL__(...) __TEST_THIRD_ARG__(__VA_OPT__(,), true, false,)
#define RX_VA_OPT_SUPPORTED __RX_VA_OPT_SUPPORTED_INTERNAL__(?)

#endif

#if RX_VA_OPT_SUPPORTED
#define __RX_VA_OPT__ __VA_OPT__
#else
#define __RX_VA_OPT_EMIT_COMMA__(...) ,
#define __RX_VA_OPT_EMIT_NP__(...)
#define __RX_VA_OPT__(...) metamacro_if_eq(0, __RxAnnotationIndexCount(__VA_ARGS__))(__RX_VA_OPT_EMIT_NP__)(__RX_VA_OPT_EMIT_COMMA__)()
#endif

#define __RxAnnotationDispatch0(__withoutScope, __withScope, ...) __withoutScope

#define __RxAnnotationDispatch1(__withoutScope, __withScope, ...) __withScope

#define _RxAnnotationDispatch(__withoutScope, __withScope,  ...) __RxAnnotationConcat(__RxAnnotationDispatch, __RxAnnotationIndexCount(__VA_ARGS__))(__withoutScope, __withScope)

#ifdef __RX_ANNOTATION_DEBUG__
#define __RxAnnotationValue(sectionName_, category_, collection_, name_, default_, counter_) \
class RxAnnotation;\
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_category_, __RxAnnotationConcat(category__, counter_)) = category_; \
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_collection_, __RxAnnotationConcat(collection__, counter_)) = collection_; \
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_name_, __RxAnnotationConcat(name__, counter_)) = name_; \
__attribute__((used)) static void *__RxAnnotationConcat(__arx_annotation_value_, __RxAnnotationConcat(default__, counter_)) = (__bridge void *) ^{ return default_; }; \
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_file_, __RxAnnotationConcat(file__, counter_)) = @__BASE_FILE__; \
__attribute__((used)) static const char *__RxAnnotationConcat(__arx_annotation_encoding_, __RxAnnotationConcat(encoding__, counter_)) = (char *)@encode(__typeof__(default_)); \
__attribute__((used)) __attribute__((section (RxAnnotationSegmentName "," sectionName_))) static rx_annotation_entry __RxAnnotationConcat(__arx_annotation_entry_, __RxAnnotationConcat(entry, counter_)) = \
{ &__RxAnnotationConcat(__arx_annotation_category_, __RxAnnotationConcat(category__, counter_)), &__RxAnnotationConcat(__arx_annotation_collection_, __RxAnnotationConcat(collection__, counter_)), &__RxAnnotationConcat(__arx_annotation_name_, __RxAnnotationConcat(name__, counter_)), &__RxAnnotationConcat(__arx_annotation_file_, __RxAnnotationConcat(file__, counter_)), (void *)&__RxAnnotationConcat(__arx_annotation_value_, __RxAnnotationConcat(default__, counter_)), &__RxAnnotationConcat(__arx_annotation_encoding_, __RxAnnotationConcat(encoding__, counter_)), __LINE__ };
#else
#define __RxAnnotationValue(sectionName_, category_, collection_, name_, default_, counter_) \
class RxAnnotation;\
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_category_, __RxAnnotationConcat(category__, counter_)) = category_; \
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_collection_, __RxAnnotationConcat(collection__, counter_)) = collection_; \
__attribute__((used)) static const RxAnnotationLiteralString __RxAnnotationConcat(__arx_annotation_name_, __RxAnnotationConcat(name__, counter_)) = name_; \
__attribute__((used)) static void *__RxAnnotationConcat(__arx_annotation_value_, __RxAnnotationConcat(default__, counter_)) = (__bridge void *) ^{ return default_; }; \
__attribute__((used)) static const char *__RxAnnotationConcat(__arx_annotation_encoding_, __RxAnnotationConcat(encoding__, counter_)) = (char *)@encode(__typeof__(default_)); \
__attribute__((used)) __attribute__((section (RxAnnotationSegmentName "," sectionName_))) static rx_annotation_entry __RxAnnotationConcat(__arx_annotation_entry_, __RxAnnotationConcat(entry, counter_)) = \
{ &__RxAnnotationConcat(__arx_annotation_category_, __RxAnnotationConcat(category__, counter_)), &__RxAnnotationConcat(__arx_annotation_collection_, __RxAnnotationConcat(collection__, counter_)), &__RxAnnotationConcat(__arx_annotation_name_, __RxAnnotationConcat(name__, counter_)), (void *)&__RxAnnotationConcat(__arx_annotation_value_, __RxAnnotationConcat(default__, counter_)), &__RxAnnotationConcat(__arx_annotation_encoding_, __RxAnnotationConcat(encoding__, counter_)) };
#endif

#ifdef __cplusplus
}
#endif

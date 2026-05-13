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

#ifndef RxInjectorAnnotation_h
#define RxInjectorAnnotation_h

#include <RxAnnotation/RxAnnotationInline.h>

#ifndef __RX_INJECTOR_ANNOTATION_VAL__

#define __RX_INJECTOR_ANNOTATION_VAL__(key, imp, ...) \
(key, imp __RX_VA_OPT__(__VA_ARGS__) __VA_ARGS__)

#endif // __RX_INJECTOR_ANNOTATION_VAL__

#ifndef RxInjectorAnnotationDefinition

#define __RxInjectorAnnotationName "RxInjector"

// RxAnnotationDeclare(section_, category_, collection_, name_, default_)
#define RxInjectorAnnotationDefinition(category_, collection_, name_, annotation_) \
RxAnnotationDeclare(__RxInjectorAnnotationName, category_, collection_, name_, (annotation_))

#ifndef RxInjectorAnnotationGetClass
#define RxInjectorAnnotationGetClass(identifier_) [identifier_ class]
#endif // RxInjectorAnnotationGetClass

#ifndef RxInjectorAnnotationGetProtocol
#define RxInjectorAnnotationGetProtocol(identifier_) @protocol(identifier_)
#endif // RxInjectorAnnotationGetProtocol

#ifndef RxInjectorClassIdentifierDefine
#define RxInjectorClassIdentifierDefine(scope_, iden_) __RX_ANNOTATION_INJECTOR_ ## scope_ ## _ ## iden_ ## __
#endif // RxInjectorClassIdentifierDefine

#ifndef __RX_INJECTOR_IDENTIFIER_DEFINE__

#define __RX_INJECTOR_IDENTIFIER_DEFINE__ 1

#ifdef DEBUG

#define RxInjectorIdentifierDefine(scope_, identifier_) FOUNDATION_EXPORT NSString *const RxInjectorClassIdentifierDefine(scope_, identifier_); NSString *const RxInjectorClassIdentifierDefine(scope_, identifier_) = @__RxAnnotationStringify(scope_)__RxAnnotationStringify(identifier_);

#define RxInjectorClassPropertyDefine(class_, property_) NSString *const RxInjectorClassIdentifierDefine(class_, property_) = __RxAnnotationKeyPathStringify(class_, property_);

#define RxInjectorClassPropertyDefineDebugOnly(class_, property_) RxInjectorClassPropertyDefine(class_, property_)

#else

#define RxInjectorIdentifierDefine(scope_, identifier_) FOUNDATION_EXPORT NSString *const RxInjectorClassIdentifierDefine(scope_, identifier_); NSString *const RxInjectorClassIdentifierDefine(scope_, identifier_) = @__RxAnnotationStringify(scope_)__RxAnnotationStringify(identifier_);

#define RxInjectorClassPropertyDefine(class_, property_) static NSString *const RxInjectorClassIdentifierDefine(class_, property_) = __RxAnnotationKeyPathStringify(class_, property_);

#define RxInjectorClassPropertyDefineDebugOnly(class_, property_)

#endif // DEBUG
#endif // RxInjectorClassPropertyDefine

// (category_, collection_, name_, default_)

#ifndef RxInjectorAnnotationClass

#define __RX_ANNOTATION_INJECTOR_VALUE_CATEGORY__ "com.rx.injector.annotation.value"

#define __RX_ANNOTATION_INJECTOR_VALUE__(key, imp) \
RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_VALUE_CATEGORY__, @__RX_ANNOTATION_INJECTOR_VALUE_CATEGORY__, @__RxAnnotationStringify(key), (@{@"k": key, @"v": (imp)}))

#define __RX_ANNOTATION_INJECTOR_VALUE_SCOPE__(key, imp, scope) \
RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_VALUE_CATEGORY__, @__RX_ANNOTATION_INJECTOR_VALUE_CATEGORY__, @__RxAnnotationStringify(key), (@{@"k": key, @"v": (imp), @"s": (scope)}))

#define RxInjectorAnnotationValue(key, imp, ...) \
_RxAnnotationDispatch(__RX_ANNOTATION_INJECTOR_VALUE__ __RX_INJECTOR_ANNOTATION_VAL__(key, imp, __VA_ARGS__), __RX_ANNOTATION_INJECTOR_VALUE_SCOPE__ __RX_INJECTOR_ANNOTATION_VAL__(key, imp, __VA_ARGS__), __VA_ARGS__)

#endif // RxInjectorAnnotationClass

#ifndef RxInjectorAnnotationInitializer

#define RxInjectorClassInitializerDefine(class_) \
RxInjectorIdentifierDefine(class_, INITIALIZER)

#define RxInjectorClassInitializerIdentifierDefine(class_) \
RxInjectorClassIdentifierDefine(class_, INITIALIZER);

#define __RX_CLASS_IS_NSARRAY__(keys_) \
__RX_STATIC_ASSERT__((__RX_IS_TYPES_COMPATIBLE__(__typeof__(keys_), NSArray *)), "???")

#define __RX_ANNOTATION_INJECTOR_INITIALIZER_CATEGORY__ "com.rx.injector.annotation.initializer"

#define RxInjectorAnnotationInitializer(class_, selector_, keys_) \
class RxAnnotation; \
@__RX_CLASS_IS_SUBCLASS_OF_CLASS__(class_, NSObject);\
__RX_CLASS_IS_NSARRAY__(keys_);\
RxInjectorClassInitializerDefine(class_); \
@RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_INITIALIZER_CATEGORY__, @__RxAnnotationStringify(class_), @__RxAnnotationStringify(class_), (@{@"c": [class_ class], @"sel": NSStringFromSelector(@selector(selector_)), @"args": keys_}))

#endif // RxInjectorAnnotationInitializer

#ifndef RxInjectorAnnotationBlock

#define __RX_ANNOTATION_INJECTOR_BLOCK_CATEGORY__ "com.rx.injector.annotation.block"

#define __RX_ANNOTATION_INJECTOR_BLOCK__(key, imp) \
RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_BLOCK_CATEGORY__, @__RX_ANNOTATION_INJECTOR_BLOCK_CATEGORY__, @__RxAnnotationStringify(key), (@{@"k": key, @"b": ^id(NSArray *args, id<RxInjector> injector) { imp }}))

#define __RX_ANNOTATION_INJECTOR_BLOCK_SCOPE__(key, imp, scope) \
RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_BLOCK_CATEGORY__, @__RX_ANNOTATION_INJECTOR_BLOCK_CATEGORY__, @__RxAnnotationStringify(key), (@{@"k": key, @"s": (scope), @"b": ^id(NSArray *args, id<RxInjector> injector) { imp }}))

#define RxInjectorAnnotationBlock(key, imp, ...) \
_RxAnnotationDispatch(__RX_ANNOTATION_INJECTOR_BLOCK__ __RX_INJECTOR_ANNOTATION_VAL__(key, imp, __VA_ARGS__), __RX_ANNOTATION_INJECTOR_BLOCK_SCOPE__ __RX_INJECTOR_ANNOTATION_VAL__(key, imp, __VA_ARGS__), __VA_ARGS__)

#endif // RxInjectorAnnotationBlock

#ifndef RxInjectorAnnotationProperty

#define __RX_ANNOTATION_INJECTOR_PROPERTY_CATEGORY__ "com.rx.injector.annotation.property"

//RxInjectorClassPropertyDefine(class_, property_);\

#define RxInjectorAnnotationProperty(class_, property_, key) \
class RxAnnotation; \
@RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_PROPERTY_CATEGORY__, __RxAnnotationKeyPathStringifyClass(class_, property_), @__RxAnnotationStringify(property_), (@[__RxAnnotationKeyPathStringify(class_, property_), @__RxAnnotationStringify(class_), @__RxAnnotationStringify(property_), key]))

#endif // RxInjectorAnnotationProperty

#ifndef RxInjectorAnnotationPropertyBlock

#define RxInjectorAnnotationPropertyBlock(class_, property_, block_) \
class RxAnnotation; \
RxInjectorClassPropertyDefine(class_, property_); \
@RxInjectorAnnotationBlock(RxInjectorClassIdentifierDefine(class_, property_), block_);\
@RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_PROPERTY_CATEGORY__, __RxAnnotationKeyPathStringifyClass(class_, property_), @__RxAnnotationStringify(property_), RxTuplePack(__RxAnnotationKeyPathStringify(class_, property_), @__RxAnnotationStringify(class_), @__RxAnnotationStringify(property_), RxInjectorClassIdentifierDefine(class_, property_), nil))

#endif // RxInjectorAnnotationPropertyBlock

#ifndef RxInjectorAnnotationModule

#define __RX_ANNOTATION_INJECTOR_MODULE_CATEGORY__ "com.rx.injector.annotation.module"

#define RxInjectorAnnotationModule(module_, priority_) \
class RxAnnotation; \
@__RX_CLASS_IS_CONFORMS_TO_PROTOCOL__(module_, RxInjectorModule); \
@RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_MODULE_CATEGORY__, @__RxAnnotationStringify(priority_), @__RxAnnotationStringify(module_), @__RxAnnotationStringify(module_));

#endif // RxInjectorAnnotationModule

// should enable environment variable RX_INJECTOR_UNIT_TESTING
#ifndef RxInjectorAnnotationUnitTestModule

#define __RX_ANNOTATION_INJECTOR_UNIT_TEST_MODULE_CATEGORY__ "com.rx.injector.annotation.module.ut"

#define RxInjectorAnnotationUnitTestModule(module_, priority_) \
class RxAnnotation; \
@__RX_CLASS_IS_CONFORMS_TO_PROTOCOL__(module_, RxInjectorModule); \
@RxInjectorAnnotationDefinition(@__RX_ANNOTATION_INJECTOR_UNIT_TEST_MODULE_CATEGORY__, @__RxAnnotationStringify(priority_), @__RxAnnotationStringify(module_), @__RxAnnotationStringify(module_));

#endif // RxInjectorAnnotationModule

#endif // RxInjectorAnnotationDefinition

#endif /* RxInjectorAnnotation_h */

#include <RxInjector/RxInjector.h>

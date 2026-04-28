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

#import <RxAnnotation/RxAnnotationInlineInternal.h>

#ifndef RxAnnotationDeclare

#define RxAnnotationDeclare(section_, category_, collection_, name_, default_) __RxAnnotationValue(section_, category_, collection_, name_, default_, __COUNTER__)

#endif // RxAnnotationDeclare

#ifndef RxAnnotationRegister

#define RxAnnotationSectionName "RxAnnotation"
#define RxAnnotationMetaCollectionIdentifier "Annotation"
#define RxAnnotationMetaSectionIdentifier "Meta"
#define RxAnnotationMetaSectionNameKey "section"
#define RxAnnotationMetaProcessorNameKey "processor"

#if !defined(RX_ANNOTATION_REGISTER_IDENTIFIER)
#define RX_ANNOTATION_REGISTER_IDENTIFIER(scope_, identifier_) __RX_ANNOTATION_REGISTER_SECTION_ ## scope_ ## _ ## identifier_ ## __
#endif // RX_ANNOTATION_REGISTER_SECTION

#if !defined(RX_ANNOTATION_IDENTIFIER_DEFINE)
#define RX_ANNOTATION_IDENTIFIER_DEFINE(scope_, identifier_) FOUNDATION_EXPORT NSString *const RX_ANNOTATION_REGISTER_IDENTIFIER(scope_, identifier_); NSString *const RX_ANNOTATION_REGISTER_IDENTIFIER(scope_, identifier_) = @__RxAnnotationStringify(scope_)__RxAnnotationStringify(identifier_);
#endif // RX_ANNOTATION_IDENTIFIER_DEFINE

#define RxAnnotationRegister(section_, processor_) \
__RX_CLASS_IS_SUBCLASS_OF_CLASS__(processor_, RxAnnotationSectionProcessor);\
RX_ANNOTATION_IDENTIFIER_DEFINE(META, section_);\
@RxAnnotationDeclare(RxAnnotationSectionName, @RxAnnotationMetaCollectionIdentifier, @RxAnnotationMetaSectionIdentifier, @__RxAnnotationStringify(section_), (@{@RxAnnotationMetaSectionNameKey: @__RxAnnotationStringify(section_), @RxAnnotationMetaProcessorNameKey: __RxAnnotationProcessorValidationStringify(processor_) }))

#endif // RxAnnotationDefinition

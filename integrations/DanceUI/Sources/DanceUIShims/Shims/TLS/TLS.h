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

#ifndef TLS_h
#define TLS_h

#import <Foundation/Foundation.h>
#import <os/signpost.h>

FOUNDATION_EXPORT _Thread_local int64_t _DanceUIPerThreadUpdateCount;

FOUNDATION_EXPORT void _DanceUISetThreadTransactionData(void *transactionData);
FOUNDATION_EXPORT void * _DanceUIThreadTransactionData(void);

FOUNDATION_EXPORT void _DanceUISetThreadGeometryProxyData(void *geometryProxyData);
FOUNDATION_EXPORT void * _DanceUIThreadGeometryProxyData(void);

FOUNDATION_EXPORT void _DanceUISetAGGraphCurrentUpdateData(void *currentUpdateData);
FOUNDATION_EXPORT void * _DanceUIAGGraphCurrentUpdateData(void);

FOUNDATION_EXPORT void _DanceUISetThreadLayoutData(void *layoutData);
FOUNDATION_EXPORT void * _DanceUIThreadLayoutData(void);

FOUNDATION_EXPORT void _DanceUISetThreadLogAddress(void *logAddress);
FOUNDATION_EXPORT void * _DanceUIThreadLogAddress(void);

#endif // TLS_h

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

#import "TLS.h"

_Thread_local int64_t _DanceUIPerThreadUpdateCount = 0;

static _Thread_local void * _DanceUIPerThreadTransactionData = nil;

void _DanceUISetThreadTransactionData(void *transactionData) {
    _DanceUIPerThreadTransactionData = transactionData;
}

void * _DanceUIThreadTransactionData(void) {
    return _DanceUIPerThreadTransactionData;
}

static _Thread_local void * _DanceUIPerThreadGeometryProxyData = nil;

void _DanceUISetThreadGeometryProxyData(void *geometryProxyData) {
    _DanceUIPerThreadGeometryProxyData = geometryProxyData;
}

void * _DanceUIThreadGeometryProxyData(void) {
    return _DanceUIPerThreadGeometryProxyData;
}

static _Thread_local void * __DanceUIAGGraphCurrentUpdateData = nil;

void _DanceUISetAGGraphCurrentUpdateData(void *currentUpdateData) {
    __DanceUIAGGraphCurrentUpdateData = currentUpdateData;
}

void * _DanceUIAGGraphCurrentUpdateData(void) {
    return __DanceUIAGGraphCurrentUpdateData;
}

static _Thread_local void * _DanceUIPerThreadLayoutData = nil;

void _DanceUISetThreadLayoutData(void *layoutData) {
    _DanceUIPerThreadLayoutData = layoutData;
}

void * _DanceUIThreadLayoutData(void) {
    return _DanceUIPerThreadLayoutData;
}

static _Thread_local void * _DanceUIPerThreadLogAddress = nil;

void _DanceUISetThreadLogAddress(void *logAddress) {
    _DanceUIPerThreadLogAddress = logAddress;
}

void * _DanceUIThreadLogAddress(void) {
    return _DanceUIPerThreadLogAddress;
}

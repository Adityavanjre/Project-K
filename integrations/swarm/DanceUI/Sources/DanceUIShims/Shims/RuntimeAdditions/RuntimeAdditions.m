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

#import <Foundation/Foundation.h>
#include <DanceUIRuntime/DanceUISwiftSupport.h>

FOUNDATION_EXPORT
const void *$s7DanceUI4ViewMp;

FOUNDATION_EXPORT
const void *_DanceUIViewProtocolDescriptor(void) {
    return &$s7DanceUI4ViewMp;
}

FOUNDATION_EXPORT
const void *$s7DanceUI12ViewModifierMp;

FOUNDATION_EXPORT
const void *_DanceUIViewModifierProtocolDescriptor(void) {
    return &$s7DanceUI12ViewModifierMp;
}

FOUNDATION_EXPORT
const void *$s7DanceUI15ViewTypeVisitorMp;

FOUNDATION_EXPORT
const void *_DanceUIViewTypeVisitorProtocolDescriptor(void) {
    return &$s7DanceUI15ViewTypeVisitorMp;
}

////    void @_DanceUICallVisitViewType2(
////        %ViewVisitorContext* nocapture readonly dereferenceable(24) %0,
////         %swift.type* %1, // visitor_pwt[+0x8](%1, ...)
////         %swift.type* %Visitor,
////         %swift.type* %V,
////         i8** %A.ViewTypeVisitor,
////         i8** %V.View)
//
////@_silgen_name("_DanceUICallVisitViewType2")
////internal func callVisitViewType2<Visitor: ViewTypeVisitor, V: View>(_ context: inout ViewVisitorContext<Visitor>, _: V.Type) {
////    context.ptr.pointee.visit(type: V.self)
////}
//
//SWIFT_CC(swift)
//void _DanceUICallVisitViewType2(const void *visitor,
//                                const void *visitor_pwt_call_view_metadata,
//                                const void *visitor_metadata,
//                                const void *view_metadata,
//                                const void *visitor_witnessTable,
//                                const void *view_witnessTable);
//
//// call swiftcc void @_DanceUICallVisitViewType1(
//// ViewVisitorContext* nocapture nonnull dereferenceable(24) %3,
//// i8* %1,   // view.type
//// i8* %2,   // view.pwt
//// %swift.type* %A,
//// i8** %A.ViewTypeVisitor)
//SWIFT_CC(swift)
//void _DanceUICallVisitViewType1(void *visitor_context,
//                                const void *view_conformance_type,
//                                const void *view_conformance_pwt,
//                                const void *visitor_type,
//                                const void *visitor_pwt,
//                                const void *p5 SWIFT_CONTEXT) {
//    return _DanceUICallVisitViewType2(visitor_context,
//                                      view_conformance_type,
//                                      visitor_type,
//                                      view_conformance_type,
//                                      visitor_pwt,
//                                      view_conformance_pwt);
//}

/// --------------------------------------------------------------------------------------------------------

//    void @_DanceUICallVisitViewType2(
//        %ViewVisitorContext* nocapture readonly dereferenceable(24) %0,
//         %swift.type* %1, // visitor_pwt[+0x8](%1, ...)
//         %swift.type* %Visitor,
//         %swift.type* %V,
//         i8** %A.ViewTypeVisitor,
//         i8** %V.View)

//@_silgen_name("_DanceUICallVisitViewType2")
//internal func callVisitViewType2<Visitor: ViewTypeVisitor, V: View>(_ context: inout ViewVisitorContext<Visitor>, _: V.Type) {
//    context.ptr.pointee.visit(type: V.self)
//}

// call swiftcc void @_DanceUICallVisitViewType1(
// ViewVisitorContext* nocapture nonnull dereferenceable(24) %3,
// i8* %1,   // view.type
// i8* %2,   // view.pwt
// %swift.type* %A,
// i8** %A.ViewTypeVisitor)

//SWIFT_CC(swift)
//void _DanceUICallVisitViewType2(const void *visitor,
//                                const void *visitor_pwt_call_view_metadata,
//                                const void *visitor_metadata,
//                                const void *view_metadata,
//                                const void *visitor_witnessTable,
//                                const void *view_witnessTable);
//
//SWIFT_CC(swift)
//void _DanceUICallVisitViewType1(void *visitor_context,
//                                const void *view_conformance_type,
//                                const void *view_conformance_pwt,
//                                const void *visitor_type,
//                                const void *visitor_pwt) {
//    return _DanceUICallVisitViewType2(visitor_context,
//                                      view_conformance_type,
//                                      view_conformance_type,
//                                      visitor_type,
//                                      visitor_pwt,
//                                      view_conformance_pwt);
//}

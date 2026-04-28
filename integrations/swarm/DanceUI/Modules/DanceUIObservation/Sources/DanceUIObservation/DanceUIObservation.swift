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

/// A type that emits notifications to observers when underlying data changes.
///
/// Conforming to this protocol signals to other APIs that the type supports
/// observation. However, applying the `Observable` protocol by itself to a
/// type doesn't add observation functionality to the type. Instead, always use
/// the ``Observation/Observable()`` macro when adding observation
/// support to a type.
public protocol Observable { }

#if $Macros && hasAttribute(attached)

/// Defines and implements conformance of the Observable protocol.
///
/// This macro adds observation support to a custom type and conforms the type
/// to the ``Observation/Observable`` protocol. For example, the following code
/// applies the `Observable` macro to the type `Car` making it observable:
///
///     @Observable
///     class Car {
///        var name: String = ""
///        var needsRepairs: Bool = false
///
///        init(name: String, needsRepairs: Bool = false) {
///            self.name = name
///            self.needsRepairs = needsRepairs
///        }
///     }
@attached(member, names:
    named(_$observationRegistrar), named(access(keyPath:)), named(withMutation(keyPath:_:))
)
@attached(memberAttribute)
@attached(extension, conformances: Observable)
public macro Observable() =
  #externalMacro(module: "DanceUIObservationMacroImpl", type: "ObservableMacro")

/// Synthesizes a property for accessors.
///
/// The ``Observation`` module uses this macro. Its use outside of the
/// framework isn't necessary.
@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro ObservationTracked() =
  #externalMacro(module: "DanceUIObservationMacroImpl", type: "ObservationTrackedMacro")

/// Disables observation tracking of a property.
///
/// By default, an object can observe any property of an observable type that
/// is accessible to the observing object. To prevent observation of an
/// accessible property, attach the `ObservationIgnored` macro to the property.
@attached(accessor, names: named(willSet))
public macro ObservationIgnored() =
  #externalMacro(module: "DanceUIObservationMacroImpl", type: "ObservationIgnoredMacro")

#endif

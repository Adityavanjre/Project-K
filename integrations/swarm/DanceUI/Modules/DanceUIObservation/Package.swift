// swift-tools-version: 5.9
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

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "DanceUIObservation",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DanceUIObservation",
            targets: ["DanceUIObservation"]
        ),
        .executable(
            name: "Playground",
            targets: ["Playground"]
        ),
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "DanceUIObservationMacroImpl",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in Playground.
        .target(
            name: "DanceUIObservation",
            dependencies: ["DanceUIObservationMacroImpl"]
        ),

        // Playground for using the macro in its own code.
        .executableTarget(
            name: "Playground",
            dependencies: ["DanceUIObservation", "DanceUIObservationMacroImpl"]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MacroExpansionTests",
            dependencies: [
                "DanceUIObservationMacroImpl",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "IntegratedTests",
            dependencies: [
                "DanceUIObservation",
            ]
        ),
    ]
)

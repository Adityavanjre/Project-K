#!/bin/bash

rootPath=$(git rev-parse --show-toplevel)
source $rootPath/utils/common-source.sh
file="$rootPath/Modules/DanceUIPreview/Sources/DanceUIPreview/Reexporter.swift"
interface_file="$PODS_CONFIGURATION_BUILD_DIR/DanceUI/DanceUI.framework/Modules/DanceUI.swiftmodule/x86_64-apple-ios-simulator.swiftinterface"
ref_interface_file="$rootPath/utils/APICoverageKit/x86_64-apple-ios-simulator.swiftinterface"
if [[ ! -f $interface_file ]]; then
    echo "DanecUI.swiftmodule not found, exit"
    exit 0
fi

if [[ ! -f $ref_interface_file ]]; then
    echo "SwiftUI.swiftmodule not found, exit"
    exit 0
fi

new_content=$($interface_parser export --interface $interface_file --reference-interface $ref_interface_file)
old_content=$(cat $file)
if [[ "$new_content" != "$old_content" ]]; then
    echo "update Reexporter.swift"
    echo "$new_content" > $file
fi

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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct ResolvedTextFilter: StatefulRule {
    
    internal typealias Value = ResolvedStyledText
    
    @Attribute
    internal var text: Text
    
    @Attribute
    internal var environment: EnvironmentValues
    
    @Attribute
    internal var time: Time
    
    internal let includeDefaultAttributes: Bool
    
    internal let isArchived: Bool
    
    internal private(set) var includeAccessibility: Bool
    
    internal let tracker: PropertyList.Tracker
    
    internal private(set) var lastText: Text?
    
    internal private(set) var nextTime: Time
    
    @inline(__always)
    internal init(text: Attribute<Text>,
                  environment: Attribute<EnvironmentValues>,
                  time: Attribute<Time>,
                  includeDefaultAttributes: Bool = false,
                  isArchived: Bool,
                  includeAccessibility: Bool = false,
                  tracker: PropertyList.Tracker = PropertyList.Tracker(),
                  lastText: Text? = nil,
                  nextTime: Time = .zero) {
        self._text = text
        self._environment = environment
        self._time = time
        self.includeDefaultAttributes = includeDefaultAttributes
        self.isArchived = isArchived
        self.includeAccessibility = includeAccessibility
        self.tracker = tracker
        self.lastText = lastText
        self.nextTime = nextTime
    }
    
    internal mutating func updateValue() {
        let (newText, isTextChanged) = $text.changedValue()
        let (newEnvironment, isEnvironmentChanged) = $environment.changedValue()
        
        guard !hasValue || (isTextChanged && lastText != newText) || (isEnvironmentChanged && newEnvironment.hasDifferentUsedValues(with: tracker)) || (!isArchived && value.resolvableConfiguration.isUpdateStrategyDelay && nextTime <= time) else {
            return
        }
        
        var renderingText = newText
        let trackedEnvironment = newEnvironment.withTracker(tracker)
        lastText = newText
        
        var features: Text.ResolvedProperties.Features = .empty
        
        if self.includeDefaultAttributes {
            var initShape = _ShapeStyle_Shape(operation: .prepare((renderingText, level: 0)),
                                              result: .none,
                                              environment: trackedEnvironment,
                                              bounds: nil,
                                              role: .stroke,
                                              inRecursiveStyle: false)
            let foregroundStyle = trackedEnvironment.effectiveForegroundStyle
            foregroundStyle._apply(to: &initShape)
            
            if case .prepared(let styledText) = initShape.result {
                renderingText = styledText
            }
            
            features = initShape.needsStyledRendering ? .styledText : .empty
        }
        
        let nsAttributedString = renderingText.resolveString(in: trackedEnvironment,
                                                             includeDefaultAttributes: includeDefaultAttributes,
                                                             options: .zero)
        let resolvedStyledText = ResolvedStyledText(string: nsAttributedString,
                                                    environment: trackedEnvironment,
                                                    dynamicRendering: isArchived,
                                                    features: features)
        value = resolvedStyledText
        guard !isArchived, value.resolvableConfiguration.isUpdateStrategyDelay else {
            return
        }
        let nextUpdateTime = value.nextUpdate(after: time)
        time = nextUpdateTime
        ViewGraph.current.scheduleNextViewUpdate(byTime: nextUpdateTime)
    }
}

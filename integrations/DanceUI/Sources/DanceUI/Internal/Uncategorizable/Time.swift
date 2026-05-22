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

import QuartzCore

@available(iOS 13.0, *)
@_spi(DanceUICompose)
public struct Time: Hashable, Comparable {
    
    @usableFromInline
    internal private(set) var seconds: Double
    
    @inlinable
    internal static var zero: Time {
        Time(seconds: 0)
    }
    
    @inlinable
    @_spi(DanceUICompose) 
    public static var now: Time {
        Time(seconds: CACurrentMediaTime())
    }
    
    @inlinable
    internal static var distantFuture: Time {
        Time(seconds: .infinity)
    }

    @inlinable
    internal static var never: Time {
        Time(seconds: -.infinity)
    }
    
    @inlinable
    internal static func seconds(_ n: Double) -> Time {
        Time(seconds: n)
    }
    
    @inlinable
    internal static func microseconds(_ n: Double) -> Time {
        Time(seconds: n * 1.0e-6)
    }
    
    @inline(__always)
    @_spi(DanceUICompose)
    public init(seconds: Double) {
        self.seconds = seconds
    }
    
    @inlinable
    internal mutating func advancing(by n: Double) {
        self = advanced(by: n)
    }
    
    @inlinable
    internal func advanced(by n: Double) -> Time {
        Time(seconds: seconds + n)
    }
    
    /// `other` - `self`
    /// 
    @inlinable
    internal func distance(to other: Time) -> Double {
        seconds.distance(to: other.seconds)
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public static func < (lhs: Time, rhs: Time) -> Bool {
        lhs.seconds < rhs.seconds
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public static func > (lhs: Time, rhs: Time) -> Bool {
        lhs.seconds > rhs.seconds
    }
    
    @inlinable
    internal static func - (lhs: Time, rhs: Time) -> Time {
        Time(seconds: lhs.seconds - rhs.seconds)
    }

    @inlinable
    internal static func + (lhs: Time, rhs: Time) -> Time {
        Time(seconds: lhs.seconds + rhs.seconds)
    }
    
}

#if DEBUG
@available(iOS 13.0, *)
extension Time: CustomDebugStringConvertible {
    
    @_spi(DanceUICompose)
    public var debugDescription: String {
        if self == .distantFuture {
            return "<Time; distantFuture>"
        }
        if self == .never {
            return "<Time; never>"
        }
        return "<Time; seconds = \(seconds)>"
    }
    
}

#endif
@available(iOS 13.0, *)
extension TimeInterval {
    
    @inline(__always)
    internal func toTime() -> Time {
        Time(seconds: self)
    }
    
}

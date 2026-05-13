//
//  HashChecker.hpp
//  RxFoundation
//
//  Created by Closure on 7/20/17.
//  Copyright © 2017 Closure. All rights reserved.
//

#ifndef HashChecker_h
#define HashChecker_h

#include <RxFoundation/MethodChecker.hpp>
#include <limits>
#include <cmath>

namespace Rx {
    namespace detail {
        auto has_hash = MethodChecker::construct([](const auto &&x) -> decltype(x.hash()) {});
        constexpr const auto hashFactor = 2654435761UL;
    }
    
    template <typename T>
    auto hash(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<decltype(detail::has_hash(object))::value, HashCode> {
        return object.hash();
    }
    
    template <typename T>
    auto hash(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<std::is_integral<T>::value, HashCode> {
        return ((object > 0) ? (HashCode)(object) : (HashCode)(-object)) * detail::hashFactor;
    }
    
    template <typename T>
    auto hash(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<std::is_floating_point<T>::value, String> {
        double dInt;
        if (object < 0) {
            object = -object;
        }
        dInt = floor(object + 0.5);
        HashCode integralHash = detail::hashFactor * (HashCode)fmod(dInt, (double)std::numeric_limits<unsigned long>::max());
        return (HashCode)(integralHash + (HashCode)((object - dInt) * std::numeric_limits<unsigned long>::max()));
    }

    template <typename T,
    typename = std::enable_if_t<std::is_pointer<T>::value>,
    typename = std::enable_if_t<!std::is_arithmetic<T>::value>>
    auto hash(const T object) RX_NOEXCEPT
    -> std::enable_if_t<!decltype(detail::has_hash(object))::value, HashCode> {
        return hashCode(*object);
    }
}


#endif /* HashChecker_h */

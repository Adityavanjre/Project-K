//
//  CopyDescriptionChecker.hpp
//  RxFoundation
//
//  Created by closure on 6/13/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CopyDescriptionChecker_hpp
#define CopyDescriptionChecker_hpp

#include <RxFoundation/MethodChecker.hpp>
#include <RxFoundation/ObjectMeta.hpp>

namespace Rx {
    namespace detail {
        auto has_copyDescription = MethodChecker::construct([](const auto &&x) -> decltype(x.copyDescription()) {});
    }
    
    template <typename T>
    auto copyDescription(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<decltype(detail::has_copyDescription(object))::value, String> {
        return object.copyDescription();
    }
    
    template <typename T>
    auto copyDescription(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<std::is_integral<T>::value, String> {
        return std::move(String("%d", 0, object));
    }
    
    template <typename T>
    auto copyDescription(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<std::is_floating_point<T>::value, String> {
        return std::move(String("%f", 0, object));
    }
    
    template <typename T,
    typename = std::enable_if_t<!std::is_pointer<T>::value>,
    typename = std::enable_if_t<!std::is_arithmetic<T>::value>>
    auto copyDescription(const T &object) RX_NOEXCEPT
    -> std::enable_if_t<!decltype(detail::has_copyDescription(object))::value, String> {
        return std::move(String("[%s]<%p>", 0, getClassName(&object).c_str(), &object));
    }
    
    template <typename T,
    typename = std::enable_if_t<std::is_pointer<T>::value>,
    typename = std::enable_if_t<!std::is_arithmetic<T>::value>>
    auto copyDescription(const T object) RX_NOEXCEPT
    -> std::enable_if_t<!decltype(detail::has_copyDescription(object))::value, String> {
        return std::move(String("[%s]<%p>", 0, getClassName(object).c_str(), object));
    }
}

#endif /* CopyDescriptionChecker_hpp */

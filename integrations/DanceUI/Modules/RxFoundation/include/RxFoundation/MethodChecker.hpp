//
//  MethodChecker.h
//  RxFoundation
//
//  Created by closure on 6/13/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef MethodChecker_h
#define MethodChecker_h

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/type_traits.hpp>

namespace Rx {
    namespace MethodChecker {
        namespace detail {
            template <typename CheckerType>
            struct CheckerContainer {
                // Let's put the test in private.
            private:
                // We use std::declval to 'recreate' an object of 'UnnamedType'.
                // We use std::declval to also 'recreate' an object of type 'Param'.
                // We can use both of these recreated objects to test the validity!
                
                template <typename Param, typename ...ArgType>
                constexpr auto test_validity(int /* unused */)
                -> decltype(std::declval<CheckerType>()(std::declval<Param>(), std::declval<ArgType>()...),
                            std::true_type()) {
                    // If substitution didn't fail, we can return a true_type.
                    return std::true_type();
                }
                
                template <typename Param, typename ...ArgType>
                constexpr std::false_type test_validity(...) {
                    // Our sink-hole returns a false_type.
                    return std::false_type();
                }
                
            public:
                // A public operator() that accept the argument we wish to test onto the UnnamedType.
                // Notice that the return type is automatic!
                template <typename Param, typename ...ArgType>
                constexpr auto operator()(const Param &p, ArgType &...args) {
                    // The argument is forwarded to one of the two overloads.
                    // The SFINAE on the 'true_type' will come into play to dispatch.
                    return test_validity<Param, ArgType...>(int());
                }
            };
        }
        
        template <typename CheckerType>
        constexpr auto construct(const CheckerType &t) {
            return detail::CheckerContainer<CheckerType>();
        }
    }
}

#endif /* MethodChecker_h */

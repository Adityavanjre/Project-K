//
//  type_traits.hpp
//  RxFoundation
//
//  Created by closure on 12/19/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef type_traits_hpp
#define type_traits_hpp

#include <RxFoundation/RxBase.hpp>
#include <type_traits>

namespace Rx {
    template <typename T>
    struct isPodLike {
#if (__has_feature(is_trivially_copyable) && defined(_LIBCPP_VERSION) || (defined(__GUNC__) && __GUNC__ > 5))
        static const bool value = std::is_trivially_copyable<T>::value;
#elif __has_feature(is_trivially_copyable)
        static const bool value = __is_trivially_copyable(T);
#else 
        static const bool value = !std::is_class<T>::value;
#endif
    };
    
    template <typename T>
    struct Raw {
    private:
        typedef typename std::remove_reference<T>::type _Up;
    public:
        typedef typename std::conditional
        <
            std::is_array<_Up>::value,
            typename std::remove_extent<_Up>::type*,
            typename std::conditional<
                std::is_function<_Up>::value,
                typename std::add_pointer<_Up>::type,
                typename std::conditional<
                    std::is_pointer<_Up>::value,
                    typename std::add_pointer<typename std::remove_cv<typename std::remove_reference<typename std::remove_pointer<_Up>::type>::type>::type>::type,
                    typename std::remove_cv<typename std::remove_reference<_Up>::type>::type
                >::type
            >::type
        >::type type;
    };
    
#if _LIBCPP_STD_VER > 11
    template <typename T>
    using RawType = typename Raw<T>::type;
#endif
}


#endif /* type_traits_hpp */

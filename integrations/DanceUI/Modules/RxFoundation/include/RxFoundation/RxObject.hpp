//
//  RxObject.hpp
//  RxFoundation
//
//  Created by closure on 9/30/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Object_hpp
#define Object_hpp

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/RefCountedBase.hpp>
#include <RxFoundation/CustomStringConvertibleInterface.hpp>
#include <RxFoundation/HashableInterface.hpp>

#include <typeinfo>
#include <cxxabi.h>
#include <memory>
#include <cstdlib>

namespace Rx {
    class Object : public RefCountedBase<Object>,
    public virtual CustomStringConvertibleInterface,
    public virtual HashableInterface {
    public:
        Object() RX_NOEXCEPT;
        Object(const Object &) = default;
        Object(Object &&) = default;
        virtual ~Object() RX_NOEXCEPT;
        
    public:
        virtual String copyDescription() const RX_NOEXCEPT;
        
        virtual bool operator<(const Object *rhs) const RX_NOEXCEPT;
        virtual bool operator<(const Object &rhs) const RX_NOEXCEPT;
        virtual bool operator==(const Object &rhs) const RX_NOEXCEPT;
        
        virtual HashCode hash() const RX_NOEXCEPT;
    private:
        bool _dead;
    };
    
    
    void Log(const String format, Integer reserved, ...);
}

#endif /* Object_hpp */

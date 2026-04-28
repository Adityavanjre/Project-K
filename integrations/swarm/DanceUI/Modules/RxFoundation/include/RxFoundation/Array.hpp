//
//  Array.hpp
//  RxFoundation
//
//  Created by closure on 11/30/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Array_hpp
#define Array_hpp

#include <vector>
#include <RxFoundation/CollectionContainer.hpp>
#include <RxFoundation/String.hpp>
#include <RxFoundation/RxObject.hpp>
#include <RxFoundation/CopyDescriptionChecker.hpp>

namespace Rx {
    
    template <typename T>
    class Array : public virtual Object, public CollectionContainer<std::vector, T, std::allocator<T>> {
    public:
        using base = CollectionContainer<std::vector, T, std::allocator<T>>;
        using StorageType = typename base::StorageType;
        
        using value_type = typename base::value_type;
        using size_type = typename base::size_type;
        using const_reference = typename base::const_reference;
        using iterator = typename base::iterator;
        using const_iterator = typename base::const_iterator;
        
        Array() RX_NOEXCEPT : base() {
        }
        
        Array(std::initializer_list<value_type> __il) RX_NOEXCEPT : base(__il) {
        }
        
        Array(const Array &value) RX_NOEXCEPT : base(value) {
        }
        
        Array(Array &&value) RX_NOEXCEPT : base(std::move(value)) {
        }
        
        Array(const StorageType &value) RX_NOEXCEPT : base(value) {
        }
        
        Array(StorageType &&value) RX_NOEXCEPT : base(value) {
        }
        
        ~Array() RX_NOEXCEPT {
        }
        
        Array &operator=(const Array &copy) RX_NOEXCEPT {
            base::operator=(copy);
            return *this;
        }
        
        virtual String copyDescription() const RX_NOEXCEPT {
            const Integer cnt = base::size();
            Integer idx = 0;
            String description = "(";
            for (idx = 0; idx < (cnt - 1); ++idx) {
                const auto &element = base::operator[](idx);
                String desc = Rx::copyDescription(element);
                description += desc;
                description += ",\n";
            }
            if (cnt) {
                description += Rx::copyDescription(base::operator[](idx));
            }
            description += ")";
            return description;
        }
        
        virtual HashCode hash() const RX_NOEXCEPT {
            return base::size();
        }
        
        bool operator==(const Array &rhs) const RX_NOEXCEPT {
            return base::operator==(rhs);
        }
        
    private:
        
    };
}

#endif /* Array_hpp */

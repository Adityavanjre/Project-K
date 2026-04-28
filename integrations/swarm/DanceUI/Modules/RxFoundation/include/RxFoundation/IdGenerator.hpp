//
//  IdGenerator.hpp
//  RxFoundation
//
//  Created by closure on 6/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef IdGenerator_hpp
#define IdGenerator_hpp

#include <RxFoundation/RxBase.hpp>

#include <RxFoundation/Array.hpp>
#include <RxFoundation/String.hpp>

namespace Rx {
    
    template <typename __IdType>
    class IdGeneratorInterface;
    
    template <typename __IdType>
    class IdGeneratorInterface {
    public:
        using id_type = __IdType;
        static const id_type &InvalidId;
        
        IdGeneratorInterface() {}
        virtual ~IdGeneratorInterface() {}
        
        virtual id_type getNextId() = 0;
        virtual bool getNextIds(Array<id_type> &ids, UInt64 size, const id_type &invalid = InvalidId) {
            if (size == 0) {
                return true;
            }
            id_type id;
            do {
                ids.addObject(id = getNextId());
                size--;
            } while (size != 0 && id != invalid);
            return size == 0 && id != invalid;
        }
    };
    
    class IntegerIdGenerator : public virtual IdGeneratorInterface<UInt64> {
    public:
        static const id_type &InvalidId;
        
        IntegerIdGenerator(id_type initializeId = InvalidId);
        virtual ~IntegerIdGenerator();
        
        virtual id_type getNextId();
    private:
        std::atomic<id_type> _id;
    };
    
    class StringIdGenerator : public virtual IdGeneratorInterface<String> {
    public:
        static const id_type &InvalidId;
        
        StringIdGenerator(id_type initializeId = InvalidId);
        virtual ~StringIdGenerator();
        virtual id_type getNextId();
    };
}

#endif /* IdGenerator_hpp */

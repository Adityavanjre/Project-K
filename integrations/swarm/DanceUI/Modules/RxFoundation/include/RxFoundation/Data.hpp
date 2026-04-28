//
//  Data.hpp
//  RxFoundation
//
//  Created by closure on 11/30/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Data_hpp
#define Data_hpp

#include <RxFoundation/RxObject.hpp>
#include <RxFoundation/Bitfield.hpp>

namespace Rx {
    class Data;
    using DataParamRef = Data *;
    
    class Data : public Object {
    public:
        Data() RX_NOEXCEPT;
        // FreeWhenDone = true, ptr will be deep copy and free when done
        // FreeWhenDone = false, ptr will be use directly
        Data(uint8_t *bytes, Index length, bool needCopy, bool freeWhenDone = true) RX_NOEXCEPT;
        Data(const Data &value) RX_NOEXCEPT;
        Data(Data &&value) RX_NOEXCEPT;
        virtual ~Data() RX_NOEXCEPT;
        
    public:
        const uint8_t *getBytePtr() const RX_NOEXCEPT;
        uint8_t *getMutableBytePtr() const RX_NOEXCEPT;
        
        const Index getLength() const RX_NOEXCEPT;
        Index getLength() RX_NOEXCEPT;
        
        const Index getCapacity() const RX_NOEXCEPT;
        Index getCapacity() RX_NOEXCEPT;
        void setLength(Index length) RX_NOEXCEPT;
        
    public:
        void appendData(const uint8_t *bytes, Index length) RX_NOEXCEPT;
        void appendData(const Data &data) RX_NOEXCEPT;
        void replaceBytes(Range range, const uint8_t *newBytes, Index newLength) RX_NOEXCEPT;
        void deleteBytes(Range range) RX_NOEXCEPT;
        
    public:
        bool writeToFile(String path, bool automatically) RX_NOEXCEPT;
        
    public:
        bool operator==(const Data &rhs) const RX_NOEXCEPT;
        virtual String copyDescription() const RX_NOEXCEPT override;
        virtual HashCode hash() const RX_NOEXCEPT override;
        
    private:
        void __setCapacity(Index capacity) RX_NOEXCEPT;
        void __setLength(Index length) RX_NOEXCEPT;
        
        /* Allocates new block of data with at least numNewValues more bytes than the current length. If clear is true, the new bytes up to at least the new length with be zeroed. */
        void __dataGrow(Data &data, Index numNewValues, bool clear) RX_NOEXCEPT;
        
        Bitfield _flags;
        Index _length;
        Index _capacity;
        UInt8 *_bytes;
    };
}

#endif /* Data_hpp */

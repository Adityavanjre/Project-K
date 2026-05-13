//
//  UnicodeChar.hpp
//  RxFoundation
//
//  Created by closure on 2/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef UniChar_hpp
#define UniChar_hpp

#include <RxFoundation/RxBase.hpp>

namespace Rx {
    class UnicodeChar {
    public:
        static const auto BitShiftForByte =	3;
        static const auto BitShiftForMask =	7;
        
        enum {
            ControlCharacterSet = 1,
            WhitespaceCharacterSet,
            WhitespaceAndNewlineCharacterSet,
            DecimalDigitCharacterSet,
            LetterCharacterSet,
            LowercaseLetterCharacterSet,
            UppercaseLetterCharacterSet,
            NonBaseCharacterSet,
            CanonicalDecomposableCharacterSet,
            DecomposableCharacterSet = CanonicalDecomposableCharacterSet,
            AlphaNumericCharacterSet,
            PunctuationCharacterSet,
            IllegalCharacterSet,
            TitlecaseLetterCharacterSet,
            SymbolAndOperatorCharacterSet,
            NewlineCharacterSet,
            
            CompatibilityDecomposableCharacterSet = 100, // internal character sets begins here
            HFSPlusDecomposableCharacterSet,
            StrongRightToLeftCharacterSet,
            HasNonSelfLowercaseCharacterSet,
            HasNonSelfUppercaseCharacterSet,
            HasNonSelfTitlecaseCharacterSet,
            HasNonSelfCaseFoldingCharacterSet,
            HasNonSelfMirrorMappingCharacterSet,
            ControlAndFormatterCharacterSet,
            CaseIgnorableCharacterSet,
            GraphemeExtendCharacterSet
        };
        
        static RX_INLINE_VISIBILITY UTF32Char getLongCharacterForSurrogatePair(UnicodeChar surrogateHigh, UnicodeChar surrogateLow) RX_NOEXCEPT {
            return (UTF32Char)((((unsigned long)surrogateHigh - 0xD800UL) << 10) + ((unsigned long)surrogateLow - 0xDC00UL) + 0x0010000UL);
        }
    public:
        UnicodeChar(UTF16Char character) : _character(character) {}
    public:
        RX_INLINE_VISIBILITY bool isSurrogateHighCharacter() const RX_NOEXCEPT;
        RX_INLINE_VISIBILITY bool isSurrogateLowCharacter() const RX_NOEXCEPT;
        RX_INLINE_VISIBILITY bool isMemberOf(const uint8_t *bitmap) const RX_NOEXCEPT;
        RX_INLINE_VISIBILITY bool isMemberOf(uint32_t charset) const RX_NOEXCEPT;
        
        RX_INLINE_VISIBILITY void addCharacterToBitmap(uint8_t *bitmap) const RX_NOEXCEPT;
//
//        RX_INLINE_VISIBILITY void RemoveCharacterFromBitmap(UTF16Char theChar, uint8_t *bitmap) RX_NOEXCEPT {
//            bitmap[(theChar) >> BitShiftForByte] &= ~(((uint32_t)1) << (theChar & BitShiftForMask));
//        }

    public:
        RX_INLINE_VISIBILITY operator UniChar() const RX_NOEXCEPT {
            return _character;
        }
        
        RX_INLINE_VISIBILITY UInteger operator+(UInteger val) const RX_NOEXCEPT {
            return _character + val;
        }
        
        RX_INLINE_VISIBILITY UInteger operator-(UInteger val) const RX_NOEXCEPT {
            return _character - val;
        }
    private:
        union {
            UTF16Char _character;
        };
    };
}

#endif /* UniChar_hpp */

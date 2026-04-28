
//
//  CustomStringConvertibleInterface.hpp
//  RxFoundation
//
//  Created by closure on 3/3/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CustomStringConvertibleInterface_h
#define CustomStringConvertibleInterface_h

namespace Rx {
    class String;
    class CustomStringConvertibleInterface {
    public:
        CustomStringConvertibleInterface() RX_NOEXCEPT {}
        virtual ~CustomStringConvertibleInterface() RX_NOEXCEPT {}
    public:
        virtual String copyDescription() const RX_NOEXCEPT = 0;
    };
}

#endif /* CustomStringConvertibleInterface_h */

//
//  RxFoundation.h
//  RxFoundation
//
//  Created by Closure on 7/20/17.
//  Copyright © 2017 Closure. All rights reserved.
//

#include <RxFoundation/DeploymentAvailability.hpp>
#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/RxBaseMacro.hpp>
#include <RxFoundation/type_traits.hpp>
#include <RxFoundation/TypeInfo.hpp>
#include <RxFoundation/AlignOf.hpp>
#include <RxFoundation/EnumAsByte.hpp>
#include <RxFoundation/MethodChecker.hpp>
#include <RxFoundation/CopyDescriptionChecker.hpp>
#include <RxFoundation/HashChecker.hpp>

#include <RxFoundation/ObjectMeta.hpp>

#include <RxFoundation/Allocator.hpp>
#include <RxFoundation/CrashReporter.hpp>
#include <RxFoundation/Atomic.hpp>

#include <RxFoundation/CollectionContainer3.hpp>
#include <RxFoundation/Exception.hpp>

#include <RxFoundation/Memory.hpp>
#include <RxFoundation/SharedPointerInternals.hpp>

#include <RxFoundation/RefPtr.hpp>
#include <RxFoundation/RefCountedBase.hpp>
#include <RxFoundation/Bitfield.hpp>
#include <RxFoundation/ByteOrder.hpp>
#include <RxFoundation/RxObject.hpp>
#include <RxFoundation/Error.hpp>

#include <RxFoundation/Copyable.hpp>
#include <RxFoundation/EpochTracker.hpp>
#include <RxFoundation/NotCopyableInterface.hpp>
#include <RxFoundation/CancellableInterface.hpp>
#include <RxFoundation/CustomStringConvertibleInterface.hpp>
#include <RxFoundation/HashableInterface.hpp>
#include <RxFoundation/KeyValueObserverInterface.hpp>

#include <RxFoundation/CollectionContainer.hpp>
#include <RxFoundation/Any.hpp>
#include <RxFoundation/UnicodeChar.hpp>
#include <RxFoundation/Array.hpp>
#include <RxFoundation/String.hpp>
#include <RxFoundation/Set.hpp>
#include <RxFoundation/OrderedSet.hpp>
#include <RxFoundation/Data.hpp>
#include <RxFoundation/Port.hpp>
#include <RxFoundation/Lists.hpp>
#include <RxFoundation/CallStackArray.hpp>

#include <RxFoundation/ProcessorInfo.hpp>

#if ((TARGET_OS_MAC)||(TARGET_OS_IPHONE)) && defined(__OBJC__)

#include <RxFoundation/objcClassReader.hpp>

#endif

//! Project version number for RxFoundation.
RX_EXPORT double RxFoundationVersionNumber;

//! Project version string for RxFoundation.
RX_EXPORT const unsigned char RxFoundationVersionString[];

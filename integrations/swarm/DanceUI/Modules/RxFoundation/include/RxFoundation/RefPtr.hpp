//
//  RefPtr.h
//  RxFoundation
//
//  Created by closure on 12/16/15.
//  Copyright © 2015 closure. All rights reserved.
//

#ifndef RefPtr_h
#define RefPtr_h

#include <stdint.h>

namespace Rx {
    template<typename ObjectType>
    class RefPtr {
        typedef ObjectType *ReferenceType;
    public:
        RefPtr() : Reference(nullptr) { }

        RefPtr(ReferenceType InReference, bool retain = true) {
            Reference = InReference;
            if (Reference && retain) {
                Reference->retain();
            }
        }

        RefPtr(const RefPtr& Copy) {
            Reference = Copy.Reference;
            if(Reference) {
                Reference->retain();
            }
        }
        
        RefPtr(RefPtr &&Value) RX_NOEXCEPT {
            Reference = Value.Reference;
            Value.Reference = nullptr;
        }

        ~RefPtr() {
            if (Reference) {
                Reference->release();
            }
        }

        RefPtr &operator=(ReferenceType InReference) {
            // Call retain before release, in case the new reference is the same as the old reference.
            ReferenceType OldReference = Reference;
            Reference = InReference;
            if (Reference) {
                Reference->retain();
            }
            if (OldReference) {
                OldReference->release();
            }
            return *this;
        }

        RefPtr &operator=(const RefPtr &InPtr) {
            return *this = InPtr.Reference;
        }

        ReferenceType operator->() const {
            return Reference;
        }

        operator ReferenceType() const {
            return Reference;
        }

        ReferenceType *GetInitReference() {
            *this = nullptr;
            return &Reference;
        }

        ReferenceType getReference() const {
            return Reference;
        }

        friend bool IsValidRef(const RefPtr &InReference) {
            return InReference.Reference != nullptr;
        }

        inline bool isValid() const {
            return Reference != nullptr;
        }
        
        operator bool() const {
            return isValid();
        }

        void safeRelease() {
            *this = nullptr;
        }

        uint32_t getRetainCount() {
            if (Reference) {
                return Reference->getRetainCount();
            } else {
                return 0;
            }
        }

        // this does not change the reference count, and so is faster
        void Swap(RefPtr &InPtr) {
            ReferenceType OldReference = Reference;
            Reference = InPtr.Reference;
            InPtr.Reference = OldReference;
        }
    private:
        ReferenceType Reference;
    };

    template<typename ObjectType>
    inline bool operator==(const RefPtr<ObjectType>& A, const RefPtr<ObjectType>& B) {
        return A.getReference() == B.getReference();
    }
    
    template<typename ObjectType>
    inline bool operator==(const RefPtr<ObjectType>& A, typename RefPtr<ObjectType>::ReferenceType B) {
        return A.getReference() == B;
    }
    
    template<typename ObjectType>
    inline bool operator==(typename RefPtr<ObjectType>::ReferenceType A, const RefPtr<ObjectType>& B) {
        return A == B.getReference();
    }
    
    template<typename ObjectType>
    inline bool operator!=(const RefPtr<ObjectType>& A, const RefPtr<ObjectType>& B) {
        return A.getReference() != B.getReference();
    }
    
    template<typename ObjectType>
    inline bool operator!=(const RefPtr<ObjectType>& A, typename RefPtr<ObjectType>::ReferenceType B) {
        return A.getReference() != B;
    }
    
    template<typename ObjectType>
    inline bool operator!=(typename RefPtr<ObjectType>::ReferenceType A, const RefPtr<ObjectType>& B) {
        return A != B.getReference();
    }
    
//    template<typename ObjectType>
//    class WeakPtr {
//        friend class WeakTable;
//    public:
//        WeakPtr(ObjectType *object) :
//        _object(object) {
//            
//        }
//        
//        WeakPtr(RefPtr<ObjectType> const &ptr) :
//        _object(ptr.getReference()) {
//        }
//        
//    public:
//        bool isValid() const {
//            return false;
//        }
//        
//        ObjectType *operator->() const {
//            RxCheck(isValid());
//            return _object;
//        }
//        
//        ObjectType *get() const {
//            if (isValid()) {
//                return _object;
//            }
//            return nullptr;
//        }
//        
//    private:
//        ObjectType *_object;
//    };
//    
//    template<typename ObjectType>
//    inline bool operator<(const WeakPtr<ObjectType> &A, const WeakPtr<ObjectType> &B) {
//        return A.get() < B.get();
//    }
}

#endif /* RefPtr_h */

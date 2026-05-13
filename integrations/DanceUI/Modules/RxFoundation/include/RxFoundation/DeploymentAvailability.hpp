//
//  DeploymentAvailability.hpp
//  RxFoundation
//
//  Created by closure on 2/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef DeploymentAvailability_hpp
#define DeploymentAvailability_hpp

#ifdef __ANDROID__
    #define DEPLOYMENT_TARGET_MACOSX        0
    #define DEPLOYMENT_TARGET_IPHONEOS      0
    #define DEPLOYMENT_TARGET_LINUX         1
    #define DEPLOYMENT_TARGET_WINDOWS       0
    #define DEPLOYMENT_TARGET_EMBEDDED      DEPLOYMENT_TARGET_IPHONEOS
    #define DEPLOYMENT_TARGET_EMBEDDED_MINI 0
    #define DEPLOYMENT_TARGET_SOLARIS       0
    #define DEPLOYMENT_TARGET_FREEBSD       0
    #define DEPLOYMENT_TARGET_ANDROID       1
#else
    #define DEPLOYMENT_TARGET_MACOSX        1
    #define DEPLOYMENT_TARGET_IPHONEOS      1
    #define DEPLOYMENT_TARGET_LINUX         0
    #define DEPLOYMENT_TARGET_WINDOWS       0
    #define DEPLOYMENT_TARGET_EMBEDDED      DEPLOYMENT_TARGET_IPHONEOS
    #define DEPLOYMENT_TARGET_EMBEDDED_MINI 0
    #define DEPLOYMENT_TARGET_SOLARIS       0
    #define DEPLOYMENT_TARGET_FREEBSD       0
    #define DEPLOYMENT_TARGET_ANDROID       0
#endif

#endif /* DeploymentAvailability_hpp */

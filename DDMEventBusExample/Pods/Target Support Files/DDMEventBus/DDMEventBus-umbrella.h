#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DDMEventBus.h"
#import "EventBusProtocol.h"
#import "EventSubscriberMaker.h"
#import "NSObject+EventBusAutoDispose.h"

FOUNDATION_EXPORT double DDMEventBusVersionNumber;
FOUNDATION_EXPORT const unsigned char DDMEventBusVersionString[];


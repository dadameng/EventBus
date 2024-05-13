//
//  EventBusSubscribable.m
//  
//
//  Created by Meng.Lin on 2024/05/13.
//

#import "NSObject+EventBusSubscribable.h"
#import <objc/runtime.h>

@interface NSObject (EventBusSubscribable)

@property (nonatomic, strong) EventLifeCycleTracker *eventLifeCycleTracker;

- (EventSubscriberMaker *)subscribeToEventClass:(Class)eventClass;
- (EventSubscriberMaker *)subscribeOnBus:(EventBus *)bus toEventClass:(Class)eventClass;
- (EventSubscriberMaker *)subscribeToJSONWithName:(NSString *)name;
- (EventSubscriberMaker *)subscribeToNotificationWithName:(NSString *)name;

@end

@implementation NSObject (EventBusSubscribable)

static const void *EventLifeCycleTrackerKey = &EventLifeCycleTrackerKey;

- (EventLifeCycleTracker *)eventLifeCycleTracker {
    EventLifeCycleTracker *tracker = objc_getAssociatedObject(self, EventLifeCycleTrackerKey);
    if (!tracker) {
        tracker = [[EventLifeCycleTracker alloc] init];
        objc_setAssociatedObject(self, EventLifeCycleTrackerKey, tracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tracker;
}


- (EventSubscriberMaker *)subscribeToEventClass:(Class)eventClass {
    EventSubscriberMaker *maker = [[EventBus sharedBus] onEventClass:eventClass];
    if (self.eventLifeCycleTracker) {
        [maker autoDisposeTokenWith:self.eventLifeCycleTracker];
    }
    return maker;
}

- (EventSubscriberMaker *)subscribeOnBus:(EventBus *)bus toEventClass:(Class)eventClass {
    EventSubscriberMaker *maker = [bus onEventClass:eventClass];
    if (self.eventLifeCycleTracker) {
        [maker autoDisposeTokenWith:self.eventLifeCycleTracker];
    }
    return maker;
}

- (EventSubscriberMaker *)subscribeToJSONWithName:(NSString *)name {
    EventSubscriberMaker *maker = [[EventBus sharedBus] onEventClass:[JSONEvent class] withSubType:name];
    if (self.eventLifeCycleTracker) {
        [maker autoDisposeTokenWith:self.eventLifeCycleTracker];
    }
    return maker;
}

- (EventSubscriberMaker *)subscribeToNotificationWithName:(NSString *)name {
    EventSubscriberMaker *maker = [[EventBus sharedBus] onEventClass:[NSNotification class] withSubType:name];
    if (self.eventLifeCycleTracker) {
        [maker autoDisposeTokenWith:self.eventLifeCycleTracker];
    }
    return maker;
}

@end


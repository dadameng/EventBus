
#import "NSObject+EventBusAutoDispose.h"
#import <DDMEventBus/DDMEventBus-Swift.h>
#import <DDMEventBus/EventSubscriberMaker.h>

@implementation NSObject (EventBusAutoDispose)

- (EventSubscriberMaker *)subscribeToEvent:(Class)eventType {
    EventSubscriberMaker *maker = [EventBus.shared onWithEventType:eventType];
    [maker autoDisposeTokenWith:self.lifeCycleTracker];
    return maker;
}

- (EventSubscriberMaker *)subscribeToEvent:(Class)eventType onBus:(EventBus *)bus {
    EventSubscriberMaker *maker = [bus onWithEventType:eventType];
    [maker autoDisposeTokenWith:self.lifeCycleTracker];
    return maker;
}

- (EventSubscriberMaker *)subscribeToJSONWithName:(NSString *)name {
    EventSubscriberMaker *maker = [[[EventBus shared] onWithEventType:[JSONEvent class]] ofSubType:name];
    [maker autoDisposeTokenWith:self.lifeCycleTracker];
    return maker;
}

- (EventSubscriberMaker *)subscribeToNotificationWithName:(NSString *)name {
    EventSubscriberMaker *maker = [[[EventBus shared] onWithEventType:[NSNotification class]] ofSubType:name];
    [maker autoDisposeTokenWith:self.lifeCycleTracker];
    return maker;
}


@end

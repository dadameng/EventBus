//
//  EventSubscriberMaker.h
//  
//
//  Created by Meng.Lin on 2024/05/13.
//

#import <Foundation/Foundation.h>
#import "EventBusProtocol.h"

@class EventBus;

NS_ASSUME_NONNULL_BEGIN

@interface EventSubscriberMaker<__covariant EventType:id<Event>> : NSObject

- (instancetype)initWithEventBus:(EventBus *)eventBus eventClass:(Class)eventClass;
- (EventSubscriberMaker<EventType> *)next:(void (^)(EventType event))handler;
- (EventSubscriberMaker<EventType> *)atQueue:(dispatch_queue_t)queue;
- (EventSubscriberMaker<EventType> *)autoDisposeTokenWith:(EventLifeCycleTracker *)object;
- (EventSubscriberMaker<EventType> *)ofSubType:(NSString *)eventType;

@end

NS_ASSUME_NONNULL_END

#import <DDMEventBus/DDMEventBus-Swift.h>
#import <DDMEventBus/EventBusProtocol.h>
#import "EventSubscriberMaker.h"

@interface EventSubscriberMaker<EventType> ()

@property (nonatomic, weak) EventBus *eventBus;
@property (nonatomic) Class eventClass;
@property (nonatomic, copy, nullable) void (^ handler)(EventType event);
@property (nonatomic, strong, nullable) dispatch_queue_t queue;
@property (nonatomic, weak, nullable) EventLifeCycleTracker *lifeTimeTracker;
@property (nonatomic, strong) NSMutableArray<NSString *> *eventSubTypes;

@end

@implementation EventSubscriberMaker

- (instancetype)initWithEventBus:(EventBus *)eventBus eventClass:(Class)eventClass {
    self = [super init];

    if (self) {
        _eventBus = eventBus;
        _eventClass = eventClass;
        _eventSubTypes = [NSMutableArray array];
    }

    return self;
}

- (id<EventSubscribeToken>)next:(void (^)(id event))handler {
    self.handler = handler;
    return [self.eventBus createNewObjCSubscriberWith:self];
}

- (EventSubscriberMaker *)atQueue:(dispatch_queue_t)queue {
    self.queue = queue;
    return self;
}

- (EventSubscriberMaker *)autoDisposeTokenWith:(EventLifeCycleTracker *)object {
    self.lifeTimeTracker = object;
    return self;
}

- (EventSubscriberMaker *)ofSubType:(NSString *)eventType {
    [self.eventSubTypes addObject:eventType];
    return self;
}

- (EventSubscriberMaker<id> * (^)(dispatch_queue_t queue))atQueueClosure {
    return ^EventSubscriberMaker<id<Event> > *(dispatch_queue_t queue) {
               return [self atQueue:queue];
    };
}

- (EventSubscriberMaker<id> * (^)(NSString *eventType))ofSubTypeClosure {
    return ^EventSubscriberMaker *(NSString *eventType) {
               return [self ofSubType:eventType];
    };
}

- (EventSubscriberMaker<id> * (^)(EventLifeCycleTracker *object))autoDisposeTokenWithClosure {
    return ^EventSubscriberMaker *(EventLifeCycleTracker *object) {
               return [self autoDisposeTokenWith:object];
    };
}

- (EventSubscriber *)makeWithUniqueId:(NSString *)uniqueId {
    EventSubscriber *subscriber = [[EventSubscriber alloc] initWithEventClass:self.eventClass uniqueId:uniqueId];

    subscriber.subscriberQueue = self.queue;
    subscriber.handler = ^(id<Event> event) {
        if (self.handler) {
            self.handler(event);
        }
    };
    subscriber.eventSubTypes = self.eventSubTypes;

    if (self.lifeTimeTracker) {
        subscriber.eventLifeCycleTracker = self.lifeTimeTracker;
    }

    return subscriber;
}

@end

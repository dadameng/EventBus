#import <Foundation/Foundation.h>
#import <DDMEventBus/EventBusProtocol.h>

@class EventLifeCycleTracker;
@class EventBus;
@class EventSubscriber;

NS_ASSUME_NONNULL_BEGIN

@interface EventSubscriberMaker<EventType> : NSObject <EventSubscriberMaking>
- (instancetype)initWithEventBus:(EventBus *)eventBus eventClass:(Class)eventClass;

@property (nonatomic, copy) EventSubscriberMaker<EventType> * (^ atQueueClosure)(dispatch_queue_t queue);
@property (nonatomic, copy) EventSubscriberMaker<EventType> * (^ ofSubTypeClosure)(NSString *eventType);
@property (nonatomic, copy) EventSubscriberMaker<EventType> * (^ autoDisposeTokenWithClosure)(EventLifeCycleTracker *object);

@property (nonatomic, readonly) Class eventClass;
@property (nonatomic, copy, nullable, readonly) void (^ handler)(EventType event);
@property (nonatomic, strong, nullable, readonly) dispatch_queue_t queue;
@property (nonatomic, weak, nullable, readonly) EventLifeCycleTracker *lifeTimeTracker;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> *eventSubTypes;

- (id<EventSubscribeToken>)next:(void (^)(EventType event))handler;
- (EventSubscriber *)makeWithUniqueId:(NSString *)uniqueId;

@end

NS_ASSUME_NONNULL_END

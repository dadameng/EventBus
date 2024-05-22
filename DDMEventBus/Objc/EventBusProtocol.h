#import <Foundation/Foundation.h>

@class EventLifeCycleTracker;
NS_ASSUME_NONNULL_BEGIN

@protocol Event <NSObject>

+ (Class)eventClass;
@optional
- (NSString *)subtypeOfEvent;
@end

@protocol EventSubscribeToken <NSObject>

- (void)dispose;

@end

@protocol EventSubscriberMaking <NSObject>

- (id<EventSubscribeToken>)next:(void (^)(id<Event> event))handler;
- (instancetype)atQueue:(dispatch_queue_t)queue;
- (instancetype)autoDisposeTokenWith:(EventLifeCycleTracker *)object;
- (instancetype)ofSubType:(NSString *)eventType;

@end


NS_ASSUME_NONNULL_END

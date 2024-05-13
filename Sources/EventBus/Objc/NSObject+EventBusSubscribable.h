//
//  EventBusSubscribable.h
//  
//
//  Created by Meng.Lin on 2024/05/13.
//

#import <Foundation/Foundation.h>
#import "EventBusProtocol.h"
#import "EventSubscriberMaker.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (EventBusSubscribable)

@property (nonatomic, strong) EventLifeCycleTracker *eventLifeCycleTracker;

- (EventSubscriberMaker *)subscribeToEventClass:(Class)eventClass;
- (EventSubscriberMaker *)subscribeOnBus:(EventBus *)bus toEventClass:(Class)eventClass;
- (EventSubscriberMaker *)subscribeToJSONWithName:(NSString *)name;
- (EventSubscriberMaker *)subscribeToNotificationWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

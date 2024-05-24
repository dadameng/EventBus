//
//  NSObject.h
//  DDMEventBus
//
//  Created by Meng.Lin on 2024/05/24.
//

#import <Foundation/Foundation.h>
@class EventBus;
@class EventSubscriberMaker;
NS_ASSUME_NONNULL_BEGIN

@interface NSObject (EventBusAutoDispose)

- (EventSubscriberMaker *)subscribeToEvent:(Class)eventType;
- (EventSubscriberMaker *)subscribeToEvent:(Class)eventType onBus:(EventBus *)bus;
- (EventSubscriberMaker *)subscribeToJSONWithName:(NSString *)name;
- (EventSubscriberMaker *)subscribeToNotificationWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

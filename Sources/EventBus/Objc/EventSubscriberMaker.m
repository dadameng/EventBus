//
//  EventSubscriberMaker.m
//  
//
//  Created by Meng.Lin on 2024/05/13.
//

#import "EventSubscriberMaker.h"

@interface EventSubscriberMaker()

@property (nonatomic, strong, nullable) dispatch_queue_t queue;
@property (nonatomic, weak, nullable) id<EventLifeCycleTracker> lifeTimeTracker;
@property (nonatomic, copy, nullable) void (^handler)(EventType event);
@property (nonatomic, strong) NSMutableArray<NSString *> *eventSubTypes;

@end

@implementation EventSubscriberMaker

@end


#import "TestController.h"
@import DDMEventBus;

@interface OCEvent : NSObject

@property (nonatomic, copy) NSString *priveteNumber;

@end

@implementation OCEvent


@end

@implementation TestController

- (void)test {
    [[self subscribeToEvent:OCEvent.class] next:^(id  _Nonnull event) {
        
    }];
}

@end

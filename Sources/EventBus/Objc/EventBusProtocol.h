//
//  EventBusProtocol.h
//  
//
//  Created by Meng.Lin on 2024/05/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol Event <NSObject>

+ (Class)eventClass;

@optional
- (NSString *)subtypeOfEvent;

@end

@protocol EventSubscribeToken <NSObject>

- (void)dispose;

@end


NS_ASSUME_NONNULL_END

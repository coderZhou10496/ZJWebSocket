//
//  ZJSocketRegisterProtocol.h
//  ZJWebSocket
//
//  Created by zhoujian on 2019/4/6.
//  Copyright © 2019年 zhoujian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZJSocketRegisterProtocol <NSObject>

- (void)didReceiveMessage:(NSDictionary *)messageDic;

@end

NS_ASSUME_NONNULL_END

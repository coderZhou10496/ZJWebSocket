//
//  ZJMessageHandler.m
//  ZJWebSocket
//
//  Created by zhoujian on 2019/4/6.
//  Copyright © 2019年 zhoujian. All rights reserved.
//

#import "ZJMessageHandler.h"

@implementation ZJMessageHandler

// 在这里可以分业务对消息进行处理，然后传给不同的业务层
- (void)didReceiveMessage:(NSDictionary *)messageDic {
    /*
     注意：此时还在子线程中
     */
    
    /**  处理数据 */
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}
@end

//
//  ViewController.m
//  ZJWebSocket
//
//  Created by zhoujian on 2019/4/6.
//  Copyright © 2019年 zhoujian. All rights reserved.
//

#import "ViewController.h"
#import "ZJMessageHandler.h"
#import "ZJSocketManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ZJMessageHandler *msgHandler = [[ZJMessageHandler alloc] init];
    
    [[ZJSocketManager shared] webSocketOpen];
    [[ZJSocketManager shared] registerMsgHandler:msgHandler];
    
}

- (void)dealloc {
    [[ZJSocketManager shared] webSocketClose];
    [[ZJSocketManager shared] unRegisterHandler];
}
@end

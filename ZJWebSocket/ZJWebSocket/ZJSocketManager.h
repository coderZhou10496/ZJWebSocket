//
//  ZJSocketManager.h
//  ZJWebSocket
//
//  Created by zhoujian on 2019/4/6.
//  Copyright © 2019年 zhoujian. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZJSocketRegisterProtocol.h"
typedef NS_ENUM(NSUInteger,WebSocketConnectType){
    WebSocketDefault = 0, //初始状态,未连接
    WebSocketConnect,      //已连接
    WebSocketDisconnect    //连接后断开，如果是这个状态需要重连
};

@interface ZJSocketManager : NSObject

@property (nonatomic, assign) WebSocketConnectType connectType;

@property (nonatomic, copy) void(^connectStatusChange)(WebSocketConnectType type);

+ (instancetype)shared;

- (void)webSocketOpen;

- (void)webSocketClose;

- (void)sendData:(id)data;

- (void)registerMsgHandler:(id<ZJSocketRegisterProtocol>)handler;

- (void)unRegisterHandler;
@end



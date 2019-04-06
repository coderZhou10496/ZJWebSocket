//
//  ZJSocketManager.m
//  ZJWebSocket
//
//  Created by zhoujian on 2019/4/6.
//  Copyright © 2019年 zhoujian. All rights reserved.
//

#import "ZJSocketManager.h"
#import "SRWebSocket.h"
#import "AFNetworkReachabilityManager.h"

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

#define WS_URL @"" // WebSocket服务端地址

@interface ZJSocketManager()<SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;

@property (nonatomic, strong) dispatch_queue_t delegateRecQueue; // 接收代理方法的队列

@property (nonatomic, strong) NSTimer *heartBeat;

@property (nonatomic, assign) NSInteger reConnectTime;

@property (nonatomic, assign) BOOL isActivelyClose; // 是否主动关闭连接

@property (nonatomic, weak) id <ZJSocketRegisterProtocol>registerModel;
@end

@implementation ZJSocketManager

+ (instancetype)shared {
    static ZJSocketManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ZJSocketManager alloc] init];
    });
    return manager;
}
- (id)init {
    if(self = [super init]) {
        self.delegateRecQueue = dispatch_queue_create("com.zj.socket.queue",DISPATCH_QUEUE_SERIAL);
        self.reConnectTime = 1;
    }
    return self;
}
- (void)registerMsgHandler:(id<ZJSocketRegisterProtocol>)handler {
    self.registerModel = handler;
}
- (void)unRegisterHandler {
    self.registerModel = nil;
}
- (void)setConnectStatusChange:(void (^)(WebSocketConnectType))connectStatusChange {
    _connectStatusChange = connectStatusChange;
}

//开始连接
- (void)webSocketOpen {
    
    dispatch_main_async_safe(^{
        
        [self webSocketClose];
        
        self.isActivelyClose = NO;
        NSURL *url = [NSURL URLWithString:WS_URL];
        self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:url]];
        self.webSocket.delegate = self;
        [self.webSocket setDelegateDispatchQueue:self.delegateRecQueue];
        [self.webSocket open];
        
    })
    
}
//重新连接
- (void)reConnect {
    if(self.connectType == WebSocketConnect) {
        return;
    }
    [self webSocketClose];
    
    if (self.reConnectTime >= 32) {
        self.reConnectTime = 1;
        return;
    }
    
    __block NSInteger time = self.reConnectTime;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"重连");
        time = time * 2;
        self.reConnectTime = time;
        [self webSocketOpen];
    });
}
//关闭连接
- (void)webSocketClose {
    self.connectType = WebSocketDefault;
    _connectStatusChange ? _connectStatusChange(self.connectType) : nil;
    [self cancelHeartBeat];
    if (self.webSocket){
        self.isActivelyClose = YES;
        [self.webSocket close];
        self.webSocket = nil;
    }
}

#pragma mark - SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if(dic) {
        [self.registerModel didReceiveMessage:dic];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"连接成功");
    self.connectType = WebSocketConnect;
    
    [self createHeartBeat];
    _connectStatusChange ? _connectStatusChange(self.connectType) : nil;
    
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"连接失败 %@",error);
    if(self.isActivelyClose == YES) {
        self.connectType = WebSocketDefault;
        _connectStatusChange ? _connectStatusChange(self.connectType) : nil;
        return;
    }
    self.connectType = WebSocketDisconnect;
    _connectStatusChange ? _connectStatusChange(self.connectType) : nil;
    if([self netWorkReachable]) {
        [self reConnect];
    }
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if(self.isActivelyClose) {
        self.connectType = WebSocketDefault;
        _connectStatusChange ? _connectStatusChange(self.connectType) : nil;
        return;
    }
    self.connectType = WebSocketDisconnect;
    _connectStatusChange ? _connectStatusChange(self.connectType) : nil;
    if([self netWorkReachable]) {
        [self reConnect];
    }
    
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
    NSLog(@"收到pong");
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:pongPayload options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"%@",dic);
}
#pragma mark - 发送数据
- (void)sendData:(id)data {
    if([self netWorkReachable] == NO) {
        return;
    }
    if (self.webSocket != nil) {
        if (self.webSocket.readyState == SR_OPEN) {
            
            [self.webSocket send:data];
            NSLog(@"已发送数据");
            
        } else if (self.webSocket.readyState == SR_CONNECTING) {
            NSLog(@"发送数据失败");
            
        } else if (self.webSocket.readyState == SR_CLOSING || self.webSocket.readyState == SR_CLOSED) {
            NSLog(@"发送数据失败");
            [self reConnect];
            
        }
    } else {
        NSLog(@"没网络，发送失败");
    }
    
}
#pragma mark - 发送心跳
- (void)sendPing {
    if([self netWorkReachable]) {
        NSDictionary *dicData = @{};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dicData options:NSJSONWritingPrettyPrinted error:nil];
        [self.webSocket sendPing:data];
    }
    
}
- (void)heartBeatFire {
    [self sendPing];
}
#pragma mark - 心跳定时器
- (void)createHeartBeat {
    dispatch_main_async_safe(^{
        [self cancelHeartBeat];
        
        self.heartBeat = [NSTimer timerWithTimeInterval:30 target:self selector:@selector(heartBeatFire) userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop]addTimer:self.heartBeat forMode:NSRunLoopCommonModes];
    })
}
//取消心跳
- (void)cancelHeartBeat {
    dispatch_main_async_safe(^{
        if (self.heartBeat) {
            [self.heartBeat invalidate];
            self.heartBeat = nil;
        }
    })
}

- (BOOL)netWorkReachable {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}
@end

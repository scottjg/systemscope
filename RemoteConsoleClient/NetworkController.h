//
//  NetworkController.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/29/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "glue.h"
#import "protocol.h"
#import "osx_glue.h"

@class AsyncSocket;
@class WebLoginController;

@interface NetworkController : NSObject
{
    AsyncSocket *ctrlSocket;
    AsyncSocket *videoSocket;
    
    NSUInteger modifierFlags;
    
    NSString *hostname;
    UInt16 ctrlPort;
    UInt16 videoPort;
    UInt16 webPort;
    NSString *username;
    NSString *password;
    NSTimer *keepaliveTimer;
    client_ctx *ctx;
    
    BOOL gotFirstVideoFrame;
    
    WebLoginController *webLoginController;
}
@property (nonatomic, weak) id delegate;

- (void)probeHost:(NSString *)host onPort:(UInt16)_port;
- (void)connectToHost:(NSString *)host onPort:(UInt16)port withUser:(NSString *)user password:(NSString *)password;
- (void)sendAppleKeyCode:(unsigned short)keycode keyDown:(BOOL)down;
- (void)sendAppleModifierKeys:(NSUInteger)flags;
- (void)sendMouseEventLocation:(NSPoint)mouseLocation windowHeight:(NSUInteger)height windowWidth:(NSUInteger)width buttons:(UInt32)buttons buttonChanged:(NSUInteger)buttonChanged;
- (void)endConnection;
- (void)connectToCtrlPort:(UInt16)_ctrlPort videoPort:(UInt16)_videoPort username:(NSString *)_user password:(NSString *)_pass dracType:(drac_type_t)dracType;

- (void)powerOn:(id)sender;
- (void)powerOff:(id)sender;
- (void)warmReset:(id)sender;
- (void)coldReset:(id)sender;

-(NSString *)sslWarning;
-(BOOL)powerOpsSupported;
- (void)showNetworkErrorTitle:(NSString *)err description:(NSString *)desc;
- (void)dracTypeDetected:(drac_type_t)dracType;
@end


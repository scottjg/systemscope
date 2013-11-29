//
//  NetworkController.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/29/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//


#import "NetworkController.h"
#import "WebLoginController.h"
#import "ScreenWindowController.h"
#import "DiagnosticLog.h"
#import "AsyncSocket.h"

#import "keycodes.h"
#import "osx_glue.h"
#import "protocol.h"

#define LEFT_SHIFT   0x20002
#define RIGHT_SHIFT  0x20004
#define LEFT_ALT     0x80020
#define RIGHT_ALT    0x80040
#define LEFT_CTRL    0x40001
#define RIGHT_CTRL   0xFFFFF //not on my laptop??
#define CAPS_LOCK    0x10000
#define LEFT_APPLE  0x100008
#define RIGHT_APPLE 0x100010
#define ALL_MODIFIERS (LEFT_SHIFT|RIGHT_SHIFT|LEFT_ALT|RIGHT_ALT|LEFT_CTRL|CAPS_LOCK|LEFT_APPLE|RIGHT_APPLE)

@implementation NetworkController

- (id)init
{
    self = [super init];
    if (self) {
        ctrlSocket  = [[AsyncSocket alloc] initWithDelegate:self];
        videoSocket = [[AsyncSocket alloc] initWithDelegate:self];
        ctx = (client_ctx *)alloc_client_ctx(ctrlSocket, videoSocket);
    }
    return self;
}

- (void)endConnection
{
    if (modifierFlags & ALL_MODIFIERS)
        [self updateModifiers:0 withTimeout:5 tag:123];
    else
        [self cleanup];
}

- (void)cleanup
{
    [keepaliveTimer invalidate];
    keepaliveTimer = nil;

    if (ctrlSocket != nil) {
        [ctrlSocket disconnect];
        ctrlSocket.delegate = nil;
        ctrlSocket = nil;
    }
    if (videoSocket != nil) {
        [videoSocket disconnect];
        videoSocket.delegate = nil;
        videoSocket = nil;
    }
    free_client_ctx((osx_client_ctx *)ctx);
}

- (void)connectToHost:(NSString *)host onPort:(UInt16)_port withUser:(NSString *)user password:(NSString *)pass
{
    hostname = host;
    ctrlPort = _port;
    videoPort = _port;
    username = user;
    password = pass;
    gotFirstVideoFrame = NO;
    
    webLoginController = [[WebLoginController alloc] init];
    webLoginController.delegate = self;
    [webLoginController startRequest:host onPort:443 user:username password:password];
}

- (void)probeHost:(NSString *)host onPort:(UInt16)_port
{
    hostname = host;
    gotFirstVideoFrame = NO;
    
    webLoginController = [[WebLoginController alloc] init];
    webLoginController.delegate = self;
    [webLoginController startProbe:host onPort:_port];

}

- (void)dracTypeDetected:(drac_type_t)dracType
{
    [self.delegate dracTypeProbed:dracType];
}

- (void)connectToCtrlPort:(UInt16)_ctrlPort videoPort:(UInt16)_videoPort username:(NSString *)_user password:(NSString *)_pass dracType:(drac_type_t)dracType
{
    NSError *err;
    
    ctx->dracType = dracType;

    username = _user;
    password = _pass;
    ctrlPort = _ctrlPort;
    videoPort = _videoPort;
    if (![ctrlSocket connectToHost:hostname onPort:ctrlPort error:&err]) {
        [self.delegate showNetworkErrorTitle:@"Connection Error" description:[err description]];
    }
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)_port
{
    
    NSLog(@"Connected To %@:%i.", host, _port);
    if (sock == ctrlSocket) {
        [self.delegate updateProgress:2 withString:@"Connected, Waiting for response..."];
        connect_start_ctrl(ctx,
                           (char *)[username cStringUsingEncoding:NSUTF8StringEncoding],
                           (char *)[password cStringUsingEncoding:NSUTF8StringEncoding]);
    } else if (sock == videoSocket) {
        [self.delegate updateProgress:4 withString:@"Video Connected, Waiting for response..."];
        connect_start_video(ctx);
        keepaliveTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(sendKeepalive:) userInfo:nil repeats:YES];
    }
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"disconnected with error: %@", err);
    if (err)
        [self showNetworkErrorTitle:@"Lost Connection" description:[err localizedDescription]];
    else
        [self showNetworkErrorTitle:@"Lost Connection" description:@"Server hung up unexpectedly"];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"disconnected normally");
    [webLoginController logout];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (sock == ctrlSocket) {
        //NSLog(@"got ctrl data length=%zu", [data length]);
        int r = incoming_data_ctrl(ctx, (uint8_t *)[data bytes], [data length]);
        if (r == NEED_TO_CONNECT_VIDEO) {
            NSError *err = nil;
            [self.delegate updateProgress:3 withString:@"Login OK, Connecting Video..."];

            if (![videoSocket connectToHost:hostname onPort:videoPort error:&err]) {
                NSLog(@"Error connecting for video: %@", [err localizedDescription]);
                [self.delegate showNetworkErrorTitle:@"Video connection Error" description:[err description]];
            }
        } else if (r == NEW_FRAME_READY) {
            if (gotFirstVideoFrame == NO) {
                gotFirstVideoFrame = YES;
                [self.delegate updateProgress:5 withString:@"All set!"];
            }
            [self.delegate newVideoFrameReady:ctx->framebuffer withWidth:ctx->width andHeight:ctx->height];
        } else if (r <= ERR_LOGIN_FAILURE && r >= ERR_LOGIN_FAILURE_MAX) {
            NSString *str;
            switch (r)
            {
                case -11:
                    str = @"Invalid username";
                    break;
                case -12:
                    str = @"Invalid password";
                    break;
                case -13:
                    str = @"Invalid Username or Password";
                    break;
                default:
                    str = [NSString stringWithFormat:@"Connection Error (%d)", r];
                    break;
            }
            [self.delegate showNetworkErrorTitle:@"Video Authentication Error" description:str];
        }
    } else if (sock == videoSocket) {
        //NSLog(@"got video data length=%zu", [data length]);
        int r = incoming_data_video(ctx, (uint8_t *)[data bytes], [data length]);
        if (r == NEW_FRAME_READY) {
            if (gotFirstVideoFrame == NO) {
                gotFirstVideoFrame = YES;
                [self.delegate updateProgress:5 withString:@"All set!"];
            }
            [self.delegate newVideoFrameReady:ctx->framebuffer withWidth:ctx->width andHeight:ctx->height];
            //static long long prev;
            //long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
            //if (now > prev + 100) {
            //    [[self window] display];
            //    prev = now;
            //}
        }
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if (tag == 123)
        [self cleanup];
}


- (NSTimeInterval)onSocket:(AsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length;
{
    if (tag == 123)
        [self cleanup];
    return 0;
}


- (void)sendAppleKeyCode:(unsigned short)keycode keyDown:(BOOL)down
{
    if (!gotFirstVideoFrame) return;
    keycode = appleKeyCodeToUSBKeycode(keycode);
    send_key(ctx, keycode, down ? 1 : 0);
}

- (void)sendAppleModifierKeys:(NSUInteger)flags
{
    [self updateModifiers:flags withTimeout:-1 tag:1];
}

- (void)updateModifiers:(NSUInteger)flags withTimeout:(NSInteger)timeout tag:(NSInteger)tag;
{
    if (!gotFirstVideoFrame) return;
    
    //NSLog(@"%@ %@ - %@", self.className, NSStringFromSelector(_cmd), event);
    unsigned short keycode;
    NSUInteger flag_diff = flags ^ modifierFlags;
    
    while (1)
    {
        NSUInteger curr_flag;
        if ((flag_diff & LEFT_SHIFT) == LEFT_SHIFT) {
            keycode = 225;
            curr_flag = LEFT_SHIFT;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & RIGHT_SHIFT) == RIGHT_SHIFT) {
            keycode = 229;
            curr_flag = RIGHT_SHIFT;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & LEFT_ALT) == LEFT_ALT) {
            keycode = 226;
            curr_flag = LEFT_ALT;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & RIGHT_ALT) == RIGHT_ALT) {
            keycode = 230;
            curr_flag = RIGHT_ALT;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & LEFT_CTRL) == LEFT_CTRL) {
            keycode = 224;
            curr_flag = LEFT_CTRL;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & RIGHT_CTRL) == RIGHT_CTRL) {
            keycode = 228;
            curr_flag = RIGHT_CTRL;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & CAPS_LOCK) == CAPS_LOCK) {
            keycode = 57;
            curr_flag = CAPS_LOCK;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & LEFT_APPLE) == LEFT_APPLE) {
            keycode = 0xe3;
            curr_flag = LEFT_APPLE;
            flag_diff &= ~curr_flag;
        } else if ((flag_diff & RIGHT_APPLE) == RIGHT_APPLE) {
            keycode = 0xe7;
            curr_flag = RIGHT_APPLE;
            flag_diff &= ~curr_flag;
        } else
            break;

        send_key(ctx, keycode, (flags & curr_flag) ? 1 : 0);
    }
    modifierFlags = flags;

}

- (void)sendMouseEventLocation:(NSPoint)mouseLocation windowHeight:(NSUInteger)height windowWidth:(NSUInteger)width buttons:(UInt32)buttons buttonChanged:(NSUInteger)buttonChanged
{
    if (!gotFirstVideoFrame) return;
    if (mouseLocation.x < 0 || mouseLocation.x > width)
        return;
    if (mouseLocation.y < 0 || mouseLocation.y > height)
        return;

    UInt8 mouseButtonState = buttons;
    send_mouse(ctx, mouseLocation.x, mouseLocation.y, mouseButtonState,buttonChanged);
}

- (void)powerOn:(id)sender
{
    send_power_command(ctx, 1);
}

- (void)powerOff:(id)sender
{
    send_power_command(ctx, 2);
}

- (void)warmReset:(id)sender
{
    send_power_command(ctx, 4);
}

- (void)coldReset:(id)sender
{
    send_power_command(ctx, 3);
}

- (void)sendKeepalive:(id)sender
{
    send_keepalive(ctx);
}

- (NSString *)sslWarning
{
    if (ctx->dracType == DRAC4)
        return @"This hardware revision does not support end-to-end encryption.";
    
    if (!ctx->video_ssl)
        return @"Video encryption disabled.";
    
    if (!ctx->ctrl_ssl)
        return @"Encryption disabled.";
    
    return nil;
}

- (BOOL)powerOpsSupported
{
    if (ctx->dracType == DRAC4)
        return NO;
    else
        return YES;
}

- (void)showNetworkErrorTitle:(NSString *)err description:(NSString *)desc;
{
    [webLoginController logout];
    [self.delegate showNetworkErrorTitle:err description:desc];
}

@end

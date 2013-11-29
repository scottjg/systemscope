//
//  ScreenView.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/17/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "osx_glue.h"

@class AsyncSocket;

@interface ScreenView : NSView
{
    uint32_t *framebuffer;
    NSUInteger width;
    NSUInteger height;

    uint8_t clicked;
    NSPoint mouseLocation;
}

@property (assign) client_ctx *ctx;
@property (nonatomic, weak) id delegate;

- (void)renderNewFrame:(uint32_t *)framebuffer withWidth:(NSUInteger)width andHeight:(NSUInteger)height;

@end

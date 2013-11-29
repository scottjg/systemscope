//
//  ScreenView.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/17/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import "ScreenView.h"
#import "AsyncSocket.h"

#import "osx_glue.h"
#import "decoder.h"
#import "keycodes.h"
@implementation ScreenView

- (id)init
{
    self = [super init];
    if (self) {
        framebuffer = NULL;
        width = 0;
        height = 0;
    }
    return self;
}

- (void)renderNewFrame:(uint32_t *)_framebuffer withWidth:(NSUInteger)_width andHeight:(NSUInteger)_height
{
    framebuffer = _framebuffer;
    width = _width;
    height = _height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imagecontext = CGBitmapContextCreate(framebuffer, width, height,
                                                      8,
                                                      sizeof(uint32_t) * width, colorSpace,
                                                      kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    CGImageRef imageRef = CGBitmapContextCreateImage(imagecontext);

    //self.layer.magnificationFilter = kCAFilterNearest;
    self.layer.contents = (id)CFBridgingRelease(imageRef);
    CGContextRelease(imagecontext);
}

-(void)rightMouseDown:(NSEvent *)event
{
    //XXX no idea how to get this passed to ScreenWindowController automatically.
    [self.delegate rightMouseDown:event];
}

@end

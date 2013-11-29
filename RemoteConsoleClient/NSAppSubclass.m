//
//  NSAppSubclass.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/30/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import "NSAppSubclass.h"
#import "ScreenWindowController.h"
@implementation NSAppSubclass

- (void) sendEvent:(NSEvent *)event {
    NSEventType type = [event type];
    if (type == NSKeyUp || type == NSKeyDown || type == NSFlagsChanged)
    {
        id windowController = [[NSApp keyWindow] delegate];

        // swallow all keystrokes, including hotkeys like Apple-Q if video started
        if (windowController && [windowController isKindOfClass:[ScreenWindowController class]] && [windowController videoStarted]) {
            if (type == NSKeyUp)
                [windowController keyUp:event];
            else if (type == NSKeyDown)
                [windowController keyDown:event];
            else if (type == NSFlagsChanged)
                [windowController flagsChanged:event];
            return;
        }
    }

    [super sendEvent:event];
}

@end

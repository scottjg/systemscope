//
//  AppDelegate.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/16/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <HockeySDK/HockeySDK.h>

#include "osx_glue.h"

@class AsyncSocket;
@class ConnectionLoginController;
@class ScreenView;
@class ScreenWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>//, BITHockeyManagerDelegate>
{
    NSMutableSet *windowSet;
}
@property (assign) IBOutlet ScreenView *screenView;

- (IBAction)newConnectionWindow:(id)sender;
- (IBAction)saveDiagnosticLog:(id)sender;
@end

//
//  AppDelegate.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/16/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//
#import <DevMateKit/DevMateKit.h>

#import "AppDelegate.h"
#import "AsyncSocket.h"
#import "ConnectionLoginController.h"
#import "DiagnosticLog.h"
#import "ScreenView.h"
#import "ScreenWindowController.h"

#import "osx_glue.h"
#import "protocol.h"
#import "decoder.h"

@implementation AppDelegate

- (void)awakeFromNib
{
    windowSet = [[NSMutableSet alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowClosing:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];

    [self newConnectionWindow:self];
}

- (IBAction)newConnectionWindow:(id)sender
{
    ScreenWindowController *window = [[ScreenWindowController alloc] init];
    [windowSet addObject:window];
    [window showWindow:self];
    //[window showConnectionSheet];
}

- (IBAction)saveDiagnosticLog:(id)sender
{
    [DiagnosticLog dumpToFile];
}

- (void)windowClosing:(NSNotification*)notification
{
    ScreenWindowController *windowController = [[notification object] delegate];
    if (![windowSet member:windowController])
        return;
    
    [windowSet removeObject:windowController];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DiagnosticLog setup];
    [DevMateKit sendTrackingReport:nil delegate:nil];
    [DevMateKit setupIssuesController:nil reportingUnhandledIssues:YES];
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [SUUpdater sharedUpdater].automaticallyChecksForUpdates = YES;
    [SUUpdater sharedUpdater].automaticallyDownloadsUpdates = YES;
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    /*
    NSString* urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ScreenWindowController *window = [[ScreenWindowController alloc] init];
    [windowSet addObject:window];
    [window setHost:[url host] withUser:[url user] withPassword:[url password]];
    [window showWindow:self];
    [window startConnectionWithHost:[url host] withPort:443 withUser:[url user] withPassword:[url password]];
     */
}
//
//- (BOOL)updaterShouldCheckForBetaUpdates:(SUUpdater *)updater
//{
//    return YES;
//}
//
//- (BOOL)isUpdaterInTestMode:(SUUpdater *)updater
//{
//    return YES;
//}
//

@end

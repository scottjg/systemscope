//
//  ScreenWindowController.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/29/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "glue.h"

@class AsyncSocket;
@class ConnectionLoginController;
@class NetworkController;

@interface ScreenWindowController : NSWindowController <NSToolbarDelegate>
{
    BOOL gotFirstVideoFrame;
    
    ConnectionLoginController *connectionSheet;
    NetworkController *network;
    
    NSToolbarItem *powerButton, *actualSizeButton, *keyboardButton, *lockButton;
    NSToolbarItem *addressBar;
    NSTextField *addressBarTextField;
    NSToolbar *toolbar;

    NSUInteger height, width;
    float scaleFactor;
    
    void *oldHotKeyMode;
}

@property (assign) IBOutlet NSProgressIndicator *progressBar;
@property (assign) IBOutlet id connectingLabel;


//- (void)onConnectFailure:(NSError *)err;
- (void)dracTypeProbed:(drac_type_t)dracType;
- (void)updateProgress:(NSInteger)progress withString:(NSString *)string;
- (void)newVideoFrameReady:(uint32_t *)framebuffer withWidth:(NSUInteger)width andHeight:(NSUInteger)height;
- (BOOL)videoStarted;

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

- (void)showNetworkErrorTitle:(NSString *)err description:(NSString *)desc;
- (void)showConnectionLogin;
- (void)startConnectionWithHost:(NSString *)host withPort:(UInt16)port withUser:(NSString *)user withPassword:(NSString *)password;
@end

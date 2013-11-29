//
//  ScreenWindowController.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/29/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Carbon/Carbon.h>

#import "ScreenWindowController.h"
#import "ConnectionLoginController.h"
#import "ScreenView.h"
#import "NetworkController.h"


@interface ScreenWindowController ()

@end

@implementation ScreenWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"ScreenWindow"];
    if (self) {
        ScreenView *screenView = (ScreenView *)[[self window] contentView];
        screenView.delegate = self;
        network = [[NetworkController alloc] init];
        network.delegate = self;

        [self setupToolbar];
        [self setToolbarEnabled:NO];

        width = 0;
        height = 0;
        scaleFactor = 1.0;
        
        gotFirstVideoFrame = false;
        //draw a black screen
        uint32_t tmp = 0;
        [screenView renderNewFrame:&tmp withWidth:1 andHeight:1];

        [self window].titleVisibility = NSWindowTitleHidden;
        [[self window] setAcceptsMouseMovedEvents:YES];
        connectionSheet = [[ConnectionLoginController alloc] initWithWindowNibName:@"ConnectionLoginDialog"];
        [connectionSheet window]; //forces dialog to be instantiated
                                  //so we can set fields on the form
    }
    return self;
}

- (void)showConnectionLogin
{
    [connectionSheet.dialogLabel setStringValue:[NSString stringWithFormat:@"Enter your username and password for the server \"%@\"", [addressBarTextField stringValue]]];
    [NSApp beginSheet: [connectionSheet window]
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
}

- (void)dealloc
{
    [network endConnection];
}

- (void)setupToolbar
{
    //power menu button
    powerButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Power"];
    [powerButton setTarget:self];
    NSPopUpButton *popupButton = [[NSPopUpButton alloc] init];
    [popupButton setPullsDown:YES];
    [popupButton sizeToFit];
    NSRect frame = [popupButton frame];
    frame.size.width += 6;
    [popupButton setFrame:frame];
    [popupButton setButtonType:NSMomentaryPushInButton];
    [[popupButton cell] setControlSize:NSSmallControlSize];
    [[popupButton cell] setBezelStyle:NSTexturedRoundedBezelStyle];
    [powerButton setView:popupButton];
    NSMenuItem *title = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    [title setImage:[NSImage imageNamed:@"PowerTemplate"]];
    [[popupButton cell] setImageScaling:NSImageScaleProportionallyDown];
    [popupButton.menu addItem:title];

    NSMenuItem *powerOn = [[NSMenuItem alloc] initWithTitle:@"Power On" action:@selector(powerOn:) keyEquivalent:@""];
    [popupButton.menu addItem:powerOn];
    NSMenuItem *powerOff = [[NSMenuItem alloc] initWithTitle:@"Power Off" action:@selector(powerOff:) keyEquivalent:@""];
    [popupButton.menu addItem:powerOff];
    NSMenuItem *warmReset = [[NSMenuItem alloc] initWithTitle:@"Warm Reset" action:@selector(warmReset:) keyEquivalent:@""];
    [popupButton.menu addItem:warmReset];
    NSMenuItem *coldReset = [[NSMenuItem alloc] initWithTitle:@"Cold Reset" action:@selector(coldReset:) keyEquivalent:@""];
    [popupButton.menu addItem:coldReset];

    //keyboard button
    keyboardButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Keyboard"];
    [keyboardButton setTarget:self];
    popupButton = [[NSPopUpButton alloc] init];
    [popupButton setPullsDown:YES];
    [popupButton sizeToFit];
    frame = [popupButton frame];
    frame.size.width += 13;
    [popupButton setFrame:frame];
    [popupButton setButtonType:NSMomentaryPushInButton];
    [[popupButton cell] setControlSize:NSSmallControlSize];
    [[popupButton cell] setBezelStyle:NSTexturedRoundedBezelStyle];
    [keyboardButton setView:popupButton];
    title = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    [title setImage:[NSImage imageNamed:@"KeyTemplate"]];
    [[popupButton cell] setImageScaling:NSImageScaleProportionallyDown];
    [popupButton.menu addItem:title];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"F11" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"F12" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+Alt+Del" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+Up" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+Down" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+Left" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+Right" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F1" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F2" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F3" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F4" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F5" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F6" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F7" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];
    item = [[NSMenuItem alloc] initWithTitle:@"Ctrl+F8" action:@selector(sendKeyPress:) keyEquivalent:@""];
    [popupButton.menu addItem:item];

    
    //actual size button
    actualSizeButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"ActualSize"];
    [actualSizeButton setTarget:self];
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
    [button setButtonType:NSMomentaryPushInButton];
    [[button cell] setControlSize:NSSmallControlSize];
    [[button cell] setBezelStyle:NSTexturedRoundedBezelStyle];
    [button setImage:[NSImage imageNamed:@"NSEnterFullScreenTemplate"]];
    [[button cell] setImageScaling:NSImageScaleProportionallyDown];
    button.toolTip = @"Reset to Actual Size";
    [actualSizeButton setView:button];
    button.action = @selector(resizeToActual:);
    
    //lock icon
    lockButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Lock"];
    [lockButton setTarget:self];
    button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
    [button setButtonType:NSMomentaryPushInButton];
    [[button cell] setControlSize:NSSmallControlSize];
    //[[button cell] setBezelStyle:NSTexturedRoundedBezelStyle];
    [button setBordered:NO];
    [button setHidden:YES];
    [[button cell] setImageScaling:NSImageScaleProportionallyDown];
    [lockButton setView:button];
    
    //address bar textfield
    addressBar = [[NSToolbarItem alloc] initWithItemIdentifier:@"AddressBar"];
    addressBarTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, -1)];
    [addressBarTextField setTarget:self];
    [addressBarTextField setAction:@selector(addressBarHitEnter:)];
    [addressBarTextField setUsesSingleLineMode:YES];
    [addressBarTextField setPlaceholderString:@"Connect to host..."];
    [addressBar setView:addressBarTextField];
    
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"toolbar"];
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [[self window] setToolbar:toolbar];
}

- (void)addressBarHitEnter:(id)sender {
    if ([[addressBarTextField stringValue] isEqualToString:@""])
        return;

    [self updateProgress:1 withString:@"Connecting..."];

    NSLog(@"connecting to %@", [addressBarTextField stringValue]);
    [addressBarTextField setEditable:NO];
    [addressBarTextField setSelectable:NO];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [addressBarTextField stringValue]]];
    NSString *host = [url host];
    NSNumber *portNumber = [url port];
    UInt16 port = 0;
    if (portNumber)
        port = [portNumber unsignedIntegerValue];
    if (port == 0 )
        port = 443;
    [network probeHost:host onPort:port];
    //[self startConnectionWithHost:[addressBarTextField stringValue] withPort:443 withUser:@"root"withPassword:@"calvin"];
}

- (void)setToolbarEnabled:(BOOL)enabled
{
    [(NSToolbarItem *)[keyboardButton view] setEnabled:enabled];
    [(NSToolbarItem *)[actualSizeButton view] setEnabled:enabled];
    if (enabled == NO || [network powerOpsSupported]) {
        [(NSToolbarItem *)[powerButton view] setEnabled:enabled];
        [(NSToolbarItem *)[powerButton view] setToolTip:@""];
    }
    else if (enabled == YES && ![network powerOpsSupported]) {
        [(NSToolbarItem *)[powerButton view] setEnabled:NO];
        [(NSToolbarItem *)[powerButton view] setToolTip:@"Power operations not yet supported for this hardware."];
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self setWindowFrameAutosaveName:@""];
}

- (void)startConnectionWithHost:(NSString *)host withPort:(UInt16)port withUser:(NSString *)user withPassword:(NSString *)password
{
    [network connectToHost:host onPort:port withUser:user password:password];
    [[self progressBar] setHidden:NO];
    [[self connectingLabel] setHidden:NO];
    [[self progressBar] incrementBy:1];
    [self.window setTitle:host];
    //[self.window setTitle:@"Colo Server (DRAC6)"];
}

- (void)didEndSheet:(NSWindow *)_sheet returnCode:(int)returnCode
        contextInfo:(void *)contextInfo
{
    if (returnCode != 0) {
        [self close];
        return;
    }

//    NSString *portstr = [[connectionSheet videoPortTextField] stringValue];
//    if ([portstr compare:@""] == 0)
//        portstr = [[[connectionSheet videoPortTextField] cell] placeholderString];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [addressBarTextField stringValue]]];
    NSString *host = [url host];
    NSNumber *portNumber = [url port];
    UInt16 port = 0;
    if (portNumber)
        port = [portNumber unsignedIntegerValue];
    if (port == 0 )
        port = 443;
    [self startConnectionWithHost:host withPort:port withUser:[[connectionSheet usernameTextField] stringValue] withPassword:[[connectionSheet passwordTextField] stringValue]];
}

- (void)dracTypeProbed:(drac_type_t)dracType {
    NSLog(@"drac type detected: %u", dracType);
    [self showConnectionLogin];
}

- (void)showNetworkErrorTitle:(NSString *)err description:(NSString *)desc;
{
    NSAlert *alert = [[NSAlert alloc] init];
    //[alert setMessageText:[NSString stringWithFormat:@"Failed to connect: %@",[err domain]]];
    //NSLog(@"%@", [err domain]);
    [alert setMessageText:err];
    [alert setInformativeText:desc];

    [network endConnection];
    network = [[NetworkController alloc] init];
    network.delegate = self;

    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:nil];

    [self.connectingLabel setHidden:YES];
    [self.progressBar setHidden:YES];
    [[self window] setTitle:@""];
    [addressBarTextField setEditable:YES];
    [addressBarTextField setSelectable:YES];
    [addressBarTextField setEnabled:YES];
    gotFirstVideoFrame = false;
}

- (void)updateProgress:(NSInteger)progress withString:(NSString *)string
{
    [self.connectingLabel setStringValue:string];
    [self.progressBar setDoubleValue:progress];
}

- (void)newVideoFrameReady:(uint32_t *)framebuffer withWidth:(NSUInteger)_width andHeight:(NSUInteger)_height
{
    ScreenView *screenView = (ScreenView *)[[self window] contentView];
    if (!gotFirstVideoFrame) {
        gotFirstVideoFrame = YES;
        [self.connectingLabel setHidden:YES];
        [self.progressBar setHidden:YES];
        [self setToolbarEnabled:YES];
        
        NSString *sslWarning = [network sslWarning];
        if (sslWarning) {
            lockButton.toolTip = sslWarning;
            [lockButton setImage:[NSImage imageNamed:@"NSLockUnlockedTemplate"]];
        } else
            [lockButton setImage:[NSImage imageNamed:@"NSLockLockedTemplate"]];
        [[lockButton view] setHidden:NO];
            
    }

    if (width == 0 || ((float)height / (float)width) != ((float)_height / (float)width)) {
        scaleFactor = 1.0; //resize window if aspect ratio changes
        [self.window setContentAspectRatio:NSMakeSize(_width, _height)];
    }

    height = _height;
    width = _width;
    NSRect rect = [[self window] contentRectForFrameRect:[[self window] frame]];
    if (scaleFactor == 1.0 && (rect.size.height != height || rect.size.width != width)) {
        [self resizeToActual:self];
    }
    [screenView renderNewFrame:framebuffer withWidth:width andHeight:height];
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSRect rect = [[self window] contentRectForFrameRect:[[self window] frame]];
    if (height != 0 && width != 0)
        scaleFactor = rect.size.height / (float)height;
}

- (void)resizeToActual:(id)sender
{
    NSRect rect = [[self window] contentRectForFrameRect:[[self window] frame]];

    NSRect frameRect = [[self window] frame];
    rect.size.height = height;
    rect.size.width = width;
    rect = [[self window] frameRectForContentRect:rect];
    rect.origin.x = frameRect.origin.x;
    rect.origin.y = frameRect.origin.y + (frameRect.size.height - rect.size.height);
    [[self window] setFrame:rect display:YES animate:YES];

}

- (void)powerOn:(id)sender
{
    [network powerOn:sender];
}

- (void)powerOff:(id)sender
{
    [network powerOff:sender];
}

- (void)warmReset:(id)sender
{
    [network warmReset:sender];
}

- (void)coldReset:(id)sender
{
    [network coldReset:sender];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstMouse
{
    return YES;
}

- (void)keyDown:(NSEvent*)event
{
    [network sendAppleKeyCode:[event keyCode] keyDown:YES];
}

- (void)keyUp:(NSEvent*)event
{
    [network sendAppleKeyCode:[event keyCode] keyDown:NO];
}

- (void)flagsChanged:(NSEvent *)event
{
    [network sendAppleModifierKeys:[event modifierFlags]];
}

-(NSPoint)translateLocation:(NSPoint)point
{
    point.y /= scaleFactor;
    point.x /= scaleFactor;
    point.y = (height - point.y);

    return point;
}

-(void)mouseDown:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:1];
}

-(void)mouseUp:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:1];
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:0];
}

-(void)rightMouseDown:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:2];
}

-(void)rightMouseUp:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:2];
}

- (void)rightMouseDragged:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:0];
}

-(void)otherMouseDown:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:3];
}

-(void)otherMouseUp:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:3];
}

- (void)otherMouseDragged:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:0];
}

- (void)mouseMoved:(NSEvent *)event
{
    NSPoint point = [self translateLocation:[event locationInWindow]];
    //NSLog(@"%f, %f", [event locationInWindow].x, [event locationInWindow].y);
    [network sendMouseEventLocation:point windowHeight:height windowWidth:width buttons:GetCurrentButtonState() buttonChanged:0];
}

- (void)scrollWheel:(NSEvent *)event
{
    if ([event deltaX] != 0 || [event deltaY] != 0)
        NSLog(@"user scrolled %f horizontally and %f vertically", [event deltaX], [event deltaY]);
}

- (void)sendKeyPress:(id)sender
{
    NSString *name = [sender title];
    if ([name compare:@"F12"] == 0) {
        [network sendAppleKeyCode:111 keyDown:YES];
        [network sendAppleKeyCode:111 keyDown:NO];
    } else if ([name compare:@"F11"] == 0) {
        [network sendAppleKeyCode:103 keyDown:YES];
        [network sendAppleKeyCode:103 keyDown:NO];
    } else if ([name compare:@"Ctrl+Alt+Del"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:0x3b keyDown:YES];
        [network sendAppleKeyCode:0x75 keyDown:YES];
        [network sendAppleKeyCode:0x75 keyDown:NO];
        [network sendAppleKeyCode:0x3b keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+Up"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:126 keyDown:YES];
        [network sendAppleKeyCode:126 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+Down"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:125 keyDown:YES];
        [network sendAppleKeyCode:125 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+Left"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:123 keyDown:YES];
        [network sendAppleKeyCode:123 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+Right"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:124 keyDown:YES];
        [network sendAppleKeyCode:124 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F1"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:122 keyDown:YES];
        [network sendAppleKeyCode:122 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F2"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:120 keyDown:YES];
        [network sendAppleKeyCode:120 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F3"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:99 keyDown:YES];
        [network sendAppleKeyCode:99 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F4"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:118 keyDown:YES];
        [network sendAppleKeyCode:118 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F5"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:96 keyDown:YES];
        [network sendAppleKeyCode:96 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F6"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:97 keyDown:YES];
        [network sendAppleKeyCode:97 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F7"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:98 keyDown:YES];
        [network sendAppleKeyCode:98 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    } else if ([name compare:@"Ctrl+F8"] == 0) {
        [network sendAppleKeyCode:0x3a keyDown:YES];
        [network sendAppleKeyCode:100 keyDown:YES];
        [network sendAppleKeyCode:100 keyDown:NO];
        [network sendAppleKeyCode:0x3a keyDown:NO];
    }
}

- (BOOL)videoStarted
{
    return gotFirstVideoFrame;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    oldHotKeyMode = PushSymbolicHotKeyMode(kHIHotKeyModeAllDisabled);
    [network sendAppleModifierKeys:  [[NSApp currentEvent] modifierFlags]];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    PopSymbolicHotKeyMode(oldHotKeyMode);
    [network sendAppleModifierKeys:0];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    if ([itemIdentifier compare:@"Power"] == 0)
         return powerButton;
    else if ([itemIdentifier compare:@"ActualSize"] == 0)
        return actualSizeButton;
    else if ([itemIdentifier compare:@"Keyboard"] == 0)
        return keyboardButton;
    else if ([itemIdentifier compare:@"Lock"] == 0)
        return lockButton;
    else if ([itemIdentifier compare:@"AddressBar"] == 0)
        return addressBar;
    else
        return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [[NSArray alloc] initWithObjects:@"Power", @"Keyboard", @"ActualSize", @"AddressBar", NSToolbarFlexibleSpaceItemIdentifier, @"Lock", nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)_toolbar
{
    return [self toolbarDefaultItemIdentifiers:_toolbar];
}

@end

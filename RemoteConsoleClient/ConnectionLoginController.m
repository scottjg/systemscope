//
//  ConnectionLoginController.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/24/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import "ConnectionLoginController.h"

@interface ConnectionLoginController ()

@end

@implementation ConnectionLoginController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(IBAction)cancelButtonPressed:(id)sender
{
    [[self window] close];
    [[NSApplication sharedApplication] endSheet:[self window]
                                     returnCode:1];
}

-(IBAction)connectButtonPressed:(id)sender
{
    [[self window] close];
    [[NSApplication sharedApplication] endSheet:[self window]
                                     returnCode:0];
}

@end

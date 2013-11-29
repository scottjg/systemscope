//
//  ConnectionLoginController.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 11/24/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConnectionLoginController : NSWindowController
{

}
@property (assign) IBOutlet NSTextField *usernameTextField;
@property (assign) IBOutlet NSTextField *passwordTextField;
@property (assign) IBOutlet NSTextField *dialogLabel;

-(IBAction)cancelButtonPressed:(id)sender;
-(IBAction)connectButtonPressed:(id)sender;

@end

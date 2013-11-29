//
//  WebLoginController.h
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 12/8/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "glue.h"
#import "protocol.h"

@interface WebLoginController : NSObject
{
    NSMutableData *responseData;
    NSURLConnection *httpConnection;
    
    NSString *host;
    UInt16 port;
    UInt16 kvmPort;
    
    NSString *user;
    NSString *password;

    enum {ONLY_PROBING, PROBING, PRE_LOGGING_IN, LOGGING_IN, GETTING_TOKEN, GETTING_TOKEN2, DONE} state;
    drac_type_t dracType;
}
@property (nonatomic, weak) id delegate;

- (void)startRequest:(NSString *)_host onPort:(UInt16)_port user:(NSString *)_user password:(NSString *)_password;
- (void)startProbe:(NSString *)_host onPort:(UInt16)_port;
- (void)logout;
@end


//
//  WebLoginController.m
//  RemoteConsoleClient
//
//  Created by Scott J. Goldman on 12/8/13.
//  Copyright (c) 2013 Scott J. Goldman. All rights reserved.
//

#import "WebLoginController.h"
#import "NetworkController.h"
#import "DiagnosticLog.h"

@implementation WebLoginController

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    // don't cache responses
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *ctrlPortStr, *videoPortStr;
    NSString *sessionId, *sessionNum, *tokenName, *tokenValue;
    NSString *adjusted_user, *adjusted_password;
    NSString *nextUrl, *authResult;

    UInt16 videoPort, ctrlPort;
    const uint8_t *bytes = [responseData bytes];
    size_t bytesLen = [responseData length];
    
    switch (state) {
        case ONLY_PROBING:
        case PROBING:
            if (memmem(bytes, bytesLen, "top.document.location.href = \"/index.html?console", 49) != NULL) {
                dracType = DRAC7;
                NSLog(@"Detected DRAC7");
                [DiagnosticLog addToLog:@"Detected DRAC7"];
            } else if (memmem(bytes, bytesLen, "top.document.location.href = \"/sclogin", 31) != NULL) {
                dracType = DRAC6;
                NSLog(@"Detected DRAC6");
                [DiagnosticLog addToLog:@"Detected DRAC6"];
            } else if (memmem(bytes, bytesLen, "top.document.location.replace(\"/cgi-bin/webcgi/index\");", 55) != NULL) {
                dracType = DRAC5;
                NSLog(@"Detected DRAC5");
                [DiagnosticLog addToLog:@"Detected DRAC5"];
            } else if (memmem(bytes, bytesLen, "var s_oemProductName = \"DRAC 4\";", 32) != NULL) {
                dracType = DRAC4;
                NSLog(@"Detected DRAC4");
                [DiagnosticLog addToLog:@"Detected DRAC4"];
            } else if (memmem(bytes, bytesLen, "top.location.replace(\"/login.html\");", 36) != NULL) {
                dracType = C6000;
                NSLog(@"Detected C6000");
                [DiagnosticLog addToLog:@"Detected C6000"];
            } else {
                [self.delegate showNetworkErrorTitle:@"Unable to detect type of remote console server" description:@"We were able to connect to the specified host via https, but the downloaded webpage was unrecognized. Make sure you've entered the correct host, and that it is a supported remote console by this software (DRAC4, DRAC5, DRAC6, or DRAC7)."];
                [DiagnosticLog addToLog:@"Failed to detect DRAC type"];
                [DiagnosticLog addToLog:[[NSString alloc] initWithBytes:bytes length:bytesLen encoding:NSASCIIStringEncoding]];
                return;
            }
            
            if (state == ONLY_PROBING) {
                [self.delegate dracTypeDetected:dracType];
                break;
            }
            
            switch (dracType) {
                case C6000:
                case DRAC7:
                    adjusted_user = [user stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    adjusted_password = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                    state = PRE_LOGGING_IN;
                    [self doRequest:@"/data/login" postData:[NSString stringWithFormat:@"user=%@&password=%@", adjusted_user, adjusted_password] headerKey:nil headerValue:nil];
                    break;
                case DRAC6:
                    //this is cool i guess (from drac javascript).
                    adjusted_user =          [user stringByReplacingOccurrencesOfString:@"@" withString:@"@040"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"(" withString:@"@028"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@")" withString:@"@029"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"," withString:@"@02C"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@":" withString:@"@03A"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"?" withString:@"@03F"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"=" withString:@"@03D"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"&" withString:@"@026"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"#" withString:@"@023"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"+" withString:@"@02B"];
                    adjusted_user = [adjusted_user stringByReplacingOccurrencesOfString:@"%" withString:@"@025"];
                    adjusted_password =          [password stringByReplacingOccurrencesOfString:@"@" withString:@"@040"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"(" withString:@"@028"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@")" withString:@"@029"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"," withString:@"@02C"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@":" withString:@"@03A"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"?" withString:@"@03F"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"=" withString:@"@03D"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"&" withString:@"@026"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"#" withString:@"@023"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"+" withString:@"@02B"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"%" withString:@"@025"];
                    adjusted_password = [adjusted_password stringByReplacingOccurrencesOfString:@"!" withString:@"@021"];

                    state = PRE_LOGGING_IN;
                    [self doRequest:@"/data/login" postData:[NSString stringWithFormat:@"user=%@&password=%@", adjusted_user, adjusted_password] headerKey:nil headerValue:nil];
                    break;
                    
                case DRAC5:
                    state = LOGGING_IN;
                    [self doRequest:@"/cgi-bin/webcgi/login" postData:[NSString stringWithFormat:@"user=%@&password=%@", user, password] headerKey:nil headerValue:nil];
                    break;

                case DRAC4:
                    state = LOGGING_IN;
                    [self doRequest:@"/cgi/login" postData:[NSString stringWithFormat:@"user=%@&hash=%@", user, password] headerKey:nil headerValue:nil];
                    break;
                    
                default:
                    NSAssert(0, @"unknown drac type");
                    break;
            }
            break;
        case PRE_LOGGING_IN:
            //only drac6/drac7
            [DiagnosticLog addToLog:[[NSString alloc] initWithBytes:bytes length:bytesLen encoding:NSASCIIStringEncoding]];

            authResult = [self getValue:"<authResult>" fromData:bytes withLen:bytesLen];
            NSLog(@"authResult=%@", authResult);
            if ([authResult compare:@"0"] != 0) {
                [DiagnosticLog addToLog:@"access denied (authresult was 0)"];
                [self.delegate showNetworkErrorTitle:@"Access Denied" description:@"Make sure you have entered the correct username and password and try again."];
                return;
            }

            nextUrl = [self getValue:"<forwardUrl>" fromData:bytes withLen:bytesLen];
            if (nextUrl == nil) {
                [DiagnosticLog addToLog:@"bad response (no forwardurl)"];
                [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"The server appears to have accepted our login credentials, but the response was unrecognized."];
                return;
            }
            [self doRequest:[@"/" stringByAppendingString:nextUrl] postData:nil headerKey:nil headerValue:nil];
            state = LOGGING_IN;
            break;
        case LOGGING_IN:
            [DiagnosticLog addToLog:[[NSString alloc] initWithBytes:bytes length:bytesLen encoding:NSASCIIStringEncoding]];
            switch (dracType) {
                case DRAC7:
                case DRAC6:
                    tokenName = [self getValue:"TOKEN_NAME = \"" fromData:bytes withLen:bytesLen];
                    tokenValue = [self getValue:"TOKEN_VALUE = \"" fromData:bytes withLen:bytesLen];
                    if (tokenName != nil && tokenValue == nil) {
                        // In some firmware revisions, the token lives in the URL now
                        NSURL *url = [[connection currentRequest] URL];
                        NSURLComponents *comps = [NSURLComponents componentsWithString:[url absoluteString]];
                        NSArray *items = [comps.query componentsSeparatedByString:tokenName];
                        if ([items count] > 0) {
                            NSString *str = [items objectAtIndex:1];
                            if ([str length] > 0) {
                                tokenValue = [str substringFromIndex:1];
                            }
                        }
                    }
                    [DiagnosticLog addToLog:[NSString stringWithFormat:@"Got TOKEN_NAME=%@ and TOKEN_VALUE=%@", tokenName, tokenValue]];
                case C6000:
                    state = GETTING_TOKEN;
                    [self doRequest:@"/data?get=kvmPort" postData:@"" headerKey:tokenName headerValue:tokenValue];
                    break;
                case DRAC5:
                    state = GETTING_TOKEN;
                    [self doRequest:@"/cgi-bin/webcgi/vkvm?state=1" postData:nil headerKey:nil headerValue:nil];
                    break;
                case DRAC4:
                    state = GETTING_TOKEN;
                    [self doRequest:@"/cgi/vkvm" postData:nil headerKey:nil headerValue:nil];
                    break;
                default:
                    NSAssert(0, @"unknown drac type");
                    break;
            }
            break;
        case GETTING_TOKEN:
            [DiagnosticLog addToLog:[[NSString alloc] initWithBytes:bytes length:bytesLen encoding:NSASCIIStringEncoding]];
            switch (dracType) {
                case C6000:
                    [self doRequest:@"/data/logout" postData:nil headerKey:nil headerValue:nil];
                    
                    videoPortStr = [self getValue:"<kvmPort>" fromData:bytes withLen:bytesLen];
                    if (videoPortStr == nil) {
                        [DiagnosticLog addToLog:@"failed to get kvm port"];
                        [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"Server did not return a valid kvm port to connect with."];
                        return;
                    }
                    
                    kvmPort = [videoPortStr integerValue];
                    state = DONE;
                    [self.delegate connectToCtrlPort:kvmPort videoPort:kvmPort username:user password:password dracType:dracType];
                    break;
                case DRAC7:
                case DRAC6:
                    [self doRequest:@"/data/logout" postData:nil headerKey:nil headerValue:nil];

                    videoPortStr = [self getValue:"<kvmPort>" fromData:bytes withLen:bytesLen];
                    if (videoPortStr == nil) {
                        [DiagnosticLog addToLog:@"failed to get kvm port"];
                        [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"Server did not return a valid kvm port to connect with."];
                        return;
                    }
            
                    videoPort = [videoPortStr integerValue];
                    ctrlPort = videoPort;

                    state = DONE;
                    [self.delegate connectToCtrlPort:ctrlPort videoPort:videoPort username:user password:password dracType:dracType];
                    break;
                case DRAC5:
                    sessionId    = [self getValue:"<property name=\"vKvmSessionId\" type=\"string\"><value>" fromData:bytes withLen:bytesLen];
                    videoPortStr = [self getValue:"<property name=\"VideoPortNumber\" type=\"text\"><value>" fromData:bytes withLen:bytesLen];
                    ctrlPortStr    = [self getValue:"<property name=\"KMPortNumber\" type=\"text\"><value>" fromData:bytes withLen:bytesLen];
                    if (sessionId == nil || ctrlPortStr == nil || videoPortStr == nil) {
                        [DiagnosticLog addToLog:@"failed to get kvm port"];
                        [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"Server did not return a valid kvm port or session id to connect with."];
                        return;
                    }
                
                    ctrlPort = [ctrlPortStr integerValue];
                    videoPort = [videoPortStr integerValue];
                    if (ctrlPort == 0 || videoPort == 0) {
                        [DiagnosticLog addToLog:@"invalid kvm port"];
                        [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"Server returned a kvm port, but it was invalid."];
                        return;
                    }

                    state = DONE;
                    [self.delegate connectToCtrlPort:ctrlPort videoPort:videoPort username:sessionId password:@"" dracType:dracType];
                    break;

                case DRAC4:
                    ctrlPortStr  = [self getValue:"var nPort = " fromData:bytes withLen:bytesLen];
                    sessionNum   = [self getValue:"var nSessionNum = " fromData:bytes withLen:bytesLen];
                    sessionId    = [self getValue:"var sSessionId = \"" fromData:bytes withLen:bytesLen];
                    if (ctrlPortStr == nil || sessionNum == nil || sessionId == nil) {
                        [DiagnosticLog addToLog:@"invalid kvm port"];
                        [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"Server did not return a valid kvm port or session id to connect with."];
                    }

                    ctrlPort = [ctrlPortStr integerValue];
                    videoPort = ctrlPort;
                    if (ctrlPort == 0) {
                        [DiagnosticLog addToLog:@"failed to get kvm port"];
                        [self.delegate showNetworkErrorTitle:@"Bad Response" description:@"Server returned a kvm port, but it was invalid."];
                    }

                    state = DONE;
                    [self.delegate connectToCtrlPort:ctrlPort videoPort:videoPort username:sessionNum password:sessionId dracType:dracType];
                    break;

                default:
                    //XXXX?
                    break;
            }
            break;
        default:
            // XXX do nothing?
            break;
    }

}

- (void)logout
{
    if (dracType == DRAC5)
        [self doRequest:@"/cgi-bin/webcgi/logout" postData:nil headerKey:nil headerValue:nil];
    else if (dracType == DRAC4)
        [self doRequest:@"/cgi/logout" postData:nil headerKey:nil headerValue:nil];
    else
        [self doRequest:@"/data/logout" postData:nil headerKey:nil headerValue:nil];
}

- (NSString *)getValue:(char *)value fromData:(const uint8_t *)bytes withLen:(size_t)bytesLen
{
    size_t valueLen = strlen(value);
    uint8_t *endData;
    uint8_t *data = memmem(bytes, bytesLen, value, valueLen);
    if (data == NULL) {
        return nil;
    }
    data += valueLen;
    endData = data;
    while (data < (bytes + bytesLen)) {
        if (*endData == '<'  || *endData == ';' || *endData == '"')
            break;
        endData++;
    }
    
    return [[NSString alloc] initWithBytes:data length:(endData - data) encoding:NSUTF8StringEncoding];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.delegate showNetworkErrorTitle:@"Connection failure" description:[NSString stringWithFormat:@"An attempt to connect over https to the specified host failed: %@", [error localizedDescription]]];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    //XXX should really prompt for certificate
    [[challenge sender] useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}


- (void)startRequest:(NSString *)_host onPort:(UInt16)_port user:(NSString *)_user password:(NSString *)_password
{
    state = PROBING;
    dracType = UNKNOWN;
    host = _host;
    port = _port;
    user = _user;
    password = _password;
    
    [self doRequest:@"/" postData:nil headerKey:nil headerValue:nil];
}

- (void)startProbe:(NSString *)_host onPort:(UInt16)_port
{
    state = ONLY_PROBING;
    dracType = UNKNOWN;
    host = _host;
    port = _port;
    
    [self doRequest:@"/" postData:nil headerKey:nil headerValue:nil];
}

- (void)doRequest:(NSString *)url postData:(NSString *)postString headerKey:(NSString *)headerKey headerValue:(NSString *)headerValue
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%d%@", host, port, url]]];
    if (postString) {
        request.HTTPMethod = @"POST";
        request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
    }
    [request addValue:headerValue forHTTPHeaderField:headerKey];
    httpConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

@end

//
//  DiagnosticLog.h
//  System Scope
//
//  Created by Scott Goldman on 5/14/17.
//  Copyright © 2017 Scott J. Goldman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiagnosticLog : NSObject
+(void)setup;
+(void)addToLog:(NSString *)entry;
+ (void)dumpToFile;
@end

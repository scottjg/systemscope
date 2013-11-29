//
//  DiagnosticLog.m
//  System Scope
//
//  Created by Scott Goldman on 5/14/17.
//  Copyright © 2017 Scott J. Goldman. All rights reserved.
//

#import "DiagnosticLog.h"
#define MAX_LOG_SIZE 100
static NSMutableArray *logQ = nil;

@implementation DiagnosticLog

+ (void)setup {
    logQ = [[NSMutableArray alloc] init];
}

+ (void)addToLog:(NSString *)entry {
    if ([logQ count] > MAX_LOG_SIZE) {
        [logQ removeObjectAtIndex:0];
    }
    
    [logQ addObject:entry];
}

+ (void)dumpToFile {
    NSSavePanel *saveDialog = [NSSavePanel savePanel];
    [saveDialog setTitle:@"Save Diagnostic Log"];
    [saveDialog setShowsTagField:NO];
    [saveDialog setNameFieldStringValue:@"SystemScopeDiagnosticLog.txt"];
    if ([saveDialog runModal] == NSOKButton) {
        NSMutableString *output = [[NSMutableString alloc] init];

        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-dd-yyyy HH:mm"];
        NSDate *now = [NSDate date];

        [output appendFormat:@"Diagnostic log on %@ generated at %@\n", [[NSHost currentHost] name], [formatter stringFromDate:now]];
        for(long i = [logQ count] - 1; i >=0; i--) {
            [output appendFormat:@"\n========================================================================\n"];
            [output appendFormat:@"========================================================================\n"];
            [output appendString:[logQ objectAtIndex:i]];
        }
        
        [output writeToURL:[saveDialog URL] atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    }
}

@end

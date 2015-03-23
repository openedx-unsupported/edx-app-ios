//
//  OEXURLSessionManager.m
//  edXVideoLocker
//
//  Created by Abhradeep on 12/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXURLSessionManager.h"
#import "OEXEnvironment.h"
#import "OEXConfig.h"
#import "OEXAuthentication.h"

@implementation OEXURLSessionManager

+ (instancetype)sharedURLSessionManager {
    static dispatch_once_t onceToken;
    static OEXURLSessionManager* sharedURLSessionManager = nil;
    dispatch_once(&onceToken, ^{
        sharedURLSessionManager = [[OEXURLSessionManager alloc] init];
    });
    return sharedURLSessionManager;
}

- (void)callAuthorizedWebServiceWithURLPath:(NSString*)urlPath method:(NSString*)method body:(NSData*)body completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandle {
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [OEXConfig sharedConfig].apiHostURL, urlPath]]];

    [request setHTTPMethod:method];

    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    [request setHTTPBody:body];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];

    [[session dataTaskWithRequest:request completionHandler:completionHandle] resume];
}

@end

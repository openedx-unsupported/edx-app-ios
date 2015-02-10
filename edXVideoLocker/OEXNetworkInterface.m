//
//  OEXNetworkInterface.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXNetworkInterface.h"

#import "OEXConfig.h"
#import "OEXEnvironment.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"

@interface OEXNetworkInterface ()

@property (nonatomic, strong) OEXNetworkManager * network;
@end

@implementation OEXNetworkInterface

#pragma mark Initialization

- (id)init {
    self = [super init];
    
    [self activate];
    
    return self;
}

+(void)clearNetworkSession{
    [OEXNetworkManager clearNetworkManager];
}



#pragma mark Public

- (void)callRequestString:(NSString *)requestString {
    NSURLSessionTask * task = [self taskWithURLString:requestString];
    [task resume];
}

- (NSString *)descriptionForURLString:(NSString *)URLString {
    
    NSMutableString * comparisonString = [NSMutableString stringWithString:[OEXEnvironment shared].config.apiHostURL];
    if ([URLString isEqualToString:[comparisonString stringByAppendingFormat:
                                    @"/%@/%@", URL_USER_DETAILS, [[OEXInterface sharedInterface] signInUserName]]]) {
        return REQUEST_USER_DETAILS;
    }
    else if ([URLString isEqualToString:[comparisonString stringByAppendingFormat:
                                         @"/%@/%@%@", URL_USER_DETAILS, [[OEXInterface sharedInterface] signInUserName], URL_COURSE_ENROLLMENTS]]) {
        return REQUEST_COURSE_ENROLLMENTS;
    }
    else {
        return URLString;
    }
    
    return nil;
}

- (void)downloadWithURLString:(NSString *)URLString {
    NSURL * URL = [NSURL URLWithString:URLString];
    [_network downloadInBackground:URL];
}


- (void)invalidateNetworkInterface{
    [_network invalidateNetworkManager];
    [OEXNetworkManager clearNetworkManager];
}

- (void)activate {
    [_network activate];
    self.network = [OEXNetworkManager sharedManager];
    _network.delegate = self;
}

#pragma mark Network Calls Helpers

- (NSURLSessionTask *)taskWithURLString:(NSString *)string {
    
    NSString * URLString = [self URLStringForType:string];
    NSURL * URL = [NSURL URLWithString:URLString];
    NSURLRequest * request = [[NSURLRequest alloc] initWithURL:URL];
    
    NSURLSessionTask *task = [_network.foregroundSession dataTaskWithRequest:request];
    task.taskDescription = [self descriptionForURLString:string];

    return task;
}

- (NSString *)URLStringForType:(NSString *)type {
    
    NSMutableString * URLString = [NSMutableString stringWithString:[OEXEnvironment shared].config.apiHostURL];
    
    if ([type isEqualToString:URL_USER_DETAILS]) {
        [URLString appendFormat:@"%@/%@", URL_USER_DETAILS, [[OEXInterface sharedInterface] signInUserName]];
    }
    else if ([type isEqualToString:URL_COURSE_ENROLLMENTS]) {
        [URLString appendFormat:@"%@/%@%@", URL_USER_DETAILS, [[OEXInterface sharedInterface] signInUserName], URL_COURSE_ENROLLMENTS];
    }
    else {
        URLString = [NSMutableString stringWithString:type];
    }
    
    //Append tail
    [URLString appendString:@"?format=json"];
    
    return URLString;
}


#pragma mark NetworkDelegate

- (void)receivedData:(NSData *)data forTask:(NSURLSessionTask *)task {
    [_delegate returnedData:data forType:[self descriptionForURLString:task.originalRequest.URL.absoluteString]];
}

- (void)receivedFaliureforTask:(NSURLSessionTask *)task {
    [_delegate returnedFaliureForType:[self descriptionForURLString:task.originalRequest.URL.absoluteString]];
}

- (void)downloadAddedForURL:(NSURL *)url {

    [_delegate didAddDownloadForURLString:url.absoluteString];
}

- (void)downloadAlreadyExistsForURL:(NSURL *)url {

    [_delegate didRejectDownloadForURLString:url.absoluteString];
}

@end

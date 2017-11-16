//
//  OEXNetworkInterface.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXNetworkInterface.h"

#import "OEXConfig.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"

@interface OEXNetworkInterface ()

@property (nonatomic, strong) OEXNetworkManager* network;
@end

@implementation OEXNetworkInterface

#pragma mark Initialization

- (id)init {
    self = [super init];

    [self activate];

    return self;
}

+ (void)clearNetworkSession {
    [OEXNetworkManager clearNetworkManager];
}

#pragma mark Public

- (void)callRequestString:(NSString*)requestString {
    NSURLSessionTask* task = [self taskWithURLString:requestString];
    [task resume];
}

- (NSString*)descriptionForURLString:(NSString*)URLString {
    NSMutableString* comparisonString = [NSMutableString stringWithString:[OEXConfig sharedConfig].apiHostURL.absoluteString];
    if([URLString isEqualToString:[comparisonString stringByAppendingFormat:
                                   @"/%@/%@", URL_USER_DETAILS, [OEXSession sharedSession].currentUser.username]]) {
        return REQUEST_USER_DETAILS;
    }
    else if([URLString isEqualToString:[comparisonString stringByAppendingFormat:
                                        @"/%@/%@%@", URL_USER_DETAILS, [OEXSession sharedSession].currentUser.username, URL_COURSE_ENROLLMENTS]]) {
        return REQUEST_COURSE_ENROLLMENTS;
    }
    else {
        return URLString;
    }

    return nil;
}

- (void)downloadWithURLString:(NSString*)URLString {
    NSURL* URL = [NSURL URLWithString:URLString];
    [_network downloadInBackground:URL];
}

- (void)invalidateNetworkManager {
    [self.network invalidateNetworkManager];
    self.network = nil;
    [OEXNetworkManager clearNetworkManager];
}

- (void)activate {
    [_network activate];
    self.network = [OEXNetworkManager sharedManager];
    _network.delegate = self;
}

#pragma mark Network Calls Helpers

- (NSURLSessionTask*)taskWithURLString:(NSString*)string {
    NSString* URLString = [self URLStringForType:string];
    NSURL* URL = [NSURL URLWithString:URLString];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:URL];

    NSURLSessionTask* task = [_network.foregroundSession dataTaskWithRequest:request];
    task.taskDescription = [self descriptionForURLString:string];

    return task;
}

- (NSString*)URLStringForType:(NSString*)type {
    NSMutableString* URLString = [OEXConfig sharedConfig].apiHostURL.absoluteString.mutableCopy;

    if([type isEqualToString:URL_USER_DETAILS]) {
        [URLString appendFormat:@"%@/%@", URL_USER_DETAILS, [OEXSession sharedSession].currentUser.username];
    }
    else if([type isEqualToString:URL_COURSE_ENROLLMENTS]) {
        [URLString appendFormat:@"%@/%@%@", URL_USER_DETAILS, [OEXSession sharedSession].currentUser.username, URL_COURSE_ENROLLMENTS];
    }
    else {
        URLString = [NSMutableString stringWithString:type];
    }

    //Append tail
    [URLString appendString:@"?format=json"];

    return URLString;
}

#pragma mark NetworkDelegate

- (void)receivedData:(NSData*)data forTask:(NSURLSessionTask*)task {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate returnedData:data forType:[weakSelf descriptionForURLString:task.originalRequest.URL.absoluteString]];
    });
}

- (void)receivedFailureforTask:(NSURLSessionTask*)task {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate returnedFailureForType:[weakSelf descriptionForURLString:task.originalRequest.URL.absoluteString]];
    });
}

- (void)downloadAddedForURL:(NSURL*)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate didAddDownloadForURLString:url.absoluteString];
    });
}

- (void)downloadAlreadyExistsForURL:(NSURL*)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate didRejectDownloadForURLString:url.absoluteString];
    });
}

@end

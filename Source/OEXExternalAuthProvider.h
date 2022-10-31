//
//  OEXExternalAuthProvider.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class OEXRegisteringUserDetails;
@class OEXTextStyle;

@protocol OEXExternalAuthProvider <NSObject>

/// Name used in the UI
@property (readonly, nonatomic) NSString* displayName;

/// Name used when communicating with the server
@property (readonly, nonatomic) NSString* backendName;

- (UIView*)authViewWithTitle:(NSString*) title;

- (void)authorizeServiceFromController:(UIViewController *)controller requestingUserDetails:(BOOL)loadUserDetails withCompletion:(void (^)(NSString * _Nullable , OEXRegisteringUserDetails * _Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END

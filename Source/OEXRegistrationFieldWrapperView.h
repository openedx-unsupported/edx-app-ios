//
//  OEXRegistrationFieldError.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 23/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationFieldWrapperView : UIView

- (void)setRegistrationErrorMessage:(NSString*)errorMessage instructionMessage:(NSString*)instructionMessage;
@end

NS_ASSUME_NONNULL_END

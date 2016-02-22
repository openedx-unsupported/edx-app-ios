//
//  OEXRegistrationAgreementView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OEXRegistrationAgreementView : UIView
{
    UILabel* errorLabel;
    UILabel* instructionLabel;
}
@property(nonatomic, strong, nullable) NSString* errorMessage;
@property(nonatomic, strong) NSString* instructionMessage;
@property(nonatomic, strong) NSString* agreement;
@property(nonatomic, strong) NSString* agreementUrl;

- (void)clearError;
- (BOOL)currentValue;
@end

NS_ASSUME_NONNULL_END

//
//  OEXRegistrationFieldCheckBoxView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class OEXCheckBoxView;

@interface OEXRegistrationFieldCheckBoxView : UIView

- (void)takeValue:(BOOL)value;

@property (nonatomic, strong, nullable) NSString* errorMessage;
@property (nonatomic, strong) NSString* instructionMessage;
@property (nonatomic, strong) NSString* label;
@property (readonly, nonatomic, strong) OEXCheckBoxView* checkBox;

- (void)clearError;
- (BOOL)currentValue;

@end

NS_ASSUME_NONNULL_END

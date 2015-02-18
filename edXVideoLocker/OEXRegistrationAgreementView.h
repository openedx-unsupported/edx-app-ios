//
//  OEXRegistrationAgreementView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXRegistrationAgreementView : UIView
{
    UIButton     *inputView;
    UILabel      *errorLabel;
    UILabel      *instructionLabel;
}
@property(nonatomic,strong)NSString *errorMessage;
@property(nonatomic,strong)NSString *instructionMessage;
@property(nonatomic,strong)NSString *agreement;
@property(nonatomic,strong)NSString *agreementUrl;

-(void)clearError;
-(NSString *)currentValue;
@end

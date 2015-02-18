//
//  OEXRegistrationAgreementController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationAgreementController.h"
#import "OEXRegistrationAgreementView.h"
@interface OEXRegistrationAgreementController ()
@property(nonatomic,strong)OEXRegistrationFormField *mField;
@property(nonatomic,strong)OEXRegistrationAgreementView *mView;
@end
@implementation OEXRegistrationAgreementController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.mField=field;
        self.mView=[[OEXRegistrationAgreementView alloc] init];
        self.mView.instructionMessage=field.instructions;
        self.mView.agreement=field.agreement.text;
        self.mView.agreementUrl=field.agreement.url;
    }
    return self;
}

-(NSString *)currentValue{
    return [[self.mView currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(UIView *)view{
    return self.mView;
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}

-(OEXRegistrationFormField *)field{
    return self.mField;
}

-(void)handleError:(NSString *)errorMsg{
    [self.mView setErrorMessage:errorMsg];
    [self.mView layoutSubviews];
}

-(BOOL)isValidInput{
    
    if([self.mField.isRequired boolValue] && ![self hasValue]){
        [self handleError:self.mField.errorMessage.required];
        return NO;
    }
    
    NSInteger length=[[self currentValue] length];
    if(self.mField.restriction && length < self.mField.restriction.minLength ){
        [self handleError:self.mField.errorMessage.minLenght];
        return NO;
    }
    if(self.mField.restriction.maxLentgh && length > self.mField.restriction.maxLentgh ){
        [self handleError:self.mField.errorMessage.maxLenght];
        return NO;
    }
    
    return YES;
}

-(void)setEnabled:(BOOL)enabled{
    
}

@end

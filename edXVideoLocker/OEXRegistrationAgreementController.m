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
@property(nonatomic,strong)OEXRegistrationFormField *field;
@property(nonatomic,strong)OEXRegistrationAgreementView *view;
@end
@implementation OEXRegistrationAgreementController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.field=field;
        self.view=[[OEXRegistrationAgreementView alloc] init];
        self.view.instructionMessage=field.instructions;
        self.view.agreement=field.agreement.text;
        self.view.agreementUrl=field.agreement.url;
        UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc] init];
        [tapGesture addTarget:self action:@selector(agreementViewTapped:)];
        [self.view addGestureRecognizer:tapGesture];
        
    }
    return self;
}

-(NSString *)currentValue{
    if([self.view currentValue])
    {
        return @"true";
    }else{
        return @"false";
    }
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}

-(void)handleError:(NSString *)errorMsg{
    [self.view setErrorMessage:errorMsg];
    [self.view layoutSubviews];
}

-(BOOL)isValidInput{
    
    if(self.field.isRequired && ![self hasValue]){
        [self handleError:self.field.errorMessage.required];
        return NO;
    }
    
    NSInteger length=[[self currentValue] length];
    if(self.field.restriction && length < self.field.restriction.minLength ){
        [self handleError:self.field.errorMessage.minLength];
        return NO;
    }
    if(self.field.restriction.maxLength && length > self.field.restriction.maxLength ){
        [self handleError:self.field.errorMessage.maxLength];
        return NO;
    }
    
    return YES;
}

-(void)setEnabled:(BOOL)enabled{
    
}

-(IBAction)agreementViewTapped:(id)sender{
    [self.delegate aggreementViewDidTappedForController:self];
}

@end

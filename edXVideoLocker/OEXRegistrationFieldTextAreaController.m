//
//  OEXRegistrationFieldTextAreaController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextAreaController.h"
#import "OEXRegistrationFieldTextAreaView.h"

@interface OEXRegistrationFieldTextAreaController ()
@property(nonatomic,strong)OEXRegistrationFormField *mField;
@property(nonatomic,strong)OEXRegistrationFieldTextAreaView *mView;
@end

@implementation OEXRegistrationFieldTextAreaController
-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.mField=field;
        self.mView=[[OEXRegistrationFieldTextAreaView alloc] init];
        self.mView.instructionMessage=field.instructions;
        self.mView.placeholder=self.mField.label;
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

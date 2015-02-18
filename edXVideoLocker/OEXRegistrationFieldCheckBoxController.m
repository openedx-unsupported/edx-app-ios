//
//  OEXRegistrationFieldCheckBoxController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldCheckBoxController.h"
#import "OEXRegistrationFieldCheckBoxView.h"
@interface OEXRegistrationFieldCheckBoxController ()
@property(nonatomic,strong)OEXRegistrationFormField *mField;
@property(nonatomic,strong)OEXRegistrationFieldCheckBoxView *mView;
@end

@implementation OEXRegistrationFieldCheckBoxController
-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.mField=field;
        self.mView=[[OEXRegistrationFieldCheckBoxView alloc] init];
        self.mView.instructionMessage=field.instructions;
        self.mView.label=field.label;
    }
    return self;
}

-(NSString *)currentValue{
    
    if([self.mView currentValue]){
        return @"true";
    }else{
        return @"false";
    }
    
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

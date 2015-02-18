//
//  OEXRegistrationFieldSelectController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldSelectController.h"
#import "OEXRegistrationFieldSelectView.h"
@interface OEXRegistrationFieldSelectController ()
@property(nonatomic,strong)OEXRegistrationFormField *mField;
@property(nonatomic,strong)OEXRegistrationFieldSelectView *mView;
@end

@implementation OEXRegistrationFieldSelectController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.mField=field;
        self.mView=[[OEXRegistrationFieldSelectView alloc] init];
        self.mView.instructionMessage=field.instructions;
        self.mView.placeholder=field.label;
        self.mView.options=[self.mField fieldOptions];
    }
    return self;
}

-(NSString *)currentValue{
    return [self.mView.selected.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}

-(UIView *)view{
    return [self mView];
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
    if(self.mField.restriction.minLength && length < [self.mField.restriction minLength] ){
         [self handleError:self.mField.errorMessage.minLenght];
        return NO;
    }
    if(self.mField.restriction.maxLentgh && length > [self.mField.restriction maxLentgh] ){
         [self handleError:self.mField.errorMessage.maxLenght];
        return NO;
    }
    
    return YES;
    
}

-(void)setEnabled:(BOOL)enabled{
   
}


@end

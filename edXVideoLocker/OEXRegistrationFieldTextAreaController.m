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
@property(nonatomic,strong)OEXRegistrationFormField *field;
@property(nonatomic,strong)OEXRegistrationFieldTextAreaView *view;
@end

@implementation OEXRegistrationFieldTextAreaController
-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.field=field;
        self.view=[[OEXRegistrationFieldTextAreaView alloc] init];
        self.view.instructionMessage=field.instructions;
        self.view.placeholder=self.field.label;
    }
    return self;
}

-(NSString *)currentValue{
    return [[self.view currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
@end

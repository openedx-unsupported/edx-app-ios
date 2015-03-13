//
//  OEXRegistrationFieldSelectController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldSelectController.h"
#import "OEXRegistrationFieldSelectView.h"
#import "NSString+OEXFormatting.h"

@interface OEXRegistrationFieldSelectController ()
@property(nonatomic,strong)OEXRegistrationFormField *field;
@property(nonatomic,strong)OEXRegistrationFieldSelectView *view;
@end

@implementation OEXRegistrationFieldSelectController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.field=field;
        self.view=[[OEXRegistrationFieldSelectView alloc] init];
        self.view.instructionMessage=field.instructions;
        self.view.placeholder=field.label;
        self.view.options=self.field.fieldOptions;
    }
    return self;
}

-(NSString *)currentValue{
    return [self.view.selected.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}


-(void)handleError:(NSString *)errorMsg{
    [self.view setErrorMessage:errorMsg];
}

-(BOOL)isValidInput{
    if(self.field.isRequired && ![self hasValue]){
        if(!self.field.errorMessage.required){
            NSString *localizedString= OEXLocalizedString(@"REGISTRATION_FIELD_EMPTY_SELECT_ERROR", nil) ;
            NSString *error=[NSString stringWithFormat:localizedString,self.field.label];
            [self handleError:error];
        }else{
            [self handleError:self.field.errorMessage.required];
        }
        return NO;
    }
    return YES;
}


@end

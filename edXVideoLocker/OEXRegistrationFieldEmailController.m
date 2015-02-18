//
//  RegistraionFieldEmailController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldEmailController.H"
#import "OEXRegistrationFormField.h"

@interface OEXRegistrationFieldEmailController ()
@property(nonatomic,strong)OEXRegistrationFormField *mField;
@property(nonatomic,strong)OEXRegistrationFieldEmailView *mView;
@end

@implementation OEXRegistrationFieldEmailController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
   if(self){
        self.mField=field;
        self.mView=[[OEXRegistrationFieldEmailView alloc] init];
        self.mView.instructionMessage=field.instructions;
        self.mView.placeholder=field.label;
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
    if(self.mField.restriction.maxLentgh && length > self.mField.restriction.maxLentgh ){    [self handleError:self.mField.errorMessage.maxLenght];
        return NO;
    }
    
    return YES;
}

-(void)setEnabled:(BOOL)enabled{

}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

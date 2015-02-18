//
//  OEXRegistrationFieldSelectView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldSelectView.h"

@interface OEXRegistrationFieldSelectView()<UIPickerViewDelegate,UIPickerViewDataSource>{
    UIPickerView *picker;
    OEXRegistrationOption *selectedOption;
}
@end

@implementation OEXRegistrationFieldSelectView

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
        picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 150)];
        [picker setDataSource: self];
        [picker setDelegate: self];
        picker.showsSelectionIndicator = YES;
        inputView.inputView = picker;
    }
    return self;
}

-(OEXRegistrationOption *)selected{
    return selectedOption;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [self.options count];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}


-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    OEXRegistrationOption *option=[self.options objectAtIndex:row];
    return [option name];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    selectedOption=[self.options objectAtIndex:row];
    inputView.text=selectedOption.name;
}

@end

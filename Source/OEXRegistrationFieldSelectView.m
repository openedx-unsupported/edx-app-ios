//
//  OEXRegistrationFieldSelectView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldSelectView.h"

#import <Masonry/Masonry.h>

@interface OEXRegistrationFieldSelectView () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) UIPickerView* picker;
@property (strong, nonatomic) OEXRegistrationOption* selectedOption;

@property (strong, nonatomic) UILabel* dropdownIcon;

@end

@implementation OEXRegistrationFieldSelectView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 150)];
        [self.picker setDataSource: self];
        [self.picker setDelegate: self];
        self.picker.showsSelectionIndicator = YES;
        self.inputView.inputView = self.picker;
    }
    return self;
}

- (OEXRegistrationOption*)selected {
    return self.selectedOption;
}

- (NSInteger)pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.options count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    return 1;
}

- (NSString*)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    OEXRegistrationOption* option = [self.options objectAtIndex:row];
    return [option name];
}

- (void)pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedOption = [self.options objectAtIndex:row];
    if(![self.selectedOption.value isEqualToString:@""]) {
        self.inputView.text = self.selectedOption.name;
    }
    else {
        self.inputView.text = @"";
    }
}

@end

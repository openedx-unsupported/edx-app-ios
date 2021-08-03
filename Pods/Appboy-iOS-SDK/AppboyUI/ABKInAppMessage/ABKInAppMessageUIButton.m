#import "ABKInAppMessageUIButton.h"
#import "ABKUIUtils.h"

#define DefaultTitleSize UIFontTextStyleSubheadline
static CGFloat const ButtonCornerRadius = 5.0f;
static CGFloat const ButtonTitleSidePadding = 12.0;

@interface ABKInAppMessageUIButton ()

@property (copy) UIColor *originalBackgroundColor;

@end

@implementation ABKInAppMessageUIButton

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setUp];
  }
  return self;
}

- (instancetype)init {
  if (self = [super init]) {
    [self setUp];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self  = [super initWithCoder:aDecoder]) {
    [self setUp];
  }
  return self;
}

- (void)setUp {
  self.titleLabel.font = [ABKUIUtils preferredFontForTextStyle:DefaultTitleSize weight:UIFontWeightBold];
  self.titleLabel.adjustsFontForContentSizeCategory = YES;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.originalBackgroundColor = self.backgroundColor;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppButtonModel.buttonTextFont]) {
    self.titleLabel.font = self.inAppButtonModel.buttonTextFont;
  }
  
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppButtonModel.buttonTextColor]) {
    [self setTitleColor:self.inAppButtonModel.buttonTextColor forState:UIControlStateNormal];
  }
  
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppButtonModel.buttonText]) {
    [self setTitle:self.inAppButtonModel.buttonText forState:UIControlStateNormal];
  }
  
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppButtonModel.buttonBackgroundColor]) {
    self.backgroundColor = self.inAppButtonModel.buttonBackgroundColor;
  }
  
  if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppButtonModel.buttonBorderColor]) {
    self.layer.borderColor = [self.inAppButtonModel.buttonBorderColor CGColor];
  } else if ([ABKUIUtils objectIsValidAndNotEmpty:self.inAppButtonModel.buttonBackgroundColor]) {
    self.layer.borderColor = [self.inAppButtonModel.buttonBackgroundColor CGColor];
  } else {
    self.layer.borderColor = [[UIColor colorWithRed:(27.0/255.0) green:(120.0/255.0) blue:(207.0)/(255.0) alpha:1.0] CGColor];
  }
  
  self.layer.cornerRadius = ButtonCornerRadius;
  self.titleLabel.frame = CGRectMake(ButtonTitleSidePadding, 0,
                             self.bounds.size.width - ButtonTitleSidePadding * 2, self.bounds.size.height);
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  
  if (highlighted) {
    [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.08]];
  } else {
    self.backgroundColor = self.originalBackgroundColor;
    [self setNeedsLayout];
  }
}

@end

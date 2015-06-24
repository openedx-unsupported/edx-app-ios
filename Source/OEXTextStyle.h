//
//  OEXTextStyle.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OEXTextWeight) {
    OEXTextWeightNormal,
    OEXTextWeightLight,
    OEXTextWeightSemiBold,
    OEXTextWeightBold
};

typedef NS_ENUM(NSUInteger, OEXLetterSpacing) {
    OEXLetterSpacingNormal,
    OEXLetterSpacingLoose,
    OEXLetterSpacingXLoose,
    OEXLetterSpacingXXLoose,
    OEXLetterSpacingTight,
    OEXLetterSpacingXTight,
    OEXLetterSpacingXXTight,
};

NS_ASSUME_NONNULL_BEGIN

@interface OEXTextStyle : NSObject <NSCopying, NSMutableCopying>

- (id)initWithWeight:(OEXTextWeight)weight size:(CGFloat)size;
- (id)initWithWeight:(OEXTextWeight)weight size:(CGFloat)size color:(nullable UIColor*)color NS_DESIGNATED_INITIALIZER;

@property (readonly, assign, nonatomic) NSTextAlignment alignment;
@property (readonly, assign, nonatomic) OEXLetterSpacing letterSpacing;
@property (readonly, strong, nonatomic, nullable) UIColor* color;
@property (readonly, assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacing;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (readonly, assign, nonatomic) CGFloat size;
@property (readonly, assign, nonatomic) OEXTextWeight weight;

@property (readonly, nonatomic) NSDictionary* attributes;

/// Duplicates the current style but makes it bold if it is not already
@property (readonly, copy, nonatomic) OEXTextStyle*(^withWeight)(OEXTextWeight weight);
/// Duplicates the current style but with the specified font size
@property (readonly, copy, nonatomic) OEXTextStyle*(^withSize)(CGFloat size);
/// Duplicates the current style but with the specified color
@property (readonly, copy, nonatomic) OEXTextStyle*(^withColor)(UIColor* color);

- (NSAttributedString*)attributedStringWithText:(nullable NSString*)text;

@end

@interface OEXMutableTextStyle : OEXTextStyle

+ (instancetype)style;

@property (assign, nonatomic) NSTextAlignment alignment;
@property (strong, nonatomic, nullable) UIColor* color;
@property (assign, nonatomic) OEXLetterSpacing letterSpacing;
@property (assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (assign, nonatomic) CGFloat paragraphSpacing;
@property (assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (assign, nonatomic) CGFloat size;
@property (assign, nonatomic) OEXTextWeight weight;

@end

NS_ASSUME_NONNULL_END


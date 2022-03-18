//
//  OEXTextStyle.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OEXTextWeight) {
    OEXTextWeightNormal,
    OEXTextWeightLight,
    OEXTextWeightSemiBold,
    OEXTextWeightBold,
    OEXTextWeightBoldItalic
    // TODO: Add XLight when necessary
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

typedef NS_ENUM(NSUInteger, OEXTextSize) {
    OEXTextSizeBase,
    OEXTextSizeXXXXXLarge,
    OEXTextSizeXXXXLarge,
    OEXTextSizeXXXLarge,
    OEXTextSizeXXLarge,
    OEXTextSizeXLarge,
    OEXTextSizeLarge,
    OEXTextSizeXXXSmall,
    OEXTextSizeXXSmall,
    OEXTextSizeXSmall,
    OEXTextSizeSmall,
};

// TODO Add line spacing when necessary


@interface OEXTextStyle : NSObject <NSCopying, NSMutableCopying>

- (id)initWithWeight:(OEXTextWeight)weight size:(OEXTextSize)size color:(nullable UIColor*)color NS_DESIGNATED_INITIALIZER;
- (id)init NS_SWIFT_UNAVAILABLE("Use the designated initializer weight:size:color");

+ (CGFloat)pointSizeForTextSize:(OEXTextSize)size;
+(OEXTextSize)textSizeForPointSize:(int)size;

@property (readonly, assign, nonatomic) NSTextAlignment alignment;
@property (readonly, assign, nonatomic) OEXLetterSpacing letterSpacing;
@property (readonly, strong, nonatomic, nullable) UIColor* color;
@property (readonly, assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacing;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (readonly, assign, nonatomic) OEXTextSize size;
@property (readonly, assign, nonatomic) OEXTextWeight weight;

@property (readonly, nonatomic) NSDictionary<NSString*, id>* attributes;

/// Duplicates the current style but makes it bold if it is not already
@property (readonly, copy, nonatomic) OEXTextStyle*(^withWeight)(OEXTextWeight weight);
/// Duplicates the current style but with the specified font size
@property (readonly, copy, nonatomic) OEXTextStyle*(^withSize)(OEXTextSize size);
/// Duplicates the current style but with the specified color
@property (readonly, copy, nonatomic) OEXTextStyle*(^withColor)(UIColor* color);
/// Controls Dynamic type support. default true
@property (nonatomic) BOOL dynamicTypeSupported;

- (NSAttributedString*)attributedStringWithText:(nullable NSString*)text;

- (NSAttributedString*)markdownStringWithText:(nullable NSString*)text;

@end

@interface OEXMutableTextStyle : OEXTextStyle

- (instancetype)initWithTextStyle:(OEXTextStyle*)style;

@property (assign, nonatomic) NSTextAlignment alignment;
@property (strong, nonatomic, nullable) UIColor* color;
@property (assign, nonatomic) OEXLetterSpacing letterSpacing;
@property (assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (assign, nonatomic) CGFloat paragraphSpacing;
@property (assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (assign, nonatomic) OEXTextSize size;
@property (assign, nonatomic) OEXTextWeight weight;

@end

NS_ASSUME_NONNULL_END


//
//  OEXVideoEncoding.h
//  edX
//
//  Created by Akiva Leffert on 6/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* const OEXVideoEncodingYoutube;
extern NSString* const OEXVideoEncodingFallback;
extern NSString* const OEXVideoEncodingMobileHigh;
extern NSString* const OEXVideoEncodingMobileLow;

@interface OEXVideoEncoding : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary name:(NSString*)name;
- (id)initWithName:(nullable NSString*)name URL:(NSString*)URL size:(NSNumber*)size;

@property (readonly, nonatomic, copy, nullable) NSString* name;
@property (readonly, nonatomic, copy, nullable) NSString* URL;
@property (readonly, nonatomic, strong, nullable) NSNumber* size;

/// [String], ordered by preference
+ (NSArray*)knownEncodingNames;

@end

NS_ASSUME_NONNULL_END

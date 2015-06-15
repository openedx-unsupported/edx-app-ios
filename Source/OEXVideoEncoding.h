//
//  OEXVideoEncoding.h
//  edX
//
//  Created by Akiva Leffert on 6/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXVideoEncoding : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;
- (id)initWithURL:(NSString*)URL size:(NSNumber*)size;

@property (readonly, nonatomic, copy, nullable) NSString* URL;
@property (readonly, nonatomic, strong, nullable) NSNumber* size;

/// [String], ordered by preference
+ (NSArray*)knownEncodingNames;

+ (NSString*)fallbackEncodingName;

@end

NS_ASSUME_NONNULL_END

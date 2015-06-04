//
//  OEXVideoEncoding.m
//  edX
//
//  Created by Akiva Leffert on 6/2/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXVideoEncoding.h"

@interface OEXVideoEncoding ()

@property (copy, nonatomic) NSString* URL;
@property (strong, nonatomic) NSNumber* size;

@end

@implementation OEXVideoEncoding

+ (NSArray*)knownEncodingNames {
    return @[@"mobile_low", @"mobile_high"];
}

+ (NSString*)fallbackEncodingName {
    return @"fallback";
}

- (id)initWithDictionary:(NSDictionary*)dictionary {
    if(self != nil) {
        self.URL = dictionary[@"url"];
        self.size = dictionary[@"file_size"];
    }
    
    return self;
}


- (id)initWithURL:(NSString*)URL size:(NSNumber*)size {
    self = [super init];
    if(self != nil) {
        self.URL = URL;
        self.size = size;
    }
    return self;
}

@end

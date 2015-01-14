//
//  TranscriptsData.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 02/09/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TranscriptsData : NSObject

@property (nonatomic, strong) NSString *EnglishURLFilePath;
@property (nonatomic, strong) NSString *ChineseURLFilePath;
@property (nonatomic, strong) NSString *GermanURLFilePath;
@property (nonatomic, strong) NSString *PortugueseURLFilePath;
@property (nonatomic, strong) NSString *SpanishURLFilePath;
// New in GA
@property (nonatomic, strong) NSString *FrenchURLFilePath;


@property (nonatomic, strong) NSString *EnglishDownloadURLString;
@property (nonatomic, strong) NSString *ChineseDownloadURLString;
@property (nonatomic, strong) NSString *GermanDownloadURLString;
@property (nonatomic, strong) NSString *PortugueseDownloadURLString;
@property (nonatomic, strong) NSString *SpanishDownloadURLString;
// New in GA
@property (nonatomic, strong) NSString *FrenchDownloadURLString;

@end

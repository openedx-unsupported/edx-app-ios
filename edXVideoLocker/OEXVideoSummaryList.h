//
//  OEXVideoSummaryList.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 17/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXVideoSummaryList : NSObject

@property (nonatomic , strong) NSString *section_url;   // used for OPEN IN BROWSER

@property (nonatomic , strong) NSMutableArray *path;    // Unused
@property (nonatomic , strong) NSMutableArray *named_path;  //Used to derive the tree of course
@property (nonatomic , strong) NSString *category;
@property (nonatomic , strong) NSString *name;
@property (nonatomic , strong) NSString *video_url;
@property (nonatomic , strong) NSString *video_thumbnail_url;
@property (nonatomic , assign) double duration;
@property (nonatomic , strong) NSString *video_id;
@property (nonatomic , strong) NSString *size;
@property (nonatomic , strong) NSDictionary *summary;
@property (nonatomic , strong) NSString *unit_url;


// For CC
// de - German
// en - English
// zh - Chinese
// es - Spanish
// pt - Portuguese
// fr - French

@property (nonatomic , strong) NSDictionary *transcripts;
@property (nonatomic , strong) NSString *srtGerman;
@property (nonatomic , strong) NSString *srtEnglish;
@property (nonatomic , strong) NSString *srtChinese;
@property (nonatomic , strong) NSString *srtSpanish;
@property (nonatomic , strong) NSString *srtPortuguese;
@property (nonatomic , strong) NSString *srtFrench;

@property (nonatomic , strong) NSString *subSectionID;

@end

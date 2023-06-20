//
//  BranchShareLink.h
//  Branch-SDK
//
//  Created by Edward Smith on 3/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BranchUniversalObject.h"
#import <LinkPresentation/LinkPresentation.h>
@class BranchShareLink;

@protocol BranchShareLinkDelegate <NSObject>
@optional

/**
This delegate method is called during the course of user interaction while sharing a
Branch link. The linkProperties, such as channel, or the share text parameters can be
altered as appropriate for the particular user-chosen activityType.

This delegate method will be called multiple times during a share interaction and might be
called on a background thread.

@param  shareLink  The calling BranchShareLink that is currently sharing.
*/
- (void) branchShareLinkWillShare:(BranchShareLink*_Nonnull)shareLink;

/**
This delegate method is called when sharing has completed.

@param shareLink    The Branch share action sheet that has just completed.
@param completed    This parameter is YES if sharing completed successfully and the user did not cancel.
@param error        This parameter contains any errors that occurred will attempting to share.
*/
- (void) branchShareLink:(BranchShareLink*_Nonnull)shareLink
             didComplete:(BOOL)completed
               withError:(NSError*_Nullable)error;
@end

#pragma mark - BranchShareLink

/**
The `BranchShareLink` class facilitates sharing Branch links using a `UIActivityViewController` 
user experience.

The `BranchShareLink` is a new class that is similar to but has more functionality than the old 
`[BranchUniversalObject showShareSheetWithLinkProperties:...]` methods.

The `BranchShareLink` is initialized with the `BranchUniversalObject` and `BranchLinkProperties` 
objects that will be used to generate the Branch link.

After the `BranchShareLink` object is created, set any configuration properties on the activity 
sheet object, and then call `showFromViewController:anchor:` to show the activity sheet.

A delegate on the BranchShareLink can further configure the share experience. For instance the link 
parameters can be changed depending on the activity that the user selects.
*/

@interface BranchShareLink : NSObject <UIActivityItemSource>

/**
Creates a BranchShareLink object.

@param universalObject  The Branch Universal Object the will be shared.
@param linkProperties   The link properties that the link will have.
*/
- (instancetype _Nonnull) initWithUniversalObject:(BranchUniversalObject*_Nonnull)universalObject
                                    linkProperties:(BranchLinkProperties*_Nonnull)linkProperties
                                    NS_DESIGNATED_INITIALIZER;

- (instancetype _Nonnull) init NS_UNAVAILABLE;
+ (instancetype _Nonnull) new NS_UNAVAILABLE;

///Returns an array of activity item providers, one for the Branch Universal Object,
///one for the share text (if provided), and one for the shareObject (if provided).
- (NSArray<UIActivityItemProvider*>*_Nonnull) activityItems;

/**
Presents a UIActivityViewController that shares the Branch link.

@param viewController           The parent view controller from which to present the the activity sheet.
@param anchorViewOrButtonItem   The anchor point for the activity sheet. Used for iPad form factors.
*/
- (void) presentActivityViewControllerFromViewController:(UIViewController*_Nullable)viewController
                                                  anchor:(id _Nullable)anchorViewOrButtonItem;

///The title for the share sheet.
@property (nonatomic, copy) NSString*_Nullable title;

// Override the default placeholder URL
// iOS 13+ fetches a preview header icon, text and domain name from this URL.
// By default, we use the Branch bnc.lt link, but if you wish more control override it here.
@property (nonatomic, strong, nullable) NSURL *placeholderURL;

// iOS 13+ : LinkPresentation metadata for the preview header.
@property (nonatomic, strong, nullable) LPLinkMetadata *lpMetaData API_AVAILABLE(ios(13.0));

///Share text for the item.  This is not the text in the iOS 13+ preview header.
///This text can be changed later when the `branchShareSheetWillShare:` delegate method is called.
@property (nonatomic, copy) NSString*_Nullable shareText;

///An additional, user defined, non-typed, object to be shared.
///This object can be changed later when the `branchShareSheetWillShare:` delegate method is called.
@property (nonatomic, strong) id _Nullable shareObject;

///Sets an email subject line for the share activity. If the Branch link property already has an
///email subject, that attribute takes precedence over this field.
@property (nonatomic, copy) NSString*_Nullable emailSubject;

///The resulting Branch URL that was shared.
@property (nonatomic, strong, readonly) NSURL*_Nullable shareURL;

///The activity type that the user chose.
@property (nonatomic, readonly, copy) NSString*_Nullable activityType;

///Extra server parameters that should be included with the link data.
@property (nonatomic, strong) NSMutableDictionary*_Nullable serverParameters;

///The Branch Universal Object that will be shared.
@property (nonatomic, strong, readonly) BranchUniversalObject*_Nonnull universalObject;

///The link properties for the created URL.
@property (nonatomic, strong, readonly) BranchLinkProperties*_Nonnull  linkProperties;

///The delegate. See 'BranchShareLinkDelegate' above for a description.
@property (nonatomic, weak)   id<BranchShareLinkDelegate>_Nullable delegate;

@property void (^ _Nullable completion)(NSString * _Nullable activityType, BOOL completed);
@property void (^ _Nullable completionError)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error);

/**
Creates and attaches an LPLinkMetadata using the provided title and icon. This method is only available on iOS 13.0 or greater.

@param title           The string that will appear in the share sheet preview,
@param icon             The image used for the share sheet preview icon.
*/

- (void) addLPLinkMetadata:(NSString *_Nullable)title
                      icon:(UIImage *_Nullable)icon API_AVAILABLE(ios(13.0));

@end

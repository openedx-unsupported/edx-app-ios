/*
 * Copyright 2018 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "FIRInAppMessagingRendering.h"

@implementation FIRInAppMessagingDisplayMessage

- (instancetype)initWithMessageID:(NSString *)messageID
                     campaignName:(NSString *)campaignName
              renderAsTestMessage:(BOOL)renderAsTestMessage
                      messageType:(FIRInAppMessagingDisplayMessageType)messageType
                      triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType {
  if (self = [super init]) {
    _campaignInfo = [[FIRInAppMessagingCampaignInfo alloc] initWithMessageID:messageID
                                                                campaignName:campaignName
                                                         renderAsTestMessage:renderAsTestMessage];
    _type = messageType;
    _triggerType = triggerType;
  }
  return self;
}
@end

@implementation FIRInAppMessagingBannerDisplay
- (instancetype)initWithMessageID:(NSString *)messageID
                     campaignName:(NSString *)campaignName
              renderAsTestMessage:(BOOL)renderAsTestMessage
                      triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType
                        titleText:(NSString *)title
                         bodyText:(NSString *)bodyText
                        textColor:(UIColor *)textColor
                  backgroundColor:(UIColor *)backgroundColor
                        imageData:(nullable FIRInAppMessagingImageData *)imageData
                        actionURL:(nullable NSURL *)actionURL {
  if (self = [super initWithMessageID:messageID
                         campaignName:campaignName
                  renderAsTestMessage:renderAsTestMessage
                          messageType:FIRInAppMessagingDisplayMessageTypeBanner
                          triggerType:triggerType]) {
    _title = title;
    _bodyText = bodyText;
    _textColor = textColor;
    _displayBackgroundColor = backgroundColor;
    _imageData = imageData;
    _actionURL = actionURL;
  }
  return self;
}
@end

@implementation FIRInAppMessagingModalDisplay

- (instancetype)initWithMessageID:(NSString *)messageID
                     campaignName:(NSString *)campaignName
              renderAsTestMessage:(BOOL)renderAsTestMessage
                      triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType
                        titleText:(NSString *)title
                         bodyText:(NSString *)bodyText
                        textColor:(UIColor *)textColor
                  backgroundColor:(UIColor *)backgroundColor
                        imageData:(nullable FIRInAppMessagingImageData *)imageData
                     actionButton:(nullable FIRInAppMessagingActionButton *)actionButton
                        actionURL:(nullable NSURL *)actionURL {
  if (self = [super initWithMessageID:messageID
                         campaignName:campaignName
                  renderAsTestMessage:renderAsTestMessage
                          messageType:FIRInAppMessagingDisplayMessageTypeModal
                          triggerType:triggerType]) {
    _title = title;
    _bodyText = bodyText;
    _textColor = textColor;
    _displayBackgroundColor = backgroundColor;
    _imageData = imageData;
    _actionButton = actionButton;
    _actionURL = actionURL;
  }
  return self;
}
@end

@implementation FIRInAppMessagingImageOnlyDisplay

- (instancetype)initWithMessageID:(NSString *)messageID
                     campaignName:(NSString *)campaignName
              renderAsTestMessage:(BOOL)renderAsTestMessage
                      triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType
                        imageData:(FIRInAppMessagingImageData *)imageData
                        actionURL:(nullable NSURL *)actionURL {
  if (self = [super initWithMessageID:messageID
                         campaignName:campaignName
                  renderAsTestMessage:renderAsTestMessage
                          messageType:FIRInAppMessagingDisplayMessageTypeModal
                          triggerType:triggerType]) {
    _imageData = imageData;
    _actionURL = actionURL;
  }
  return self;
}
@end

@implementation FIRInAppMessagingActionButton

- (instancetype)initWithButtonText:(NSString *)btnText
                   buttonTextColor:(UIColor *)textColor
                   backgroundColor:(UIColor *)bkgColor {
  if (self = [super init]) {
    _buttonText = btnText;
    _buttonTextColor = textColor;
    _buttonBackgroundColor = bkgColor;
  }
  return self;
}
@end

@implementation FIRInAppMessagingImageData
- (instancetype)initWithImageURL:(NSString *)imageURL imageData:(NSData *)imageData {
  if (self = [super init]) {
    _imageURL = imageURL;
    _imageRawData = imageData;
  }
  return self;
}
@end

@implementation FIRInAppMessagingCampaignInfo
- (instancetype)initWithMessageID:(NSString *)messageID
                     campaignName:(NSString *)campaignName
              renderAsTestMessage:(BOOL)renderAsTestMessage {
  if (self = [super init]) {
    _messageID = messageID;
    _campaignName = campaignName;
    _renderAsTestMessage = renderAsTestMessage;
  }
  return self;
}
@end

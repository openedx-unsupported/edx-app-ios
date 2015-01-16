//
//  OEXAnalyticsData.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 20/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#ifndef edXVideoLocker_AnalyticsData_h
#define edXVideoLocker_AnalyticsData_h


#define key_app_name @"app_name"
#define key_app_version @"version"
#define key_username @"username"
#define key_email @"email"
#define key_name @"name"
#define key_old_time @"old_time"
#define key_new_time @"new_time"
#define key_seek_type @"seek_type"
#define key_requested_skip_interval @"requested_skip_interval"
#define key_module_id @"module_id"
#define key_code @"code"
#define key_current_time @"current_time"
#define key_course_id @"course_id"
#define key_open_in_browser @"open_in_browser_url"
#define key_component @"component"
#define key_context @"context"
#define key_data @"data"
#define key_unit_url @"context"
#define key_old_speed @"old_speed"
#define key_new_speed @"new_speed"
#define key_component @"component"
#define key_No_Of_Videos @"number_of_videos"
#define key_courseSection @"courseSection"
#define key_courseSubsection @"courseSubsection"
#define key_appname @"app.name"
#define key_fullscreen @"settings.video.fullscreen"
#define key_method @"method"
#define key_target_url @"target_url"
#define key_language @"language"

//Values

#define value_app_name @"edx.mobileapp.iOS"
#define value_skip @"skip"
#define value_mobile @"mobile"
#define value_videoplayer @"videoplayer"
#define value_downloadmodule @"downloadmodule"
#define value_video_loaded @"edx.video.loaded"
#define value_video_speed @"edx.bi.video.speed.changed"
#define value_video_played @"edx.video.played"
#define value_video_paused @"edx.video.paused"
#define value_video_stopped @"edx.video.stopped"
//The seek event name has been changed as per MOB-1274
#define value_video_seeked @"edx.video.position.changed"
#define value_transcript_shown @"edx.video.transcript.shown"
#define value_transcript_hidden @"edx.video.transcript.hidden"
#define value_appname @ "edx.mobileapp.iOS"

#define value_video_downloaded @"edx.bi.video.downloaded"
#define value_bulk_download_section @"edx.bi.video.section.bulkdownload.requested"
#define value_bulk_download_subsection @"edx.bi.video.subsection.bulkdownload.requested"
#define value_single_download @"edx.bi.video.download.requested"
#define value_fullscreen @"edx.bi.video.screen.fullscreen.toggled"
#define value_login @"edx.bi.app.user.login"
#define value_logout @"edx.bi.app.user.logout"
#define value_browser_launched @"edx.bi.app.browser.launched"
#define value_transcript_language @"edx.bi.video.transcript.language.selected"
#define value_no_acccout @"edx.bi.app.user.no_account"
#define value_find_courses @"edx.bi.app.find_courses"


#endif

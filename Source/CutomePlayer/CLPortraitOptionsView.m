//
//  CLPortraitOptionsView.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 21/08/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "CLPortraitOptionsView.h"
#import "CLVideoPlayerControls.h"
#import "CLVideoPlayer.h"
#import "OEXInterface.h"
#import "OEXHelperVideoDownload.h"
#import "OEXClosedCaptionTableViewCell.h"

@interface CLPortraitOptionsView ()

@property (weak, nonatomic) IBOutlet UIButton* btn_Background;
@property (nonatomic, strong) UIView* viewOverlay;
@property (nonatomic, strong) NSString* selectedCCOption;
@property (nonatomic, strong) OEXInterface* dataInterface;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* constraint_TableHeight;

@end

static CLPortraitOptionsView* _sharedInterface = nil;

@implementation CLPortraitOptionsView

+ (id)sharedInstance {
    if(!_sharedInterface) {
        _sharedInterface = [[CLPortraitOptionsView alloc] init];
        _sharedInterface.arr_Values = [[NSMutableArray alloc] init];
    }

    return _sharedInterface;
}

- (void)addValueToArray:(NSDictionary*)dictValues {
    [self.table_Values registerNib:[UINib nibWithNibName:@"OEXClosedCaptionTableViewCell"bundle:nil] forCellReuseIdentifier:@"CustomCell"];

    [_sharedInterface.arr_Values removeAllObjects];

    _sharedInterface.arr_Values = [dictValues objectForKey:CC_VALUE_ARRAY];

//    _sharedInterface.objTranscript = [dictValues objectForKey:CC_TRANSCRIPT_OBJECT];

    _sharedInterface.selectedCCOption = [dictValues objectForKey:CC_SELECTED_INDEX];

    // get the persisted language and On the CC.
    [self setPersistedLanguage];

    // Initialize the interface
    self.dataInterface = [OEXInterface sharedInterface];

    [self changeCCPopUpSize];

    [self.table_Values reloadData];
}

// MOB - 599
- (void)changeCCPopUpSize {
    NSInteger count = [_sharedInterface.arr_Values count];

    if(count == 0) {
        return;
    }

    if(count > 3) {
        self.constraint_TableHeight.constant = 224;
    }
    else {
        self.constraint_TableHeight.constant = (count * 44) + 44 + self.btn_Cancel.frame.size.height;
    }
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // Add Observer

    [self.btn_Cancel.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:12.0]];

    self.view_Inner.layer.cornerRadius = 10;
    self.view_Inner.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view_Inner.layer.shadowRadius = 1.f;
    self.view_Inner.layer.shadowOffset = CGSizeMake(1.f, 1.f);
    self.view_Inner.layer.shadowOpacity = 0.8f;
    self.view_Inner.layer.masksToBounds = YES;
}

- (void)addViewToContainerSuperview:(UIView*)parentView {
    //Set initial frame
    [self removeSelfFromSuperView];

 #ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Values setLayoutMargins:UIEdgeInsetsZero];
    }
 #endif
    _viewOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, parentView.frame.size.width, parentView.frame.size.height)];
    _viewOverlay.backgroundColor = [UIColor blackColor];
    _viewOverlay.alpha = 0.3f;
    [parentView addSubview:_viewOverlay];

    _sharedInterface.view.frame = CGRectMake(0,
                                             0,
                                             _sharedInterface.view.frame.size.width,
                                             _sharedInterface.view.frame.size.height);
    [parentView addSubview:_sharedInterface.view];
}

- (void)removeSelfFromSuperView {
    [_sharedInterface.viewOverlay removeFromSuperview];
    [_sharedInterface.view removeFromSuperview];
}

- (IBAction)dismissView:(id)sender {
    [self removeSelfFromSuperView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* viewMain = nil;

    if(tableView == self.table_Values) {
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        viewMain.backgroundColor = GREY_COLOR;

        UILabel* chapTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 280, 44)];

        if([self.selectedCCOption isEqualToString:@"0"]) {
            chapTitle.text = @"Closed Captions";
        }
        else if([self.selectedCCOption isEqualToString:@"1"]) {
            chapTitle.text = @"Video Speed";
        }
        chapTitle.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        chapTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:chapTitle];
    }

    return viewMain;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

    return [_sharedInterface.arr_Values count];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 44;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXClosedCaptionTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
    if(cell == nil) {
        [tableView registerNib:[UINib nibWithNibName:@"OEXClosedCaptionTableViewCell"bundle:nil] forCellReuseIdentifier:@"CustomCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
    }

    // To show blue selection.
    UIView* bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = SELECTED_CELL_COLOR;
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    cell.lbl_Title.font = [UIFont fontWithName:@"OpenSans" size:12.f];

    if([self.selectedCCOption isEqualToString:@"0"]) {
        // To retain the selected blue color on selected cell
        if(indexPath.row == _dataInterface.selectedCCIndex) {
            [cell addSubview:bgColorView];
        }
        else {
            [bgColorView removeFromSuperview];
        }
    }
    else if([self.selectedCCOption isEqualToString:@"1"]) {
        // To retain the selected blue color on selected cell
        if(indexPath.row == _dataInterface.selectedVideoSpeedIndex) {
            [cell addSubview:bgColorView];
        }
        else {
            [bgColorView removeFromSuperview];
        }
    }

    cell.backgroundColor = [UIColor whiteColor];

    cell.lbl_Title.text = [self.arr_Values objectAtIndex:indexPath.row];

#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    return cell;
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self removeSelfFromSuperView];

    NSString* StrFilePath = [[NSString alloc] init];
    NSString* StrDownloadURL = [[NSString alloc] init];

    if([self.selectedCCOption isEqualToString:@"0"]) {
        _dataInterface.selectedCCIndex = indexPath.row;

        NSString* strTag = [self.arr_Values objectAtIndex:indexPath.row];

        if([strTag isEqualToString:@"Chinese"]) {
            StrFilePath = self.objTranscript.ChineseURLFilePath;
            StrDownloadURL = self.objTranscript.ChineseDownloadURLString;
        }
        else if([strTag isEqualToString:@"English"]) {
            StrFilePath = self.objTranscript.EnglishURLFilePath;
            StrDownloadURL = self.objTranscript.EnglishDownloadURLString;
        }
        else if([strTag isEqualToString:@"German"]) {
            StrFilePath = self.objTranscript.GermanURLFilePath;
            StrDownloadURL = self.objTranscript.GermanDownloadURLString;
        }
        else if([strTag isEqualToString:@"Portuguese"]) {
            StrFilePath = self.objTranscript.PortugueseURLFilePath;
            StrDownloadURL = self.objTranscript.PortugueseDownloadURLString;
        }
        else if([strTag isEqualToString:@"Spanish"]) {
            StrFilePath = self.objTranscript.SpanishURLFilePath;
            StrDownloadURL = self.objTranscript.SpanishDownloadURLString;
        }
        else if([strTag isEqualToString:@"French"]) {
            StrFilePath = self.objTranscript.FrenchURLFilePath;
            StrDownloadURL = self.objTranscript.FrenchDownloadURLString;
        }

        // Set the language to persist
        [OEXInterface setCCSelectedLanguage:strTag];

        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: StrFilePath, KEY_SET_CC_URL:StrDownloadURL}];
    }
    else if([self.selectedCCOption isEqualToString:@"1"]) {
        StrFilePath = @"1.0";

        _dataInterface.selectedVideoSpeedIndex = indexPath.row;

        switch(indexPath.row)
        {
            case 0:
                StrFilePath = @"0.5";
                break;

            case 1:
                StrFilePath = @"1.0";
                break;

            case 2:
                StrFilePath = @"1.5";
                break;

            case 3:
                StrFilePath = @"2.0";
                break;

            default:
                break;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_PLAYBACKSPEED: StrFilePath}];
    }
}

- (void)setPersistedLanguage {
    NSString* strLanguage = [OEXInterface getCCSelectedLanguage];

    if(!strLanguage || [strLanguage isEqualToString:@""]) {
        return;
    }
    for(int i = 0; i < [self.arr_Values count]; i++) {
        if([strLanguage isEqualToString: [self.arr_Values objectAtIndex:i]]) {
            self.selectedCCOption = @"0";
            _dataInterface.selectedCCIndex = i;
            break;
        }
        if(i == [self.arr_Values count] - 1) {
            return;
        }
    }

    if([self.selectedCCOption isEqualToString:@"0"]) {
        if([strLanguage isEqualToString:@"Chinese"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: self.objTranscript.ChineseURLFilePath, KEY_SET_CC_URL:self.objTranscript.ChineseDownloadURLString}];
        }
        else if([strLanguage isEqualToString:@"English"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: self.objTranscript.EnglishURLFilePath, KEY_SET_CC_URL:self.objTranscript.EnglishDownloadURLString}];
        }
        else if([strLanguage isEqualToString:@"German"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: self.objTranscript.GermanURLFilePath, KEY_SET_CC_URL:self.objTranscript.GermanDownloadURLString}];
        }
        else if([strLanguage isEqualToString:@"Portuguese"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: self.objTranscript.PortugueseURLFilePath, KEY_SET_CC_URL:self.objTranscript.PortugueseDownloadURLString}];
        }
        else if([strLanguage isEqualToString:@"Spanish"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: self.objTranscript.SpanishURLFilePath, KEY_SET_CC_URL:self.objTranscript.SpanishDownloadURLString}];
        }
        else if([strLanguage isEqualToString:@"French"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: self.objTranscript.FrenchURLFilePath, KEY_SET_CC_URL:self.objTranscript.FrenchDownloadURLString}];
        }
    }

    [self.table_Values reloadData];
}

- (void)didReceiveMemoryWarning {
    ELog(@"MemoryWarning CLPortraitOptionView");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelBtnClicked:(id)sender {
    [self removeSelfFromSuperView];

    if([self.selectedCCOption isEqualToString:@"0"]) {
        _dataInterface.selectedCCIndex = -1;

        // Set the language to blank
        [OEXInterface setCCSelectedLanguage:@""];

        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_CC: @"off", KEY_SET_CC_URL:@""}];
    }
    else if([self.selectedCCOption isEqualToString:@"1"]) {
        _dataInterface.selectedVideoSpeedIndex = -1;

        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CC_SELECTED object:self userInfo:@{KEY_SET_PLAYBACKSPEED: @"1.0"}];
    }
}

@end

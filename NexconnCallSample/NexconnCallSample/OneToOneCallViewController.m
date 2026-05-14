//
//  OneToOneCallViewController.m
//  NexconnCallSample
//

#import "OneToOneCallViewController.h"
#import <NexconnChatSDK/NexconnChatSDK-Swift.h>
#import <NexconnCall/NexconnCall.h>

typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypeAudioVideo = 0,
    MediaTypeAudio = 1
};

@interface OneToOneCallViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NCCallEventHandler, NCCallAPIResultHandler>

// Left side controls
@property (nonatomic, strong) UIScrollView *leftScrollView;
@property (nonatomic, strong) UIView *leftContainerView;
@property (nonatomic, strong) UITextField *calleeUserIdTextField;
@property (nonatomic, strong) UISegmentedControl *mediaTypeSegment;
@property (nonatomic, strong) UIButton *startCallButton;
@property (nonatomic, strong) UIButton *endCallButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *microphoneButton;
@property (nonatomic, strong) UIButton *speakerButton;
@property (nonatomic, strong) UIButton *changeToVideoButton;

// Right side user views
@property (nonatomic, strong) NCCallLocalVideoView *localVideoView;
@property (nonatomic, strong) UILabel *localUserLabel;
@property (nonatomic, strong) NCCallRemoteVideoView *remoteVideoView;
@property (nonatomic, strong) UILabel *remoteUserLabel;

// Bottom call log
@property (nonatomic, strong) UITableView *callLogTableView;
@property (nonatomic, strong) NSMutableArray<NCCallLog *> *callLogs;

// State
@property (nonatomic, assign) BOOL isCameraEnabled;
@property (nonatomic, assign) MediaType selectedMediaType;
@property (nonatomic, copy) NSString *currentCallId;
@property (nonatomic, copy) NSString *currentUserId;

@end

@implementation OneToOneCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"1v1 Call";
    self.view.backgroundColor = [UIColor whiteColor];

    self.isCameraEnabled = NO;
    self.selectedMediaType = MediaTypeAudioVideo;
    self.callLogs = [NSMutableArray array];
    self.currentUserId = [NCEngine getCurrentUserId];

    // Enable microphone by default
    [NCCallEngine getInstance].enableMicrophone = YES;

    [self setupUI];
    [self setupCallHandlers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // End call if there's an active call
    if (self.currentCallId) {
        NCCallEndCallParams *params = [[NCCallEndCallParams alloc] initWithCallId:self.currentCallId];
        [[NCCallEngine getInstance] endCall:params];
        self.currentCallId = nil;
    }

    // Disable camera if it's enabled
    if (self.isCameraEnabled) {
        [[NCCallEngine getInstance] enableCamera:NO];
        self.isCameraEnabled = NO;
    }

    // Remove handlers when leaving the page
    [[NCCallEngine getInstance] setCallEventHandler:nil];
    [[NCCallEngine getInstance] setAPIResultHandler:nil];
}

- (void)dealloc {
    [[NCCallEngine getInstance] setCallEventHandler:nil];
    [[NCCallEngine getInstance] setAPIResultHandler:nil];
}

#pragma mark - Setup

- (void)setupCallHandlers {
    // Set call event handler and API result handler
    [[NCCallEngine getInstance] setCallEventHandler:self];
    [[NCCallEngine getInstance] setAPIResultHandler:self];
}

- (void)setupUI {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat leftWidth = screenWidth * 0.4;
    CGFloat rightWidth = screenWidth * 0.6;
    CGFloat contentHeight = screenHeight - navBarHeight;

    // Left side controls - limit height to avoid overlap
    [self setupLeftControls:CGRectMake(0, navBarHeight, leftWidth, contentHeight * 0.6)];

    // Right side user views
    [self setupRightUserViews:CGRectMake(leftWidth, navBarHeight, rightWidth, contentHeight * 0.6)];

    // Bottom call log
    [self setupCallLogView:CGRectMake(0, navBarHeight + contentHeight * 0.6, screenWidth, contentHeight * 0.4)];
}

- (void)setupLeftControls:(CGRect)frame {
    self.leftScrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.leftScrollView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.view addSubview:self.leftScrollView];
    
    self.leftContainerView = [[UIView alloc] init];
    [self.leftScrollView addSubview:self.leftContainerView];
    
    CGFloat padding = 15;
    CGFloat width = frame.size.width - 2 * padding;
    CGFloat yOffset = padding;
    CGFloat buttonHeight = 40;
    CGFloat spacing = 10;
    
    // Callee UserId TextField
    UILabel *calleeLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width, 20)];
    calleeLabel.text = @"Callee UserId:";
    calleeLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.leftContainerView addSubview:calleeLabel];
    yOffset += 25;
    
    self.calleeUserIdTextField = [[UITextField alloc] initWithFrame:CGRectMake(padding, yOffset, width, buttonHeight)];
    self.calleeUserIdTextField.placeholder = @"Enter callee userId";
    self.calleeUserIdTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.calleeUserIdTextField.font = [UIFont systemFontOfSize:13];
    self.calleeUserIdTextField.delegate = self;
    [self.leftContainerView addSubview:self.calleeUserIdTextField];
    yOffset += buttonHeight + spacing * 2;
    
    // MediaType Segment
    UILabel *mediaLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width, 20)];
    mediaLabel.text = @"Media Type:";
    mediaLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.leftContainerView addSubview:mediaLabel];
    yOffset += 25;
    
    self.mediaTypeSegment = [[UISegmentedControl alloc] initWithItems:@[@"Video", @"Audio"]];
    self.mediaTypeSegment.frame = CGRectMake(padding, yOffset, width, buttonHeight);
    self.mediaTypeSegment.selectedSegmentIndex = 0;
    [self.mediaTypeSegment addTarget:self action:@selector(mediaTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.leftContainerView addSubview:self.mediaTypeSegment];
    yOffset += buttonHeight + spacing * 2;
    
    // Start Call Button
    self.startCallButton = [self createButtonWithTitle:@"Start Call" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemGreenColor]];
    [self.startCallButton addTarget:self action:@selector(startCallTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.startCallButton];
    yOffset += buttonHeight + spacing;
    
    // End Call Button
    self.endCallButton = [self createButtonWithTitle:@"End Call" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemRedColor]];
    [self.endCallButton addTarget:self action:@selector(endCallTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.endCallButton];
    yOffset += buttonHeight + spacing;
    
    // Camera Button
    self.cameraButton = [self createButtonWithTitle:@"Enable Camera" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.cameraButton addTarget:self action:@selector(cameraTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.cameraButton];
    yOffset += buttonHeight + spacing;
    
    // Switch Camera Button
    self.switchCameraButton = [self createButtonWithTitle:@"Switch Camera" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.switchCameraButton addTarget:self action:@selector(switchCameraTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.switchCameraButton];
    yOffset += buttonHeight + spacing;
    
    // Microphone Button
    self.microphoneButton = [self createButtonWithTitle:@"Disable Microphone" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.microphoneButton addTarget:self action:@selector(microphoneTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.microphoneButton];
    yOffset += buttonHeight + spacing;
    
    // Speaker Button
    self.speakerButton = [self createButtonWithTitle:@"Enable Speaker" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.speakerButton addTarget:self action:@selector(speakerTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.speakerButton];
    yOffset += buttonHeight + spacing;
    
    // Change To Video Button
    self.changeToVideoButton = [self createButtonWithTitle:@"Change To Video Call" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemOrangeColor]];
    [self.changeToVideoButton addTarget:self action:@selector(changeToVideoTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.changeToVideoButton];
    yOffset += buttonHeight + padding;
    
    self.leftContainerView.frame = CGRectMake(0, 0, frame.size.width, yOffset);
    self.leftScrollView.contentSize = CGSizeMake(frame.size.width, yOffset);
}

- (void)setupRightUserViews:(CGRect)frame {
    CGFloat halfHeight = frame.size.height / 2;
    CGFloat padding = 10;

    // Local Video View
    self.localVideoView = [[NCCallLocalVideoView alloc] initWithFrame:CGRectMake(frame.origin.x + padding, frame.origin.y + padding, frame.size.width - 2 * padding, halfHeight - 2 * padding)];
    self.localVideoView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.localVideoView.layer.cornerRadius = 8;
    self.localVideoView.layer.masksToBounds = YES;
    self.localVideoView.renderMode = NCCallRenderModeAspectFill;
    self.localVideoView.userId = self.currentUserId;
    [self.view addSubview:self.localVideoView];

    self.localUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.localVideoView.bounds.size.width - 20, 30)];
    self.localUserLabel.text = @"Local User";
    self.localUserLabel.textColor = [UIColor whiteColor];
    self.localUserLabel.textAlignment = NSTextAlignmentCenter;
    self.localUserLabel.font = [UIFont boldSystemFontOfSize:16];
    self.localUserLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.localUserLabel.layer.cornerRadius = 4;
    self.localUserLabel.layer.masksToBounds = YES;
    [self.localVideoView addSubview:self.localUserLabel];

    // Remote Video View
    self.remoteVideoView = [[NCCallRemoteVideoView alloc] initWithFrame:CGRectMake(frame.origin.x + padding, frame.origin.y + halfHeight + padding, frame.size.width - 2 * padding, halfHeight - 2 * padding)];
    self.remoteVideoView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    self.remoteVideoView.layer.cornerRadius = 8;
    self.remoteVideoView.layer.masksToBounds = YES;
    self.remoteVideoView.renderMode = NCCallRenderModeAspectFill;
    self.remoteVideoView.enableLowResolutionStream = NO;
    [self.view addSubview:self.remoteVideoView];

    self.remoteUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.remoteVideoView.bounds.size.width - 20, 30)];
    self.remoteUserLabel.text = @"Remote User";
    self.remoteUserLabel.textColor = [UIColor whiteColor];
    self.remoteUserLabel.textAlignment = NSTextAlignmentCenter;
    self.remoteUserLabel.font = [UIFont boldSystemFontOfSize:16];
    self.remoteUserLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.remoteUserLabel.layer.cornerRadius = 4;
    self.remoteUserLabel.layer.masksToBounds = YES;
    [self.remoteVideoView addSubview:self.remoteUserLabel];
}

- (void)setupCallLogView:(CGRect)frame {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, frame.origin.y, frame.size.width - 20, 30)];
    titleLabel.text = @"Call Logs:";
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.view addSubview:titleLabel];
    
    self.callLogTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, frame.origin.y + 30, frame.size.width, frame.size.height - 30) style:UITableViewStylePlain];
    self.callLogTableView.delegate = self;
    self.callLogTableView.dataSource = self;
    [self.callLogTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CallLogCell"];
    [self.view addSubview:self.callLogTableView];
}

- (UIButton *)createButtonWithTitle:(NSString *)title frame:(CGRect)frame color:(UIColor *)color {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = color;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    button.layer.cornerRadius = 6;
    return button;
}

#pragma mark - Button Actions

- (void)mediaTypeChanged:(UISegmentedControl *)sender {
    self.selectedMediaType = sender.selectedSegmentIndex;
}

- (void)startCallTapped:(UIButton *)sender {
    NSString *calleeUserId = self.calleeUserIdTextField.text;
    if (calleeUserId.length == 0) {
        [self showToast:@"Please enter callee userId"];
        return;
    }

    NCCallMediaType mediaType = (self.selectedMediaType == MediaTypeAudioVideo) ? NCCallMediaTypeAudioVideo : NCCallMediaTypeAudio;
    NCCallStartCallParams *params = [[NCCallStartCallParams alloc] initWithCalleeIds:@[calleeUserId]
                                                                             callType:NCCallTypeSingle
                                                                            mediaType:mediaType];

    [[NCCallEngine getInstance] startCall:params];

    // Update UI based on media type
    if (self.selectedMediaType == MediaTypeAudioVideo) {
        self.localUserLabel.text = @"Video Preview";
    } else {
        self.localUserLabel.text = @"Audio";
    }
}

- (void)endCallTapped:(UIButton *)sender {
    if (self.currentCallId) {
        NCCallEndCallParams *params = [[NCCallEndCallParams alloc] initWithCallId:self.currentCallId];
        [[NCCallEngine getInstance] endCall:params];
    }
}

- (void)cameraTapped:(UIButton *)sender {
    self.isCameraEnabled = !self.isCameraEnabled;
    [[NCCallEngine getInstance] enableCamera:self.isCameraEnabled];
    [sender setTitle:self.isCameraEnabled ? @"Disable Camera" : @"Enable Camera" forState:UIControlStateNormal];

    // Set local video view when camera is enabled (works even without active call)
    if (self.isCameraEnabled) {
        [[NCCallEngine getInstance] setLocalVideoView:self.localVideoView];
    }
}

- (void)switchCameraTapped:(UIButton *)sender {
    [[NCCallEngine getInstance] switchCamera];
}

- (void)microphoneTapped:(UIButton *)sender {
    BOOL isEnabled = [NCCallEngine getInstance].enableMicrophone;
    [NCCallEngine getInstance].enableMicrophone = !isEnabled;
    [sender setTitle:isEnabled ? @"Enable Microphone" : @"Disable Microphone" forState:UIControlStateNormal];
}

- (void)speakerTapped:(UIButton *)sender {
    BOOL isEnabled = [NCCallEngine getInstance].enableSpeaker;
    [NCCallEngine getInstance].enableSpeaker = !isEnabled;
    [sender setTitle:isEnabled ? @"Enable Speaker" : @"Disable Speaker" forState:UIControlStateNormal];
}

- (void)changeToVideoTapped:(UIButton *)sender {
    NCCallRequestChangeMediaTypeParams *params = [[NCCallRequestChangeMediaTypeParams alloc] initWithMediaType:NCCallMediaTypeAudioVideo];
    [[NCCallEngine getInstance] requestChangeMediaType:params];
}

#pragma mark - NCCallEventHandler

- (void)onCallReceived:(NCCallReceivedEvent *)event {
    NSLog(@"Call received from %@", event.session.callerUserId);

    dispatch_async(dispatch_get_main_queue(), ^{
        // Dismiss any existing alert first
        if (self.presentedViewController) {
            [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
                [self showIncomingCallAlert:event];
            }];
        } else {
            [self showIncomingCallAlert:event];
        }
    });
}

- (void)showIncomingCallAlert:(NCCallReceivedEvent *)event {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Incoming Call"
                                                                   message:[NSString stringWithFormat:@"From: %@", event.session.callerUserId]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Accept" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NCCallAcceptCallParams *params = [[NCCallAcceptCallParams alloc] initWithCallId:event.session.callId];
        [[NCCallEngine getInstance] acceptCall:params];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Decline" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NCCallEndCallParams *params = [[NCCallEndCallParams alloc] initWithCallId:event.session.callId];
        [[NCCallEngine getInstance] endCall:params];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onCallConnected:(NCCallConnectedEvent *)event {
    [self showToast:@"Call connected"];
    self.currentCallId = event.session.callId;

    dispatch_async(dispatch_get_main_queue(), ^{
        // Only set up video views and camera for video calls
        if (self.selectedMediaType == MediaTypeAudioVideo) {
            // Auto enable camera when call is connected (for video calls only)
            if (!self.isCameraEnabled) {
                self.isCameraEnabled = YES;
                [[NCCallEngine getInstance] enableCamera:YES];
                [self.cameraButton setTitle:@"Disable Camera" forState:UIControlStateNormal];
            }

            // Set up video views
            NCCallSession *session = [[NCCallEngine getInstance] getCurrentCallSession];
            if (session) {
                // Set local video view
                self.localVideoView.userId = session.callerUserId;
                [[NCCallEngine getInstance] setLocalVideoView:self.localVideoView];

                // Set remote video view
                if (session.remoteParticipants.count > 0) {
                    NCCallUser *remoteUser = session.remoteParticipants.firstObject;
                    self.remoteVideoView.userId = remoteUser.userId;
                    [[NCCallEngine getInstance] setRemoteVideoView:@[self.remoteVideoView]];
                    self.remoteUserLabel.text = remoteUser.userId;
                }
            }
        } else {
            // For audio calls, just update the label
            NCCallSession *session = [[NCCallEngine getInstance] getCurrentCallSession];
            if (session && session.remoteParticipants.count > 0) {
                NCCallUser *remoteUser = session.remoteParticipants.firstObject;
                self.remoteUserLabel.text = [NSString stringWithFormat:@"%@'s audio", remoteUser.userId];
            }
        }
    });
}

- (void)onCallEnded:(NCCallEndedEvent *)event {
    [self showToast:[NSString stringWithFormat:@"Call ended: %ld", (long)event.reason]];
    self.currentCallId = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.localUserLabel.text = @"Local User";
        self.remoteUserLabel.text = @"Remote User";
    });
}

- (void)onRemoteUserStateChanged:(NCCallRemoteUserStateChangedEvent *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Check if user left the call
        if (event.userState == NCCallUserStateIdle) {
            self.remoteUserLabel.text = @"Remote User (Left)";
            [self showToast:[NSString stringWithFormat:@"User %@ left", event.userId]];
        }
    });
}

- (void)onMediaTypeChangeRequestReceived:(NCCallMediaTypeChangeRequestReceivedEvent *)event {
    [self showToast:@"Media type change request received"];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"TransactionId: %@\nRequested MediaType: %@\nFrom: %@",
                           event.transactionId,
                           event.mediaType == NCCallMediaTypeAudioVideo ? @"Video" : @"Audio",
                           event.userId];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Media Type Change Request"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"Agree" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NCCallReplyChangeMediaTypeParams *params = [[NCCallReplyChangeMediaTypeParams alloc] initWithTransactionId:event.transactionId isAgreed:YES];
            [[NCCallEngine getInstance] replyChangeMediaType:params];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Disagree" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NCCallReplyChangeMediaTypeParams *params = [[NCCallReplyChangeMediaTypeParams alloc] initWithTransactionId:event.transactionId isAgreed:NO];
            [[NCCallEngine getInstance] replyChangeMediaType:params];
        }]];

        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)onServerCallLogReceived:(NCCallServerCallLogReceivedEvent *)event {
    [self showToast:@"Call log received"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.callLogs addObject:event.callLog];
        [self.callLogTableView reloadData];
    });
}

#pragma mark - NCCallAPIResultHandler

- (void)onStartCallResult:(NCCallStartCallResult *)result {
    if (result.code != NCCallCodeSuccess) {
        [self showToast:[NSString stringWithFormat:@"Start call failed: code %ld", (long)result.code]];
    } else {
        [self showToast:@"Start call success"];
        self.currentCallId = result.callId;
    }
}

- (void)onEndCallResult:(NCCallEndCallResult *)result {
    if (result.code != NCCallCodeSuccess) {
        [self showToast:[NSString stringWithFormat:@"End call failed: code %ld", (long)result.code]];
    } else {
        [self showToast:@"End call success"];
    }
}

- (void)onAcceptCallResult:(NCCallAcceptCallResult *)result {
    if (result.code != NCCallCodeSuccess) {
        [self showToast:[NSString stringWithFormat:@"Accept call failed: code %ld", (long)result.code]];
    } else {
        [self showToast:@"Accept call success"];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.callLogs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CallLogCell" forIndexPath:indexPath];

    NCCallLog *log = self.callLogs[indexPath.row];
    NSString *text = [NSString stringWithFormat:@"Start: %@ | End: %@ | Participants: %@ | Duration: %lds",
                     [self formatTimestamp:log.startTime],
                     [self formatTimestamp:log.endTime],
                     [log.participants componentsJoinedByString:@", "],
                     (long)log.duration];

    cell.textLabel.text = text;
    cell.textLabel.font = [UIFont systemFontOfSize:11];
    cell.textLabel.numberOfLines = 0;

    return cell;
}

#pragma mark - Helper Methods

- (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:toast animated:YES completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    return [formatter stringFromDate:date];
}

- (NSString *)formatTimestamp:(NSInteger)timestamp {
    if (timestamp == 0) {
        return @"N/A";
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp / 1000.0];
    return [self formatDate:date];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

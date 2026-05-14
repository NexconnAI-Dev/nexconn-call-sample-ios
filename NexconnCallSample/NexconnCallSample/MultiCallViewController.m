//
//  MultiCallViewController.m
//  NexconnCallSample
//

#import "MultiCallViewController.h"
#import <NexconnChatSDK/NexconnChatSDK-Swift.h>
#import <NexconnCall/NexconnCall.h>

typedef NS_ENUM(NSInteger, MediaType) {
    MediaTypeAudioVideo = 0,
    MediaTypeAudio = 1
};

@interface MultiCallViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NCCallEventHandler, NCCallAPIResultHandler>

// Left side controls
@property (nonatomic, strong) UIScrollView *leftScrollView;
@property (nonatomic, strong) UIView *leftContainerView;
@property (nonatomic, strong) UITextField *calleeUserIdsTextField;
@property (nonatomic, strong) UISegmentedControl *mediaTypeSegment;
@property (nonatomic, strong) UIButton *startCallButton;
@property (nonatomic, strong) UIButton *endCallButton;
@property (nonatomic, strong) UIButton *inviteToCallButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *microphoneButton;
@property (nonatomic, strong) UIButton *speakerButton;

// Right side user views
@property (nonatomic, strong) NCCallLocalVideoView *localVideoView;
@property (nonatomic, strong) UILabel *localUserLabel;
@property (nonatomic, strong) UITableView *remoteUsersTableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *remoteUsers;

// Bottom call log
@property (nonatomic, strong) UITableView *callLogTableView;
@property (nonatomic, strong) NSMutableArray<NCCallLog *> *callLogs;

// State
@property (nonatomic, assign) BOOL isCameraEnabled;
@property (nonatomic, assign) MediaType selectedMediaType;
@property (nonatomic, copy) NSString *currentCallId;
@property (nonatomic, copy) NSString *currentUserId;

@end

@implementation MultiCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Multi Call";
    self.view.backgroundColor = [UIColor whiteColor];

    self.isCameraEnabled = NO;
    self.selectedMediaType = MediaTypeAudioVideo;
    self.callLogs = [NSMutableArray array];
    self.remoteUsers = [NSMutableArray array];
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

    // Clear remote users
    [self.remoteUsers removeAllObjects];
    [self.remoteUsersTableView reloadData];

    // Remove handlers
    [[NCCallEngine getInstance] setCallEventHandler:nil];
    [[NCCallEngine getInstance] setAPIResultHandler:nil];
}

- (void)dealloc {
    [[NCCallEngine getInstance] setCallEventHandler:nil];
    [[NCCallEngine getInstance] setAPIResultHandler:nil];
}

#pragma mark - Setup

- (void)setupCallHandlers {
    [[NCCallEngine getInstance] setCallEventHandler:self];
    [[NCCallEngine getInstance] setAPIResultHandler:self];
}

- (void)setupUI {
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat navBarHeight = 88;
    CGFloat leftWidth = screenWidth * 0.4;
    CGFloat rightWidth = screenWidth * 0.6;
    CGFloat contentHeight = screenHeight - navBarHeight;

    // Left side controls - limit height to avoid overlap
    [self setupLeftControls:CGRectMake(0, navBarHeight, leftWidth, contentHeight * 0.6)];

    // Right side: local video view at top, remote users table view below
    CGFloat localVideoHeight = contentHeight * 0.3;
    CGFloat remoteUsersHeight = contentHeight * 0.3;
    [self setupLocalVideoView:CGRectMake(leftWidth, navBarHeight, rightWidth, localVideoHeight)];
    [self setupRemoteUsersTableView:CGRectMake(leftWidth, navBarHeight + localVideoHeight, rightWidth, remoteUsersHeight)];

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

    UILabel *calleeLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width, 20)];
    calleeLabel.text = @"Callee UserIds:";
    calleeLabel.font = [UIFont boldSystemFontOfSize:12];
    calleeLabel.numberOfLines = 0;
    [self.leftContainerView addSubview:calleeLabel];
    yOffset += 35;

    self.calleeUserIdsTextField = [[UITextField alloc] initWithFrame:CGRectMake(padding, yOffset, width, buttonHeight)];
    self.calleeUserIdsTextField.placeholder = @"user1,user2,user3";
    self.calleeUserIdsTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.calleeUserIdsTextField.font = [UIFont systemFontOfSize:13];
    self.calleeUserIdsTextField.delegate = self;
    [self.leftContainerView addSubview:self.calleeUserIdsTextField];
    yOffset += buttonHeight + spacing * 2;

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

    self.startCallButton = [self createButtonWithTitle:@"Start Call" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemGreenColor]];
    [self.startCallButton addTarget:self action:@selector(startCallTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.startCallButton];
    yOffset += buttonHeight + spacing;

    self.endCallButton = [self createButtonWithTitle:@"End Call" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemRedColor]];
    [self.endCallButton addTarget:self action:@selector(endCallTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.endCallButton];
    yOffset += buttonHeight + spacing;

    self.inviteToCallButton = [self createButtonWithTitle:@"Invite to Call" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemPurpleColor]];
    [self.inviteToCallButton addTarget:self action:@selector(inviteToCallTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.inviteToCallButton];
    yOffset += buttonHeight + spacing;

    self.cameraButton = [self createButtonWithTitle:@"Enable Camera" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.cameraButton addTarget:self action:@selector(cameraTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.cameraButton];
    yOffset += buttonHeight + spacing;

    self.switchCameraButton = [self createButtonWithTitle:@"Switch Camera" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.switchCameraButton addTarget:self action:@selector(switchCameraTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.switchCameraButton];
    yOffset += buttonHeight + spacing;

    self.microphoneButton = [self createButtonWithTitle:@"Disable Microphone" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.microphoneButton addTarget:self action:@selector(microphoneTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.microphoneButton];
    yOffset += buttonHeight + spacing;

    self.speakerButton = [self createButtonWithTitle:@"Enable Speaker" frame:CGRectMake(padding, yOffset, width, buttonHeight) color:[UIColor systemBlueColor]];
    [self.speakerButton addTarget:self action:@selector(speakerTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftContainerView addSubview:self.speakerButton];
    yOffset += buttonHeight + padding;

    self.leftContainerView.frame = CGRectMake(0, 0, frame.size.width, yOffset);
    self.leftScrollView.contentSize = CGSizeMake(frame.size.width, yOffset);
}

- (void)setupLocalVideoView:(CGRect)frame {
    // Local Video View
    self.localVideoView = [[NCCallLocalVideoView alloc] initWithFrame:frame];
    self.localVideoView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.localVideoView.layer.cornerRadius = 8;
    self.localVideoView.layer.masksToBounds = YES;
    self.localVideoView.renderMode = NCCallRenderModeAspectFill;
    self.localVideoView.userId = self.currentUserId;
    [self.view addSubview:self.localVideoView];

    self.localUserLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, frame.size.width - 20, 30)];
    self.localUserLabel.text = @"Local User";
    self.localUserLabel.textColor = [UIColor whiteColor];
    self.localUserLabel.textAlignment = NSTextAlignmentCenter;
    self.localUserLabel.font = [UIFont boldSystemFontOfSize:16];
    self.localUserLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.localUserLabel.layer.cornerRadius = 4;
    self.localUserLabel.layer.masksToBounds = YES;
    [self.localVideoView addSubview:self.localUserLabel];
}

- (void)setupRemoteUsersTableView:(CGRect)frame {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 10, frame.origin.y, frame.size.width - 20, 25)];
    titleLabel.text = @"Remote Users:";
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.view addSubview:titleLabel];

    // Calculate row height to match local video height
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat navBarHeight = 88;
    CGFloat contentHeight = screenHeight - navBarHeight;
    CGFloat videoHeight = contentHeight * 0.3;  // Same as local video height

    self.remoteUsersTableView = [[UITableView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y + 25, frame.size.width, frame.size.height - 25) style:UITableViewStylePlain];
    self.remoteUsersTableView.delegate = self;
    self.remoteUsersTableView.dataSource = self;
    self.remoteUsersTableView.rowHeight = videoHeight;  // Set row height to match local video height
    self.remoteUsersTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.remoteUsersTableView.separatorInset = UIEdgeInsetsZero;
    self.remoteUsersTableView.layoutMargins = UIEdgeInsetsZero;
    [self.remoteUsersTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RemoteUserCell"];
    [self.view addSubview:self.remoteUsersTableView];
}

- (void)setupRemoteVideoViews {
    if (self.remoteUsers.count == 0) {
        [[NCCallEngine getInstance] setRemoteVideoView:@[]];
        return;
    }

    NSMutableArray<NCCallRemoteVideoView *> *remoteVideoViews = [NSMutableArray array];

    for (NSInteger i = 0; i < self.remoteUsers.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *cell = [self.remoteUsersTableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            // Find the video view by tag
            NCCallRemoteVideoView *remoteVideoView = (NCCallRemoteVideoView *)[cell.contentView viewWithTag:1000];
            if (remoteVideoView && [remoteVideoView isKindOfClass:[NCCallRemoteVideoView class]]) {
                [remoteVideoViews addObject:remoteVideoView];
            }
        }
    }

    if (remoteVideoViews.count > 0) {
        [[NCCallEngine getInstance] setRemoteVideoView:remoteVideoViews];
    }
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
    NSString *calleeUserIds = self.calleeUserIdsTextField.text;
    if (calleeUserIds.length == 0) {
        [self showToast:@"Please enter callee userIds"];
        return;
    }

    NSArray *userIds = [calleeUserIds componentsSeparatedByString:@","];
    NSMutableArray *trimmedUserIds = [NSMutableArray array];
    for (NSString *userId in userIds) {
        NSString *trimmed = [userId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimmed.length > 0) {
            [trimmedUserIds addObject:trimmed];
        }
    }

    if (trimmedUserIds.count == 0) {
        [self showToast:@"Please enter valid callee userIds"];
        return;
    }

    NCCallMediaType mediaType = (self.selectedMediaType == MediaTypeAudioVideo) ? NCCallMediaTypeAudioVideo : NCCallMediaTypeAudio;
    NCCallStartCallParams *params = [[NCCallStartCallParams alloc] initWithCalleeIds:trimmedUserIds
                                                                             callType:NCCallTypeMultiple
                                                                            mediaType:mediaType];

    [[NCCallEngine getInstance] startCall:params];

    // Don't add participants here, wait for onCallConnected
}

- (void)endCallTapped:(UIButton *)sender {
    if (self.currentCallId) {
        NCCallEndCallParams *params = [[NCCallEndCallParams alloc] initWithCallId:self.currentCallId];
        [[NCCallEngine getInstance] endCall:params];
    }
}

- (void)inviteToCallTapped:(UIButton *)sender {
    if (!self.currentCallId) {
        [self showToast:@"No active call to invite users to"];
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invite to Call"
                                                                   message:@"Enter user IDs to invite"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"callee userIds: divided by comma";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Invite" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        NSString *userIdsText = textField.text;

        if (userIdsText.length == 0) {
            [self showToast:@"Please enter user IDs"];
            return;
        }

        // Parse user IDs
        NSArray *userIds = [userIdsText componentsSeparatedByString:@","];
        NSMutableArray *trimmedUserIds = [NSMutableArray array];
        for (NSString *userId in userIds) {
            NSString *trimmed = [userId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (trimmed.length > 0) {
                [trimmedUserIds addObject:trimmed];
            }
        }

        if (trimmedUserIds.count == 0) {
            [self showToast:@"Please enter valid user IDs"];
            return;
        }

        // Call inviteToCall API
        NCCallInviteToCallParams *params = [[NCCallInviteToCallParams alloc] initWithCalleeIds:trimmedUserIds];
        [[NCCallEngine getInstance] inviteToCall:params];
        [self showToast:[NSString stringWithFormat:@"Inviting %@ to call", [trimmedUserIds componentsJoinedByString:@", "]]];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)cameraTapped:(UIButton *)sender {
    self.isCameraEnabled = !self.isCameraEnabled;
    [[NCCallEngine getInstance] enableCamera:self.isCameraEnabled];
    [sender setTitle:self.isCameraEnabled ? @"Disable Camera" : @"Enable Camera" forState:UIControlStateNormal];

    // Set local video view when camera is enabled
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
        // Clear remote users list
        [self.remoteUsers removeAllObjects];

        // Add remote users
        if (event.session.remoteParticipants) {
            for (NCCallUser *user in event.session.remoteParticipants) {
                [self.remoteUsers addObject:user.userId];
            }
        }

        // Reload remote users table view
        [self.remoteUsersTableView reloadData];

        // Only set up video views for video calls
        if (self.selectedMediaType == MediaTypeAudioVideo) {
            // Auto enable camera when call is connected (for video calls only)
            if (!self.isCameraEnabled) {
                self.isCameraEnabled = YES;
                [[NCCallEngine getInstance] enableCamera:YES];
                [self.cameraButton setTitle:@"Disable Camera" forState:UIControlStateNormal];
            }

            // Set up video views after a short delay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Set local video view
                [[NCCallEngine getInstance] setLocalVideoView:self.localVideoView];

                // Set remote video views
                [self setupRemoteVideoViews];
            });
        }
    });
}

- (void)onCallEnded:(NCCallEndedEvent *)event {
    [self showToast:[NSString stringWithFormat:@"Call ended: %ld", (long)event.reason]];
    self.currentCallId = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.remoteUsers removeAllObjects];
        [self.remoteUsersTableView reloadData];
    });
}

- (void)onRemoteUserStateChanged:(NCCallRemoteUserStateChangedEvent *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (event.userState == NCCallUserStateOnCall) {
            // User joined or connected to the call
            if (![self.remoteUsers containsObject:event.userId]) {
                // Add new user to remote users list
                [self.remoteUsers addObject:event.userId];

                // Reload table view
                [self.remoteUsersTableView reloadData];

                // Update remote video views after a short delay
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setupRemoteVideoViews];
                });

                [self showToast:[NSString stringWithFormat:@"User %@ joined", event.userId]];
            }
        } else if (event.userState == NCCallUserStateIdle) {
            // User left the call
            if ([self.remoteUsers containsObject:event.userId]) {
                // Remove user from remote users list
                [self.remoteUsers removeObject:event.userId];

                // Reload table view
                [self.remoteUsersTableView reloadData];

                // Update remote video views after a short delay
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setupRemoteVideoViews];
                });

                [self showToast:[NSString stringWithFormat:@"User %@ left", event.userId]];
            }
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

- (void)onStartCall:(NCCallStartCallResult *)result {
    if (result.code != NCCallCodeSuccess) {
        [self showToast:[NSString stringWithFormat:@"Start call failed: code %ld", (long)result.code]];
    } else {
        [self showToast:@"Start call success"];
        self.currentCallId = result.callId;
    }
}

- (void)onEndCall:(NCCallEndCallResult *)result {
    if (result.code != NCCallCodeSuccess) {
        [self showToast:[NSString stringWithFormat:@"End call failed: code %ld", (long)result.code]];
    } else {
        [self showToast:@"End call success"];
    }
}

- (void)onAcceptCall:(NCCallAcceptCallResult *)result {
    if (result.code != NCCallCodeSuccess) {
        [self showToast:[NSString stringWithFormat:@"Accept call failed: code %ld", (long)result.code]];
    } else {
        [self showToast:@"Accept call success"];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.remoteUsersTableView) {
        return self.remoteUsers.count;
    }
    return self.callLogs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.remoteUsersTableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RemoteUserCell" forIndexPath:indexPath];

        // Remove all subviews first
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }

        // Remove cell margins and insets
        cell.layoutMargins = UIEdgeInsetsZero;
        cell.separatorInset = UIEdgeInsetsZero;
        cell.contentView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];

        // Calculate the same size as local video view
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat navBarHeight = 88;
        CGFloat rightWidth = screenWidth * 0.6;  // Right side is 60% of screen
        CGFloat contentHeight = screenHeight - navBarHeight;
        CGFloat videoHeight = contentHeight * 0.3;  // Same as local video height

        // Add remote video view with same size as local video
        NCCallRemoteVideoView *remoteVideoView = [[NCCallRemoteVideoView alloc] initWithFrame:CGRectMake(0, 0, rightWidth, videoHeight)];
        remoteVideoView.userId = self.remoteUsers[indexPath.row];
        remoteVideoView.renderMode = NCCallRenderModeAspectFill;
        remoteVideoView.enableLowResolutionStream = NO;
        remoteVideoView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        remoteVideoView.tag = 1000; // Tag to identify video view
        [cell.contentView addSubview:remoteVideoView];

        // Add user label on top of video
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, rightWidth - 20, 30)];
        label.text = self.remoteUsers[indexPath.row];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        label.layer.cornerRadius = 4;
        label.layer.masksToBounds = YES;
        [cell.contentView addSubview:label];

        return cell;
    } else {
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

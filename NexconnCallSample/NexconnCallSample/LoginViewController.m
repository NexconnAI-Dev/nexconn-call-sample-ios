//
//  LoginViewController.m
//  NexconnCallSample
//

#import "LoginViewController.h"
#import <NexconnChatSDK/NexconnChatSDK-Swift.h>
#import "OneToOneCallViewController.h"
#import "MultiCallViewController.h"

@interface LoginViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UITextField *appKeyTextField;
@property (nonatomic, strong) UITextField *userTokenTextField;
@property (nonatomic, strong) UIButton *connectButton;

// Buttons displayed after successful connection
@property (nonatomic, strong) UIButton *oneToOneCallButton;
@property (nonatomic, strong) UIButton *multiCallButton;

@property (nonatomic, assign) BOOL isConnected;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"NexconnCall Sample";
    self.view.backgroundColor = [UIColor whiteColor];

    self.isConnected = NO;

    [self setupUI];

    // Set default credentials for demo
    self.appKeyTextField.text = @"appKey";
    self.userTokenTextField.text = @"userToken";

    // Add tap gesture to dismiss keyboard
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
}

#pragma mark - Setup UI

- (void)setupUI {
    // ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    // Container View
    self.containerView = [[UIView alloc] init];
    [self.scrollView addSubview:self.containerView];

    CGFloat padding = 20;
    CGFloat fieldHeight = 50;
    CGFloat buttonHeight = 60;
    CGFloat spacing = 15;
    CGFloat yOffset = 150;
    CGFloat width = self.view.bounds.size.width - 2 * padding;

    // AppKey TextField
    self.appKeyTextField = [self createTextFieldWithPlaceholder:@"AppKey"
                                                          frame:CGRectMake(padding, yOffset, width, fieldHeight)];
    [self.containerView addSubview:self.appKeyTextField];
    yOffset += fieldHeight + spacing;

    // User Token TextField
    self.userTokenTextField = [self createTextFieldWithPlaceholder:@"User Token"
                                                             frame:CGRectMake(padding, yOffset, width, fieldHeight)];
    [self.containerView addSubview:self.userTokenTextField];
    yOffset += fieldHeight + spacing * 2;

    // Connect/Disconnect Button
    self.connectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.connectButton.frame = CGRectMake(padding, yOffset, width, fieldHeight);
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.connectButton.backgroundColor = [UIColor systemBlueColor];
    [self.connectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.connectButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.connectButton.layer.cornerRadius = 8;
    [self.connectButton addTarget:self action:@selector(connectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.connectButton];
    yOffset += fieldHeight + spacing * 2;

    // 1v1 Call Button (initially hidden)
    self.oneToOneCallButton = [self createButtonWithTitle:@"1v1 Call"
                                          backgroundColor:[UIColor systemGreenColor]
                                                    frame:CGRectMake(padding, yOffset, width, buttonHeight)];
    [self.oneToOneCallButton addTarget:self action:@selector(oneToOneCallButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.oneToOneCallButton.hidden = YES;
    [self.containerView addSubview:self.oneToOneCallButton];
    yOffset += buttonHeight + spacing;

    // Multi Call Button (initially hidden)
    self.multiCallButton = [self createButtonWithTitle:@"Multi Call"
                                        backgroundColor:[UIColor systemOrangeColor]
                                                  frame:CGRectMake(padding, yOffset, width, buttonHeight)];
    [self.multiCallButton addTarget:self action:@selector(multiCallButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.multiCallButton.hidden = YES;
    [self.containerView addSubview:self.multiCallButton];
    yOffset += buttonHeight + padding;

    // Set container and scrollView size
    self.containerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, yOffset);
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, yOffset);
}

- (UITextField *)createTextFieldWithPlaceholder:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    textField.placeholder = placeholder;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyNext;
    textField.font = [UIFont systemFontOfSize:16];
    return textField;
}

- (UIButton *)createButtonWithTitle:(NSString *)title backgroundColor:(UIColor *)color frame:(CGRect)frame {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = color;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    button.layer.cornerRadius = 10;
    return button;
}

#pragma mark - UI State Management

- (void)showConnectedState {
    // Change Connect button to Disconnect
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    self.connectButton.backgroundColor = [UIColor systemRedColor];
    [self.connectButton removeTarget:self action:@selector(connectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.connectButton addTarget:self action:@selector(disconnectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    // Show call buttons
    self.oneToOneCallButton.hidden = NO;
    self.multiCallButton.hidden = NO;

    // Disable input fields
    self.appKeyTextField.enabled = NO;
    self.userTokenTextField.enabled = NO;

    self.isConnected = YES;
}

- (void)showDisconnectedState {
    // Change Disconnect button back to Connect
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.connectButton.backgroundColor = [UIColor systemBlueColor];
    [self.connectButton removeTarget:self action:@selector(disconnectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.connectButton addTarget:self action:@selector(connectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    // Hide call buttons
    self.oneToOneCallButton.hidden = YES;
    self.multiCallButton.hidden = YES;

    // Enable input fields
    self.appKeyTextField.enabled = YES;
    self.userTokenTextField.enabled = YES;

    self.isConnected = NO;
}

#pragma mark - Button Actions

- (void)connectButtonTapped:(UIButton *)sender {
    [self dismissKeyboard];

    NSString *appKey = self.appKeyTextField.text;
    NSString *userToken = self.userTokenTextField.text;

    if (appKey.length == 0 || userToken.length == 0) {
        [self showAlertWithTitle:@"Error" message:@"Please fill in all fields"];
        return;
    }

    [self showLoadingIndicator];

    // call NexconnCall init
    NCInitParams *initParams = [[NCInitParams alloc] initWithAppKey:appKey];
    initParams.logLevel = NCLogLevelVerbose;
    [NCEngine initializeWithParams:initParams];

    // call NexconnChat connect
    NCConnectParams *connectParams = [[NCConnectParams alloc] initWithToken:userToken];
    [NCEngine connectWithParams:connectParams databaseOpenedHandler:^(BOOL isRecreated, NCError * _Nullable error) {
    } completionHandler:^(NSString * _Nullable userId, NCError * _Nullable error) {
        // Connection completion callback
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideLoadingIndicator];

            if (error == nil && userId != nil) {
                // Connection successful
                [self showConnectedState];
                NSLog(@"Connected successfully with userId: %@", userId);
            } else {
                // Connection failed
                NSString *errorMessage = error ? error.localizedDescription : @"Connection failed";
                [self showAlertWithTitle:@"Connection Failed" message:errorMessage];
                NSLog(@"Connection failed: %@", errorMessage);
            }
        });
    }];
}

- (void)disconnectButtonTapped:(UIButton *)sender {
    // Call NCEngine.disconnect method
    // disablePush: NO means keep push capability after disconnection
    [NCEngine disconnect:NO];

    [self showDisconnectedState];
    NSLog(@"Disconnected");
}

- (void)oneToOneCallButtonTapped:(UIButton *)sender {
    // Navigate to 1v1 call page
    NSLog(@"Navigate to 1v1 Call Page");

    OneToOneCallViewController *vc = [[OneToOneCallViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)multiCallButtonTapped:(UIButton *)sender {
    // Navigate to multi call page
    NSLog(@"Navigate to Multi Call Page");

    MultiCallViewController *vc = [[MultiCallViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Loading Indicator

- (void)showLoadingIndicator {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    indicator.center = self.view.center;
    indicator.tag = 999;
    [indicator startAnimating];
    [self.view addSubview:indicator];

    self.connectButton.enabled = NO;
}

- (void)hideLoadingIndicator {
    UIView *indicator = [self.view viewWithTag:999];
    [indicator removeFromSuperview];

    self.connectButton.enabled = YES;
}

#pragma mark - Helper Methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.appKeyTextField) {
        [self.userTokenTextField becomeFirstResponder];
    } else if (textField == self.userTokenTextField) {
        [self dismissKeyboard];
        if (!self.isConnected) {
            [self connectButtonTapped:self.connectButton];
        }
    }
    return YES;
}

@end

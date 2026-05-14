# Nexconn Call Sample iOS

A comprehensive demonstration application showcasing the capabilities of the Nexconn Call SDK for iOS. Built with Objective-C and UIKit, this sample app demonstrates real-time audio and video calling features with a native iOS architecture.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Permissions](#permissions)
- [Dependencies](#dependencies)
- [Documentation](#documentation)
- [License](#license)

## Features

### Authentication & Connection
- App Key and User Token authentication
- Automatic SDK initialization (Chat + Call)
- Connection state management with visual feedback
- Persistent login state across navigation

### 1-to-1 Calling
- **Audio/Video Calls**: Initiate and receive high-quality audio and video calls
- **Incoming Call Handling**: Accept or decline incoming calls with alert dialog
- **Device Controls**: 
  - Camera enable/disable and switching (front/back)
  - Microphone mute/unmute
  - Speaker/speakerphone toggle
- **Media Type Switching**: Seamlessly switch between audio-only and video calls during active sessions
- **Call History**: View detailed call logs with timestamps and participants

### Group Calling
- **Multi-Participant Calls**: Support for group video/audio conferences
- **Dynamic Participant Management**: 
  - Real-time participant list updates
  - Visual indication of participant status
  - Invite additional users to ongoing calls
- **Invite to Call**: 
  - Invite new users during an active call
  - Dialog-based user input for invitee IDs
  - Automatic participant list updates when invited users join
- **Multi-Video Rendering**: Simultaneous video streams from multiple participants displayed in TableView
- **Flexible Call Controls**: Same device controls available as 1-to-1 calls
- **Optimized Layout**: 
  - Local video view fixed at top (30% of content height)
  - Remote users displayed in scrollable TableView
  - Each remote video matches local video size for consistency

### Device Management
- **Runtime Permissions**: Automatic permission requests for camera and microphone
- **Auto-Enable Devices**: Automatic camera and microphone activation upon call connection
- **Dynamic Video Updates**: Seamless video view updates when participants join/leave

## Requirements

- **Minimum iOS Version**: 13.0
- **Xcode**: 14.0 or later
- **Swift**: 5.0 or later (for SDK compatibility)
- **CocoaPods**: 1.11.0 or later
- **Device**: Physical device required for testing (simulator has limited camera/audio support)
- **Architecture**: arm64 (Apple Silicon and modern iOS devices)

## Project Structure

```
NexconnCallSample/
├── AppDelegate.h/m                    # Application lifecycle
├── SceneDelegate.h/m                  # Scene management (iOS 13+)
├── ViewController.h/m                 # Login screen
├── OneToOneCallViewController.h/m     # 1-to-1 calling implementation
├── MultiCallViewController.h/m        # Group calling implementation
├── Base.lproj/
│   └── LaunchScreen.storyboard       # Launch screen
├── Info.plist                        # App configuration
└── Assets.xcassets/                  # App assets
```

### Key Components

#### View Controllers
- **ViewController**: Login and authentication flow
- **OneToOneCallViewController**: Single participant video/audio calls
- **MultiCallViewController**: Multi-participant conference calls

#### UI Layout (OneToOneCallViewController)
```
┌─────────────────────────────────────────┐
│  Left Controls (40%)  │  Right Video (60%)  │
│                       │                      │
│  - Callee UserId      │  ┌────────────────┐ │
│  - Media Type         │  │  Local Video    │ │
│    (Video / Audio)    │  │  (Top Half)     │ │
│  - Start Call         │  └────────────────┘ │
│  - End Call           │                      │
│  - Enable Camera      │  ┌────────────────┐ │
│  - Switch Camera      │  │  Remote Video   │ │
│  - Disable Microphone │  │  (Bottom Half)  │ │
│  - Enable Speaker     │  └────────────────┘ │
│  - Change To Video    │                      │
├─────────────────────────────────────────┤
│           Call Logs (Bottom 40%)         │
└─────────────────────────────────────────┘
```

#### UI Layout (MultiCallViewController)
```
┌─────────────────────────────────────────┐
│  Left Controls (40%)  │  Right Video (60%)  │
│                       │                      │
│  - Callee UserIds     │  ┌────────────────┐ │
│  - Media Type         │  │  Local Video    │ │
│    (Video / Audio)    │  │  (Top 30%)      │ │
│  - Start Call         │  └────────────────┘ │
│  - End Call           │                      │
│  - Invite to Call     │  Remote Users:       │
│  - Enable Camera      │  ┌────────────────┐ │
│  - Switch Camera      │  │  Remote User 1  │ │
│  - Disable Microphone │  ├────────────────┤ │
│  - Enable Speaker     │  │  Remote User 2  │ │
│                       │  │  (Bottom 30%)   │ │
│                       │  └────────────────┘ │
├─────────────────────────────────────────┤
│           Call Logs (Bottom 40%)         │
└─────────────────────────────────────────┘
```

## Quick Start

### Option 1: Quick Demo Testing (Recommended for First Run)

For quick verification without going through the registration process:

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nexconn-call-sample-ios
   ```

2. **Install dependencies**
   ```bash
   cd NexconnCallSample
   pod install
   ```

3. **Open in Xcode**
   ```bash
   open NexconnCallSample.xcworkspace
   ```

4. **Configure credentials for quick testing**
   - Navigate to: `NexconnCallSample/ViewController.m`
   - Find the `viewDidLoad` method and update the default values:
   
   ```objc
   - (void)viewDidLoad {
       [super viewDidLoad];
       
       // Set default credentials for quick testing
       self.appKeyTextField.text = @"YOUR_APP_KEY";
       self.userTokenTextField.text = @"YOUR_USER_TOKEN";
   }
   ```

5. **Run the application**
   - Select a physical iOS device (simulator not recommended)
   - Click "Run" (⌘R) in Xcode
   - The app will launch with your credentials pre-filled

6. **Test calling features**
   - Tap "Connect" to authenticate
   - Navigate to "1v1 Call" or "Multi Call"
   - Grant camera and microphone permissions when prompted
   - Enter a user ID to call (use another device/account for testing)

### Option 2: Obtain Your Own Credentials

To get your own App Key and User Token:

1. Visit the [Nexconn User Registration Guide](https://docs.nexconn.ai/platform-chat-api/user/register)
2. Follow the registration process to obtain:
   - **App Key**: Your application identifier
   - **User Token**: Authentication token for your user
3. Use these credentials in `ViewController.m` as described above

### Important Security Notes

⚠️ **For Production Use:**
- **Never hardcode credentials** in production builds
- Implement a proper authentication flow with secure token storage
- Use iOS Keychain for sensitive data
- Consider implementing token refresh mechanisms
- Remove default credentials before releasing

## Configuration

### SDK Dependencies

The project uses Nexconn SDKs for calling functionality via CocoaPods:

```ruby
# Podfile
target 'NexconnCallSample' do
  use_frameworks!

  # Nexconn SDKs
  pod 'NexconnCall', '~> 26.2.0'
  pod 'NexconnChatSDK', '~> 26.2.0'
end
```

### Required Permissions

Add these keys to your `Info.plist`:

```xml
<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera for video calls</string>

<!-- Microphone permission -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone for voice and video calls</string>

<!-- Background modes for VoIP -->
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>audio</string>
</array>
```

**Runtime Permissions**: The app automatically requests camera and microphone permissions when needed.

## Architecture

### Design Pattern

The application follows the **MVC (Model-View-Controller)** architecture pattern with UIKit:

- **Model**: Data classes and SDK integration
- **View**: UIKit views and controls (programmatic UI)
- **Controller**: View controllers managing UI and business logic

### Key Components

#### View Controllers
- **State Management**: Using properties and delegate patterns
- **Lifecycle Awareness**: Proper handling of view lifecycle events
- **Event Handling**: SDK event callbacks processed and reflected in UI

#### UI Layer
- **Programmatic UI**: All UI elements created in code (no Storyboards except LaunchScreen)
- **UIKit Components**: Native iOS controls and views
- **Dynamic Updates**: UI updates based on call state changes

#### SDK Initialization Flow

```
1. App Startup
   └─> NCCallEngine.install() (in AppDelegate.didFinishLaunchingWithOptions)

2. User Login
   └─> Chat SDK Initialization (NCEngine.initialize())
   └─> Chat SDK Connection (NCEngine.connect())
   └─> On Success: Call SDK Initialization (NCCallEngine.initialize())

3. Call Screen Entry
   └─> Handler Registration (setCallEventHandler, setAPIResultHandler)
   └─> Permission Requests (camera, microphone)

4. Call Screen Exit
   └─> End active calls
   └─> Disable camera/microphone
   └─> Handler Cleanup
```

### Event Handling

The app uses a delegate-based event system:

```objc
// Event Handler Registration
[[NCCallEngine getInstance] setCallEventHandler:self];

// Implement NCCallEventHandler protocol
- (void)onCallReceived:(NCCallReceivedEvent *)event {
    // Handle incoming call
}

- (void)onCallConnected:(NCCallConnectedEvent *)event {
    // Handle call connection
}

- (void)onCallEnded:(NCCallEndedEvent *)event {
    // Handle call end
}
```

## Permissions

### Required Permissions

| Permission | Purpose | When Requested |
|------------|---------|----------------|
| `NSCameraUsageDescription` | Video calling | On first camera access |
| `NSMicrophoneUsageDescription` | Audio calling | On first microphone access |
| Background Modes (VoIP) | Background call handling | Granted at install |
| Background Modes (Audio) | Audio during background | Granted at install |

### Permission Handling

The app implements comprehensive permission handling:

1. **Automatic Requests**: Permissions requested when accessing camera/microphone
2. **User-Friendly Messages**: Clear descriptions in Info.plist
3. **Graceful Handling**: App continues to function with limited permissions

## Dependencies

### Core iOS Frameworks

```objc
// UIKit for UI
@import UIKit;

// AVFoundation for media
@import AVFoundation;

// Foundation for core functionality
@import Foundation;
```

### Nexconn SDKs

```ruby
# Via CocoaPods
pod 'NexconnCall', '~> 26.2.0'
pod 'NexconnChatSDK', '~> 26.2.0'
```

### Third-Party Dependencies

The Nexconn SDKs include necessary dependencies:
- RongCloudIM (for chat functionality)
- WebRTC (for real-time communication)

## Documentation

### Official Resources

- **Nexconn Platform Documentation**: [https://docs.nexconn.ai/callsdk-ios](https://docs.nexconn.ai/callsdk-ios)
- **User Registration Guide**: [https://docs.nexconn.ai/platform-chat-api/user/register](https://docs.nexconn.ai/platform-chat-api/user/register)
- **API Reference**: [NexconnCall iOS](https://docs.nexconn.ai/apidoc/nexconncall-ios/latest/en_US/)

## Testing

### Testing Checklist

- [ ] Login with valid credentials
- [ ] Navigate between screens (login state persists)
- [ ] Grant camera and microphone permissions
- [ ] Initiate 1-to-1 video call
- [ ] Accept incoming call (alert dialog displays correctly)
- [ ] Toggle camera on/off during call
- [ ] Switch between front/back camera
- [ ] Toggle microphone on/off
- [ ] Toggle speaker on/off
- [ ] Switch from audio to video call
- [ ] End call and verify cleanup
- [ ] Initiate group call with multiple users
- [ ] Verify multi-video rendering in TableView
- [ ] Verify local and remote videos are same size
- [ ] Check remote user leave handling
- [ ] Check call history display

### Known Limitations

- Simulator testing has limited camera/audio functionality
- Physical devices required for full feature testing
- Multiple devices/accounts needed for end-to-end call testing
- iOS 13.0+ required for SceneDelegate support

## Build Configuration

### Debug Build
```bash
xcodebuild -workspace NexconnCallSample.xcworkspace \
           -scheme NexconnCallSample \
           -sdk iphoneos \
           -configuration Debug \
           build
```

### Release Build
```bash
xcodebuild -workspace NexconnCallSample.xcworkspace \
           -scheme NexconnCallSample \
           -sdk iphoneos \
           -configuration Release \
           build
```

## Support

For issues, questions, or feature requests:
- Check the [Nexconn Documentation](https://docs.nexconn.ai/)
- Contact Nexconn support through our official channels

---

**Built with ❤️ using Nexconn Call SDK**

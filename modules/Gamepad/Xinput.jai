#import "Windows";

// Input options:
XINPUT_DYNAMIC_LINK :: 1;
XINPUT_STATIC_LINK_1_4 :: 0;
XINPUT_STATIC_LINK_1_3 :: 0;
XINPUT_STATIC_LINK_9_1 :: 0;



XINPUT_DEVTYPE_GAMEPAD ::          0x01;

//
// Device subtypes available in XINPUT_CAPABILITIES
//

XINPUT_DEVSUBTYPE_GAMEPAD ::           0x01;

XINPUT_DEVSUBTYPE_UNKNOWN ::           0x00;
XINPUT_DEVSUBTYPE_WHEEL ::             0x02;
XINPUT_DEVSUBTYPE_ARCADE_STICK ::      0x03;
XINPUT_DEVSUBTYPE_FLIGHT_STICK ::      0x04;
XINPUT_DEVSUBTYPE_DANCE_PAD ::         0x05;
XINPUT_DEVSUBTYPE_GUITAR ::            0x06;
XINPUT_DEVSUBTYPE_GUITAR_ALTERNATE ::  0x07;
XINPUT_DEVSUBTYPE_DRUM_KIT ::          0x08;
XINPUT_DEVSUBTYPE_GUITAR_BASS ::       0x0B;
XINPUT_DEVSUBTYPE_ARCADE_PAD ::        0x13;

//
// Flags for XINPUT_CAPABILITIES
//

XINPUT_CAPS_VOICE_SUPPORTED ::     0x0004;

XINPUT_CAPS_FFB_SUPPORTED ::       0x0001;
XINPUT_CAPS_WIRELESS ::            0x0002;
XINPUT_CAPS_PMD_SUPPORTED ::       0x0008;
XINPUT_CAPS_NO_NAVIGATION ::       0x0010;

//
// Constants for gamepad buttons
//
XINPUT_GAMEPAD_DPAD_UP ::          0x0001;
XINPUT_GAMEPAD_DPAD_DOWN ::        0x0002;
XINPUT_GAMEPAD_DPAD_LEFT ::        0x0004;
XINPUT_GAMEPAD_DPAD_RIGHT ::       0x0008;
XINPUT_GAMEPAD_START ::            0x0010;
XINPUT_GAMEPAD_BACK ::             0x0020;
XINPUT_GAMEPAD_LEFT_THUMB ::       0x0040;
XINPUT_GAMEPAD_RIGHT_THUMB ::      0x0080;
XINPUT_GAMEPAD_LEFT_SHOULDER ::    0x0100;
XINPUT_GAMEPAD_RIGHT_SHOULDER ::   0x0200;
XINPUT_GAMEPAD_A ::                0x1000;
XINPUT_GAMEPAD_B ::                0x2000;
XINPUT_GAMEPAD_X ::                0x4000;
XINPUT_GAMEPAD_Y ::                0x8000;

//
// Gamepad thresholds
//
XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE ::  7849;
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE :: 8689;
XINPUT_GAMEPAD_TRIGGER_THRESHOLD ::    30;

//
// Flags to pass to XInputGetCapabilities
//
XINPUT_FLAG_GAMEPAD ::             0x00000001;

//
// Devices that support batteries
//
BATTERY_DEVTYPE_GAMEPAD ::         0x00;
BATTERY_DEVTYPE_HEADSET ::         0x01;

//
// Flags for battery status level
//
BATTERY_TYPE_DISCONNECTED ::       0x00;    // This device is not connected
BATTERY_TYPE_WIRED ::              0x01;    // Wired device, no battery
BATTERY_TYPE_ALKALINE ::           0x02;    // Alkaline battery source
BATTERY_TYPE_NIMH ::               0x03;    // Nickel Metal Hydride battery source
BATTERY_TYPE_UNKNOWN ::            0xFF;    // Cannot determine the battery type

// These are only valid for wireless, connected devices, with known battery types
// The amount of use time remaining depends on the type of device.
BATTERY_LEVEL_EMPTY ::             0x00;
BATTERY_LEVEL_LOW ::               0x01;
BATTERY_LEVEL_MEDIUM ::            0x02;
BATTERY_LEVEL_FULL ::              0x03;

// User index definitions
XUSER_MAX_COUNT ::                 4;

XUSER_INDEX_ANY ::                 0x000000FF;

//
// Codes returned for the gamepad keystroke
//

VK_PAD_A ::                        0x5800;
VK_PAD_B ::                        0x5801;
VK_PAD_X ::                        0x5802;
VK_PAD_Y ::                        0x5803;
VK_PAD_RSHOULDER ::                0x5804;
VK_PAD_LSHOULDER ::                0x5805;
VK_PAD_LTRIGGER ::                 0x5806;
VK_PAD_RTRIGGER ::                 0x5807;

VK_PAD_DPAD_UP ::                  0x5810;
VK_PAD_DPAD_DOWN ::                0x5811;
VK_PAD_DPAD_LEFT ::                0x5812;
VK_PAD_DPAD_RIGHT ::               0x5813;
VK_PAD_START ::                    0x5814;
VK_PAD_BACK ::                     0x5815;
VK_PAD_LTHUMB_PRESS ::             0x5816;
VK_PAD_RTHUMB_PRESS ::             0x5817;

VK_PAD_LTHUMB_UP ::                0x5820;
VK_PAD_LTHUMB_DOWN ::              0x5821;
VK_PAD_LTHUMB_RIGHT ::             0x5822;
VK_PAD_LTHUMB_LEFT ::              0x5823;
VK_PAD_LTHUMB_UPLEFT ::            0x5824;
VK_PAD_LTHUMB_UPRIGHT ::           0x5825;
VK_PAD_LTHUMB_DOWNRIGHT ::         0x5826;
VK_PAD_LTHUMB_DOWNLEFT ::          0x5827;

VK_PAD_RTHUMB_UP ::                0x5830;
VK_PAD_RTHUMB_DOWN ::              0x5831;
VK_PAD_RTHUMB_RIGHT ::             0x5832;
VK_PAD_RTHUMB_LEFT ::              0x5833;
VK_PAD_RTHUMB_UPLEFT ::            0x5834;
VK_PAD_RTHUMB_UPRIGHT ::           0x5835;
VK_PAD_RTHUMB_DOWNRIGHT ::         0x5836;
VK_PAD_RTHUMB_DOWNLEFT ::          0x5837;

//
// Flags used in XINPUT_KEYSTROKE
//
XINPUT_KEYSTROKE_KEYDOWN ::        0x0001;
XINPUT_KEYSTROKE_KEYUP ::          0x0002;
XINPUT_KEYSTROKE_REPEAT ::         0x0004;


XINPUT_GAMEPAD :: struct {
    wButtons: u16;
    bLeftTrigger: u8;
    bRightTrigger: u8;
    sThumbLX: s16;
    sThumbLY: s16;
    sThumbRX: s16;
    sThumbRY: s16;
}

XINPUT_STATE :: struct {
    dwPacketNumber: u32;
    Gamepad: XINPUT_GAMEPAD;
}

XINPUT_VIBRATION :: struct {
    wLeftMotorSpeed: u16;
    wRightMotorSpeed: u16;
}

XINPUT_CAPABILITIES :: struct {
    Type: u8;
    SubType: u8;
    Flags: u16;
    Gamepad: XINPUT_GAMEPAD;
    Vibration: XINPUT_VIBRATION;
}

XINPUT_BATTERY_INFORMATION :: struct {
    BatteryType: u8;
    BatteryLevel: u8;
}

XINPUT_KEYSTROKE :: struct {
    VirtualKey: u16;
    Unicode: u16;
    Flags: u16;
    UserIndex: u8;
    HidCode: u8;
}

#if XINPUT_DYNAMIC_LINK {
    XInputGetState : (dwUserIndex: u32, pState: *XINPUT_STATE) -> u32 #c_call;
    XInputSetState : (dwUserIndex: u32, pVibration: *XINPUT_VIBRATION) -> u32 #c_call;
    XInputGetCapabilities : (dwUserIndex: u32, dwFlags: u32, pCapabilities: *XINPUT_CAPABILITIES) -> u32 #c_call;
}
else {
    XInputGetState :: (dwUserIndex: u32, pState: *XINPUT_STATE) -> u32 #foreign Xinput;
    XInputSetState :: (dwUserIndex: u32, pVibration: *XINPUT_VIBRATION) -> u32 #foreign Xinput;
    XInputGetCapabilities :: (dwUserIndex: u32, dwFlags: u32, pCapabilities: *XINPUT_CAPABILITIES) -> u32 #foreign Xinput;
    //XInputEnable :: (enable: BOOL) #foreign Xinput;   // deprecated.

    // These are only in xinput1_4
    #if XINPUT_STATIC_LINK_1_4 {
        XInputGetAudioDeviceIds :: (dwUserIndex: u32, pRenderDeviceId: *u16, pRenderCount: *u32, pCaptureDeviceId: *u16, pCaptureCount: *u32) -> u32 #foreign Xinput;
        XInputGetBatteryInformation :: (dwUserIndex: u32, devType: u8, pBatteryInformation: *XINPUT_BATTERY_INFORMATION) -> u32 #foreign Xinput;
        XInputGetKeystroke :: (dwUserIndex: u32, dwReserved: u32, pKeystroke: *XINPUT_KEYSTROKE) -> u32 #foreign Xinput;
    }
}



init_xinput :: () -> bool {
    // Check if already initialized.
    if XInputGetState != null && XInputSetState != null return true;

    try_1_4 := false; // 1.3 otherwise
    info : OSVERSIONINFOEXW;
    info.dwOSVersionInfoSize = size_of(type_of(info));
    GetVersionExW(*info);

    if info.dwMajorVersion == 6 && info.dwMinorVersion == 2         try_1_4 = true;     // Windows 8
    else if info.dwMajorVersion == 6 && info.dwMinorVersion == 3    try_1_4 = true;     // Windows 8.1
    else if info.dwMajorVersion >= 10                               try_1_4 = true;     // Windows 10 or above

    module : HMODULE;
    if try_1_4 module = LoadLibraryA("xinput1_4.dll");
    if !module module = LoadLibraryA("xinput1_3.dll");
    if !module module = LoadLibraryA("xinput9_1_0.dll");

    if module {
        XInputGetState = xx GetProcAddress(module, "XInputGetState");
        XInputSetState = xx GetProcAddress(module, "XInputSetState");
    }

    have_all := XInputGetState != null && XInputSetState != null;
    if !have_all return false;

    return true;
}

#scope_file

// Win8 and above:
#if XINPUT_STATIC_LINK_1_4  Xinput :: #system_library "xinput1_4";

// Before Win8:
#if XINPUT_STATIC_LINK_1_3  Xinput :: #system_library "xinput1_3";
#if XINPUT_STATIC_LINK_9_1  Xinput :: #system_library "xinput9_1_0";


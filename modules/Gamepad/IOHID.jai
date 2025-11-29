
#import "Basic";

#scope_file

#import "Linux";

kIOReturnSucess :: KERN_SUCCESS;

IOReturn :: kern_return_t;

IOOptionBits :: u32;

IOFixed :: s32;

IOVersion :: u32;

IOItemCount :: u32;

IOCacheMode :: u32;

IOByteCount32 :: u32;

IOByteCount64 :: u64;

IOPhysicalAddress32 :: u32;

IOPhysicalAddress64 :: u64;

IOPhysicalLength32 :: u32;

IOPhysicalLength64 :: u64;

IOVirtualAddress :: mach_vm_address_t;

IOByteCount :: IOByteCount32;

IOLogicalAddress :: IOVirtualAddress;

IOPhysicalAddress :: IOPhysicalAddress32;

IOPhysicalLength :: IOPhysicalLength32;

anon_struct_0 :: struct {
    address: IOPhysicalAddress;
    length: IOByteCount;
}

IOPhysicalRange :: anon_struct_0;

anon_struct_1 :: struct {
    address: IOVirtualAddress;
    length: IOByteCount;
}

IOVirtualRange :: anon_struct_1;

IOAddressRange :: IOVirtualRange;

anon_struct_2 :: struct {
    value: s32;
    name: *s8;
}

IONamedValue :: anon_struct_2;

IOAlignment :: u32;

io_object_t :: mach_port_t;

io_connect_t :: io_object_t;

io_enumerator_t :: io_object_t;

io_iterator_t :: io_object_t;

io_registry_entry_t :: io_object_t;

io_service_t :: io_object_t;

using anon_enum_3 :: enum u32 {
    kIODefaultMemoryType :: 0;
}

using anon_enum_4 :: enum u32 {
    kIODefaultCache :: 0;
    kIOInhibitCache :: 1;
    kIOWriteThruCache :: 2;
    kIOCopybackCache :: 3;
    kIOWriteCombineCache :: 4;
    kIOCopybackInnerCache :: 5;
    kIOPostedWrite :: 6;
}

using anon_enum_5 :: enum u32 {
    kIOMapAnywhere :: 1;
    kIOMapCacheMask :: 1792;
    kIOMapCacheShift :: 8;
    kIOMapDefaultCache :: 0;
    kIOMapInhibitCache :: 256;
    kIOMapWriteThruCache :: 512;
    kIOMapCopybackCache :: 768;
    kIOMapWriteCombineCache :: 1024;
    kIOMapCopybackInnerCache :: 1280;
    kIOMapPostedWrite :: 1536;
    kIOMapUserOptionsMask :: 4095;
    kIOMapReadOnly :: 4096;
    kIOMapStatic :: 16777216;
    kIOMapReference :: 33554432;
    kIOMapUnique :: 67108864;
    kIOMapPrefault :: 268435456;
    kIOMapOverwrite :: 536870912;
}

using anon_enum_6 :: enum u32 {
    kNanosecondScale :: 1;
    kMicrosecondScale :: 1000;
    kMillisecondScale :: 1000000;
    kSecondScale :: 1000000000;
    kTickScale :: 10000000;
}

using anon_enum_7 :: enum s32 {
    kIOConnectMethodVarOutputSize :: -3;
}

IODeviceNumber :: u32;

IOIndex :: s32;

IOSelect :: u32;

IOFixed1616 :: u32;

IODisplayVendorID :: u32;

IODisplayProductID :: u32;

IODisplayModeID :: s32;

using anon_enum_8 :: enum s32 {
    kIODisplayModeIDBootProgrammable :: -5;
    kIODisplayModeIDReservedBase :: -2147483648;
}

using anon_enum_9 :: enum u32 {
    kIOMaxPixelBits :: 64;
}

IOPixelEncoding :: [64] s8;

using anon_enum_10 :: enum u32 {
    kIOCLUTPixels :: 0;
    kIOFixedCLUTPixels :: 1;
    kIORGBDirectPixels :: 2;
    kIOMonoDirectPixels :: 3;
    kIOMonoInverseDirectPixels :: 4;
    kIORGBSignedDirectPixels :: 5;
    kIORGBSignedFloatingPointPixels :: 6;
}

IOPixelInformation :: struct {
    bytesPerRow: u32;
    bytesPerPlane: u32;
    bitsPerPixel: u32;
    pixelType: u32;
    componentCount: u32;
    bitsPerComponent: u32;
    componentMasks: [16] u32;
    pixelFormat: IOPixelEncoding;
    flags: u32;
    activeWidth: u32;
    activeHeight: u32;
    reserved: [2] u32;
}



IOAppleTimingID :: u32;

IODisplayModeInformation :: struct {
    nominalWidth: u32;
    nominalHeight: u32;
    refreshRate: IOFixed1616;
    maxDepthIndex: IOIndex;
    flags: u32;
    imageWidth: u16;
    imageHeight: u16;
    reserved: [3] u32;
}



using anon_enum_11 :: enum u32 {
    kDisplayModeSafetyFlags :: 7;
    kDisplayModeAlwaysShowFlag :: 8;
    kDisplayModeNeverShowFlag :: 128;
    kDisplayModeNotResizeFlag :: 16;
    kDisplayModeRequiresPanFlag :: 32;
    kDisplayModeInterlacedFlag :: 64;
    kDisplayModeSimulscanFlag :: 256;
    kDisplayModeBuiltInFlag :: 1024;
    kDisplayModeNotPresetFlag :: 512;
    kDisplayModeStretchedFlag :: 2048;
    kDisplayModeNotGraphicsQualityFlag :: 4096;
    kDisplayModeValidateAgainstDisplay :: 8192;
    kDisplayModeTelevisionFlag :: 1048576;
    kDisplayModeValidForMirroringFlag :: 2097152;
    kDisplayModeAcceleratorBackedFlag :: 4194304;
    kDisplayModeValidForHiResFlag :: 8388608;
    kDisplayModeValidForAirPlayFlag :: 16777216;
    kDisplayModeNativeFlag :: 33554432;
}

using anon_enum_12 :: enum u32 {
    kDisplayModeValidFlag :: 1;
    kDisplayModeSafeFlag :: 2;
    kDisplayModeDefaultFlag :: 4;
}

IOFramebufferInformation :: struct {
    baseAddress: IOPhysicalAddress;
    activeWidth: u32;
    activeHeight: u32;
    bytesPerRow: IOByteCount;
    bytesPerPlane: IOByteCount;
    bitsPerPixel: u32;
    pixelType: u32;
    flags: u32;
    reserved: [4] u32;
}



using anon_enum_13 :: enum u32 {
    kFramebufferSupportsCopybackCache :: 65536;
    kFramebufferSupportsWritethruCache :: 131072;
    kFramebufferSupportsGammaCorrection :: 262144;
    kFramebufferDisableAltivecAccess :: 524288;
}

IOPixelAperture :: IOIndex;

using anon_enum_14 :: enum u32 {
    kIOFBSystemAperture :: 0;
}

IOColorComponent :: u16;

IOColorEntry :: struct {
    index: u16;
    red: IOColorComponent;
    green: IOColorComponent;
    blue: IOColorComponent;
}



using anon_enum_15 :: enum u32 {
    kSetCLUTByValue :: 1;
    kSetCLUTImmediately :: 2;
    kSetCLUTWithLuminance :: 4;
}

using anon_enum_16 :: enum u32 {
    kIOPowerStateAttribute :: 1886876275;
    kIOPowerAttribute :: 1886353266;
    kIODriverPowerAttribute :: 1685090167;
    kIOHardwareCursorAttribute :: 1668445042;
    kIOMirrorAttribute :: 1835627122;
    kIOMirrorDefaultAttribute :: 1836213350;
    kIOCapturedAttribute :: 1667330148;
    kIOCursorControlAttribute :: 1668445027;
    kIOSystemPowerAttribute :: 1936750450;
    kIOWindowServerActiveAttribute :: 2004054646;
    kIOVRAMSaveAttribute :: 1987212150;
    kIODeferCLUTSetAttribute :: 1986227316;
    kIOClamshellStateAttribute :: 1668047213;
    kIOFBDisplayPortTrainingAttribute :: 1685091425;
    kIOFBDisplayState :: 1685288052;
    kIOFBVariableRefreshRate :: 1987211839;
    kIOFBLimitHDCPAttribute :: 1751409520;
    kIOFBLimitHDCPStateAttribute :: 1934115907;
    kIOFBStop :: 1937010544;
    kIOFBRedGammaScaleAttribute :: 1735617650;
    kIOFBGreenGammaScaleAttribute :: 1735617639;
    kIOFBBlueGammaScaleAttribute :: 1735617634;
    kIOFBHDRMetaDataAttribute :: 1751413357;
}

using anon_enum_17 :: enum u32 {
    kIOFBHDCPLimit_AllowAll :: 0;
    kIOFBHDCPLimit_NoHDCP1x :: 1;
    kIOFBHDCPLimit_NoHDCP20Type0 :: 2;
    kIOFBHDCPLimit_NoHDCP20Type1 :: 4;
}

IOFBHDRMetaDataV1 :: struct {
    displayPrimary_X0: u16;
    displayPrimary_Y0: u16;
    displayPrimary_X1: u16;
    displayPrimary_Y1: u16;
    displayPrimary_X2: u16;
    displayPrimary_Y2: u16;
    displayPrimary_X: u16;
    displayPrimary_Y: u16;
    desiredLuminance_Max: u16;
    desiredLuminance_Min: u16;
    desiredLightLevel_Avg: u16;
    desiredLightLevel_Max: u16;
    __reservedA: [5] u64;
}



anon_struct_18 :: union {
    v1: IOFBHDRMetaDataV1;
}

IOFBHDRMetaData :: anon_struct_18;

using anon_enum_19 :: enum u32 {
    kIOFBDisplayState_AlreadyActive :: 1;
    kIOFBDisplayState_RestoredProfile :: 2;
    kIOFBDisplayState_PipelineBlack :: 4;
    kIOFBDisplayState_Mask :: 7;
}

using anon_enum_20 :: enum u32 {
    kIOWSAA_Unaccelerated :: 0;
    kIOWSAA_Accelerated :: 1;
    kIOWSAA_From_Accelerated :: 2;
    kIOWSAA_To_Accelerated :: 3;
    kIOWSAA_Sleep :: 4;
    kIOWSAA_Hibernate :: 4;
    kIOWSAA_DriverOpen :: 5;
    kIOWSAA_StateMask :: 15;
    kIOWSAA_Transactional :: 16;
    kIOWSAA_DeferStart :: 256;
    kIOWSAA_DeferEnd :: 512;
    kIOWSAA_NonConsoleDevice :: 1024;
    kIOWSAA_Reserved :: 4026531840;
}

using anon_enum_21 :: enum u32 {
    kIOMirrorIsPrimary :: 2147483648;
    kIOMirrorHWClipped :: 1073741824;
    kIOMirrorIsMirrored :: 536870912;
}

using anon_enum_22 :: enum u32 {
    kIOMirrorDefault :: 1;
    kIOMirrorForced :: 2;
}

IODetailedTimingInformationV1 :: struct {
    pixelClock: u32;
    horizontalActive: u32;
    horizontalBlanking: u32;
    horizontalBorder: u32;
    horizontalSyncOffset: u32;
    horizontalSyncWidth: u32;
    verticalActive: u32;
    verticalBlanking: u32;
    verticalBorder: u32;
    verticalSyncOffset: u32;
    verticalSyncWidth: u32;
}



IODetailedTimingInformationV2 :: struct {
    __reservedA: [3] u32;
    horizontalScaledInset: u32;
    verticalScaledInset: u32;
    scalerFlags: u32;
    horizontalScaled: u32;
    verticalScaled: u32;
    signalConfig: u32;
    signalLevels: u32;
    pixelClock: u64;
    minPixelClock: u64;
    maxPixelClock: u64;
    horizontalActive: u32;
    horizontalBlanking: u32;
    horizontalSyncOffset: u32;
    horizontalSyncPulseWidth: u32;
    verticalActive: u32;
    verticalBlanking: u32;
    verticalSyncOffset: u32;
    verticalSyncPulseWidth: u32;
    horizontalBorderLeft: u32;
    horizontalBorderRight: u32;
    verticalBorderTop: u32;
    verticalBorderBottom: u32;
    horizontalSyncConfig: u32;
    horizontalSyncLevel: u32;
    verticalSyncConfig: u32;
    verticalSyncLevel: u32;
    numLinks: u32;
    verticalBlankingExtension: u32;
    pixelEncoding: u16;
    bitsPerColorComponent: u16;
    colorimetry: u16;
    dynamicRange: u16;
    __reservedB: [4] u32;
}



IODetailedTimingInformation :: IODetailedTimingInformationV2;

IOTimingInformation :: struct {
    appleTimingID: IOAppleTimingID;
    flags: u32;
    
    detailedInfo: union {
        v1: IODetailedTimingInformationV1;        v2: IODetailedTimingInformationV2;
    };
}



using anon_enum_24 :: enum u32 {
    kIODetailedTimingValid :: 2147483648;
    kIOScalingInfoValid :: 1073741824;
}

using anon_enum_25 :: enum u32 {
    kIOScaleStretchToFit :: 1;
    kIOScaleRotateFlags :: 240;
    kIOScaleSwapAxes :: 16;
    kIOScaleInvertX :: 32;
    kIOScaleInvertY :: 64;
    kIOScaleRotate0 :: 0;
    kIOScaleRotate90 :: 48;
    kIOScaleRotate180 :: 96;
    kIOScaleRotate270 :: 80;
}

using anon_enum_26 :: enum u32 {
    kIOPixelEncodingNotSupported :: 0;
    kIOPixelEncodingRGB444 :: 1;
    kIOPixelEncodingYCbCr444 :: 2;
    kIOPixelEncodingYCbCr422 :: 4;
    kIOPixelEncodingYCbCr420 :: 8;
}

using anon_enum_27 :: enum u32 {
    kIOBitsPerColorComponentNotSupported :: 0;
    kIOBitsPerColorComponent6 :: 1;
    kIOBitsPerColorComponent8 :: 2;
    kIOBitsPerColorComponent10 :: 4;
    kIOBitsPerColorComponent12 :: 8;
    kIOBitsPerColorComponent16 :: 16;
}

using anon_enum_28 :: enum u32 {
    kIOColorimetryNotSupported :: 0;
    kIOColorimetryNativeRGB :: 1;
    kIOColorimetrysRGB :: 2;
    kIOColorimetryDCIP3 :: 4;
    kIOColorimetryAdobeRGB :: 8;
    kIOColorimetryxvYCC :: 16;
    kIOColorimetryWGRGB :: 32;
    kIOColorimetryBT601 :: 64;
    kIOColorimetryBT709 :: 128;
    kIOColorimetryBT2020 :: 256;
    kIOColorimetryBT2100 :: 512;
}

using anon_enum_29 :: enum u32 {
    kIODynamicRangeNotSupported :: 0;
    kIODynamicRangeSDR :: 1;
    kIODynamicRangeHDR10 :: 2;
    kIODynamicRangeDolbyNormalMode :: 4;
    kIODynamicRangeDolbyTunnelMode :: 8;
    kIODynamicRangeTraditionalGammaHDR :: 16;
}

IOFBDisplayModeDescription :: struct {
    info: IODisplayModeInformation;
    timingInfo: IOTimingInformation;
}



IODisplayTimingRange :: struct {
    __reservedA: [2] u32;
    version: u32;
    __reservedB: [5] u32;
    minPixelClock: u64;
    maxPixelClock: u64;
    maxPixelError: u32;
    supportedSyncFlags: u32;
    supportedSignalLevels: u32;
    supportedSignalConfigs: u32;
    minFrameRate: u32;
    maxFrameRate: u32;
    minLineRate: u32;
    maxLineRate: u32;
    maxHorizontalTotal: u32;
    maxVerticalTotal: u32;
    __reservedD: [2] u32;
    charSizeHorizontalActive: u8;
    charSizeHorizontalBlanking: u8;
    charSizeHorizontalSyncOffset: u8;
    charSizeHorizontalSyncPulse: u8;
    charSizeVerticalActive: u8;
    charSizeVerticalBlanking: u8;
    charSizeVerticalSyncOffset: u8;
    charSizeVerticalSyncPulse: u8;
    charSizeHorizontalBorderLeft: u8;
    charSizeHorizontalBorderRight: u8;
    charSizeVerticalBorderTop: u8;
    charSizeVerticalBorderBottom: u8;
    charSizeHorizontalTotal: u8;
    charSizeVerticalTotal: u8;
    __reservedE: u16;
    minHorizontalActiveClocks: u32;
    maxHorizontalActiveClocks: u32;
    minHorizontalBlankingClocks: u32;
    maxHorizontalBlankingClocks: u32;
    minHorizontalSyncOffsetClocks: u32;
    maxHorizontalSyncOffsetClocks: u32;
    minHorizontalPulseWidthClocks: u32;
    maxHorizontalPulseWidthClocks: u32;
    minVerticalActiveClocks: u32;
    maxVerticalActiveClocks: u32;
    minVerticalBlankingClocks: u32;
    maxVerticalBlankingClocks: u32;
    minVerticalSyncOffsetClocks: u32;
    maxVerticalSyncOffsetClocks: u32;
    minVerticalPulseWidthClocks: u32;
    maxVerticalPulseWidthClocks: u32;
    minHorizontalBorderLeft: u32;
    maxHorizontalBorderLeft: u32;
    minHorizontalBorderRight: u32;
    maxHorizontalBorderRight: u32;
    minVerticalBorderTop: u32;
    maxVerticalBorderTop: u32;
    minVerticalBorderBottom: u32;
    maxVerticalBorderBottom: u32;
    maxNumLinks: u32;
    minLink0PixelClock: u32;
    maxLink0PixelClock: u32;
    minLink1PixelClock: u32;
    maxLink1PixelClock: u32;
    supportedPixelEncoding: u16;
    supportedBitsPerColorComponent: u16;
    supportedColorimetryModes: u16;
    supportedDynamicRangeModes: u16;
    __reservedF: [1] u32;
}



using anon_enum_30 :: enum u32 {
    kIORangePixelEncodingNotSupported :: 0;
    kIORangePixelEncodingRGB444 :: 1;
    kIORangePixelEncodingYCbCr444 :: 2;
    kIORangePixelEncodingYCbCr422 :: 4;
    kIORangePixelEncodingYCbCr420 :: 8;
}

using anon_enum_31 :: enum u32 {
    kIORangeBitsPerColorComponentNotSupported :: 0;
    kIORangeBitsPerColorComponent6 :: 1;
    kIORangeBitsPerColorComponent8 :: 2;
    kIORangeBitsPerColorComponent10 :: 4;
    kIORangeBitsPerColorComponent12 :: 8;
    kIORangeBitsPerColorComponent16 :: 16;
}

using anon_enum_32 :: enum u32 {
    kIORangeColorimetryNotSupported :: 0;
    kIORangeColorimetryNativeRGB :: 1;
    kIORangeColorimetrysRGB :: 2;
    kIORangeColorimetryDCIP3 :: 4;
    kIORangeColorimetryAdobeRGB :: 8;
    kIORangeColorimetryxvYCC :: 16;
    kIORangeColorimetryWGRGB :: 32;
    kIORangeColorimetryBT601 :: 64;
    kIORangeColorimetryBT709 :: 128;
    kIORangeColorimetryBT2020 :: 256;
    kIORangeColorimetryBT2100 :: 512;
}

using anon_enum_33 :: enum u32 {
    kIORangeDynamicRangeNotSupported :: 0;
    kIORangeDynamicRangeSDR :: 1;
    kIORangeDynamicRangeHDR10 :: 2;
    kIORangeDynamicRangeDolbyNormalMode :: 4;
    kIORangeDynamicRangeDolbyTunnelMode :: 8;
    kIORangeDynamicRangeTraditionalGammaHDR :: 16;
}

using anon_enum_34 :: enum u32 {
    kIORangeSupportsSignal_0700_0300 :: 1;
    kIORangeSupportsSignal_0714_0286 :: 2;
    kIORangeSupportsSignal_1000_0400 :: 4;
    kIORangeSupportsSignal_0700_0000 :: 8;
}

using anon_enum_35 :: enum u32 {
    kIORangeSupportsSeparateSyncs :: 1;
    kIORangeSupportsSyncOnGreen :: 2;
    kIORangeSupportsCompositeSync :: 4;
    kIORangeSupportsVSyncSerration :: 8;
}

using anon_enum_36 :: enum u32 {
    kIORangeSupportsInterlacedCEATiming :: 4;
    kIORangeSupportsInterlacedCEATimingWithConfirm :: 8;
}

using anon_enum_37 :: enum u32 {
    kIODigitalSignal :: 1;
    kIOAnalogSetupExpected :: 2;
    kIOInterlacedCEATiming :: 4;
    kIONTSCTiming :: 8;
    kIOPALTiming :: 16;
}

using anon_enum_38 :: enum u32 {
    kIOAnalogSignalLevel_0700_0300 :: 0;
    kIOAnalogSignalLevel_0714_0286 :: 1;
    kIOAnalogSignalLevel_1000_0400 :: 2;
    kIOAnalogSignalLevel_0700_0000 :: 3;
}

using anon_enum_39 :: enum u32 {
    kIOSyncPositivePolarity :: 1;
}

IODisplayScalerInformation :: struct {
    __reservedA: [1] u32;
    version: u32;
    __reservedB: [2] u32;
    scalerFeatures: IOOptionBits;
    maxHorizontalPixels: u32;
    maxVerticalPixels: u32;
    __reservedC: [5] u32;
}



using anon_enum_40 :: enum u32 {
    kIOScaleStretchOnly :: 1;
    kIOScaleCanUpSamplePixels :: 2;
    kIOScaleCanDownSamplePixels :: 4;
    kIOScaleCanScaleInterlaced :: 8;
    kIOScaleCanSupportInset :: 16;
    kIOScaleCanRotate :: 32;
    kIOScaleCanBorderInsetOnly :: 64;
}

using anon_enum_41 :: enum u32 {
    kOrConnections :: 268435454;
    kAndConnections :: 268435453;
}

using anon_enum_42 :: enum u32 {
    kConnectionFlags :: 1718380403;
    kConnectionSyncEnable :: 1937337955;
    kConnectionSyncFlags :: 1937335142;
    kConnectionSupportsAppleSense :: 1634954867;
    kConnectionSupportsLLDDCSense :: 1818518627;
    kConnectionSupportsHLDDCSense :: 1751409763;
    kConnectionEnable :: 1701732706;
    kConnectionCheckEnable :: 1667591777;
    kConnectionProbe :: 1886547810;
    kConnectionChanged :: 1667788391;
    kConnectionPower :: 1886353266;
    kConnectionPostWake :: 1886871915;
    kConnectionDisplayParameterCount :: 1885564532;
    kConnectionDisplayParameters :: 1885434477;
    kConnectionOverscan :: 1869833070;
    kConnectionVideoBest :: 1986163572;
    kConnectionRedGammaScale :: 1919382371;
    kConnectionGreenGammaScale :: 1734832995;
    kConnectionBlueGammaScale :: 1650946915;
    kConnectionGammaScale :: 1735615264;
    kConnectionFlushParameters :: 1718383987;
    kConnectionVBLMultiplier :: 1986161773;
    kConnectionHandleDisplayPortEvent :: 1685088626;
    kConnectionPanelTimingDisable :: 1886284916;
    kConnectionColorMode :: 1668904310;
    kConnectionColorModesSupported :: 1668246642;
    kConnectionColorDepthsSupported :: 543322211;
    kConnectionControllerDepthsSupported :: 6779492;
    kConnectionControllerColorDepth :: 6582372;
    kConnectionControllerDitherControl :: 6775907;
    kConnectionDisplayFlags :: 1684434023;
    kConnectionEnableAudio :: 1635083296;
    kConnectionAudioStreaming :: 1635083379;
}

using anon_enum_43 :: enum u32 {
    kIOConnectionBuiltIn :: 2048;
    kIOConnectionStereoSync :: 32768;
}

using anon_enum_44 :: enum u32 {
    kIOHSyncDisable :: 1;
    kIOVSyncDisable :: 2;
    kIOCSyncDisable :: 4;
    kIONoSeparateSyncControl :: 64;
    kIOTriStateSyncs :: 128;
    kIOSyncOnBlue :: 8;
    kIOSyncOnGreen :: 16;
    kIOSyncOnRed :: 32;
}

using anon_enum_45 :: enum u32 {
    kIODPEventStart :: 1;
    kIODPEventIdle :: 2;
    kIODPEventForceRetrain :: 3;
    kIODPEventRemoteControlCommandPending :: 256;
    kIODPEventAutomatedTestRequest :: 257;
    kIODPEventContentProtection :: 258;
    kIODPEventMCCS :: 259;
    kIODPEventSinkSpecific :: 260;
}

using anon_enum_46 :: enum u32 {
    kIODisplayColorMode :: 1668904310;
}

using anon_enum_47 :: enum u32 {
    kIODisplayRGBColorComponentBitsUnknown :: 0;
    kIODisplayRGBColorComponentBits6 :: 1;
    kIODisplayRGBColorComponentBits8 :: 2;
    kIODisplayRGBColorComponentBits10 :: 4;
    kIODisplayRGBColorComponentBits12 :: 8;
    kIODisplayRGBColorComponentBits14 :: 16;
    kIODisplayRGBColorComponentBits16 :: 32;
    kIODisplayYCbCr444ColorComponentBitsUnknown :: 0;
    kIODisplayYCbCr444ColorComponentBits6 :: 256;
    kIODisplayYCbCr444ColorComponentBits8 :: 512;
    kIODisplayYCbCr444ColorComponentBits10 :: 1024;
    kIODisplayYCbCr444ColorComponentBits12 :: 2048;
    kIODisplayYCbCr444ColorComponentBits14 :: 4096;
    kIODisplayYCbCr444ColorComponentBits16 :: 8192;
    kIODisplayYCbCr422ColorComponentBitsUnknown :: 0;
    kIODisplayYCbCr422ColorComponentBits6 :: 65536;
    kIODisplayYCbCr422ColorComponentBits8 :: 131072;
    kIODisplayYCbCr422ColorComponentBits10 :: 262144;
    kIODisplayYCbCr422ColorComponentBits12 :: 524288;
    kIODisplayYCbCr422ColorComponentBits14 :: 1048576;
    kIODisplayYCbCr422ColorComponentBits16 :: 2097152;
}

using anon_enum_48 :: enum u32 {
    kIODisplayDitherDisable :: 0;
    kIODisplayDitherSpatial :: 1;
    kIODisplayDitherTemporal :: 2;
    kIODisplayDitherFrameRateControl :: 4;
    kIODisplayDitherDefault :: 128;
    kIODisplayDitherAll :: 255;
    kIODisplayDitherRGBShift :: 0;
    kIODisplayDitherYCbCr444Shift :: 8;
    kIODisplayDitherYCbCr422Shift :: 16;
}

using anon_enum_49 :: enum u32 {
    kIODisplayNeedsCEAUnderscan :: 1;
}

using anon_enum_50 :: enum u32 {
    kIODisplayPowerStateOff :: 0;
    kIODisplayPowerStateMinUsable :: 1;
    kIODisplayPowerStateOn :: 2;
}

using anon_enum_51 :: enum u32 {
    kIOFBServerConnectType :: 0;
    kIOFBSharedConnectType :: 1;
    kIOFBDiagnoseConnectType :: 2;
}

using anon_enum_52 :: enum u32 {
    kIOFBUserRequestProbe :: 1;
}

IOGPoint :: struct {
    x: s16;
    y: s16;
}



IOGSize :: struct {
    width: s16;
    height: s16;
}



IOGBounds :: struct {
    minx: s16;
    maxx: s16;
    miny: s16;
    maxy: s16;
}



using anon_enum_53 :: enum u32 {
    kTransparentEncoding :: 0;
    kInvertingEncoding :: 1;
}

using anon_enum_54 :: enum u32 {
    kTransparentEncodingShift :: 0;
    kTransparentEncodedPixel :: 1;
    kInvertingEncodingShift :: 2;
    kInvertingEncodedPixel :: 4;
}

using anon_enum_55 :: enum u32 {
    kHardwareCursorDescriptorMajorVersion :: 1;
    kHardwareCursorDescriptorMinorVersion :: 0;
}

IOHardwareCursorDescriptor :: struct {
    majorVersion: u16;
    minorVersion: u16;
    height: u32;
    width: u32;
    bitDepth: u32;
    maskBitDepth: u32;
    numColors: u32;
    colorEncodings: *u32;
    flags: u32;
    supportedSpecialEncodings: u32;
    specialEncodings: [16] u32;
}



using anon_enum_56 :: enum u32 {
    kHardwareCursorInfoMajorVersion :: 1;
    kHardwareCursorInfoMinorVersion :: 0;
}

IOHardwareCursorInfo :: struct {
    majorVersion: u16;
    minorVersion: u16;
    cursorHeight: u32;
    cursorWidth: u32;
    colorMap: *IOColorEntry;
    hardwareCursorData: *u8;
    cursorHotSpotX: u16;
    cursorHotSpotY: u16;
    reserved: [5] u32;
}



using anon_enum_57 :: enum u32 {
    kIOFBVBLInterruptType :: 1986161696;
    kIOFBHBLInterruptType :: 1751280672;
    kIOFBFrameInterruptType :: 1718772077;
    kIOFBConnectInterruptType :: 1684236576;
    kIOFBChangedInterruptType :: 1667788391;
    kIOFBOfflineInterruptType :: 1919249782;
    kIOFBOnlineInterruptType :: 1633969184;
    kIOFBDisplayPortInterruptType :: 1685088626;
    kIOFBDisplayPortLinkChangeInterruptType :: 1685089387;
    kIOFBMCCSInterruptType :: 1835230067;
    kIOFBWakeInterruptType :: 1987535211;
}

using anon_enum_58 :: enum u32 {
    kIOTimingIDInvalid :: 0;
    kIOTimingIDApple_FixedRateLCD :: 42;
    kIOTimingIDApple_512x384_60hz :: 130;
    kIOTimingIDApple_560x384_60hz :: 135;
    kIOTimingIDApple_640x480_67hz :: 140;
    kIOTimingIDApple_640x400_67hz :: 145;
    kIOTimingIDVESA_640x480_60hz :: 150;
    kIOTimingIDVESA_640x480_72hz :: 152;
    kIOTimingIDVESA_640x480_75hz :: 154;
    kIOTimingIDVESA_640x480_85hz :: 158;
    kIOTimingIDGTF_640x480_120hz :: 159;
    kIOTimingIDApple_640x870_75hz :: 160;
    kIOTimingIDApple_640x818_75hz :: 165;
    kIOTimingIDApple_832x624_75hz :: 170;
    kIOTimingIDVESA_800x600_56hz :: 180;
    kIOTimingIDVESA_800x600_60hz :: 182;
    kIOTimingIDVESA_800x600_72hz :: 184;
    kIOTimingIDVESA_800x600_75hz :: 186;
    kIOTimingIDVESA_800x600_85hz :: 188;
    kIOTimingIDVESA_1024x768_60hz :: 190;
    kIOTimingIDVESA_1024x768_70hz :: 200;
    kIOTimingIDVESA_1024x768_75hz :: 204;
    kIOTimingIDVESA_1024x768_85hz :: 208;
    kIOTimingIDApple_1024x768_75hz :: 210;
    kIOTimingIDVESA_1152x864_75hz :: 215;
    kIOTimingIDApple_1152x870_75hz :: 220;
    kIOTimingIDAppleNTSC_ST :: 230;
    kIOTimingIDAppleNTSC_FF :: 232;
    kIOTimingIDAppleNTSC_STconv :: 234;
    kIOTimingIDAppleNTSC_FFconv :: 236;
    kIOTimingIDApplePAL_ST :: 238;
    kIOTimingIDApplePAL_FF :: 240;
    kIOTimingIDApplePAL_STconv :: 242;
    kIOTimingIDApplePAL_FFconv :: 244;
    kIOTimingIDVESA_1280x960_75hz :: 250;
    kIOTimingIDVESA_1280x960_60hz :: 252;
    kIOTimingIDVESA_1280x960_85hz :: 254;
    kIOTimingIDVESA_1280x1024_60hz :: 260;
    kIOTimingIDVESA_1280x1024_75hz :: 262;
    kIOTimingIDVESA_1280x1024_85hz :: 268;
    kIOTimingIDVESA_1600x1200_60hz :: 280;
    kIOTimingIDVESA_1600x1200_65hz :: 282;
    kIOTimingIDVESA_1600x1200_70hz :: 284;
    kIOTimingIDVESA_1600x1200_75hz :: 286;
    kIOTimingIDVESA_1600x1200_80hz :: 288;
    kIOTimingIDVESA_1600x1200_85hz :: 289;
    kIOTimingIDVESA_1792x1344_60hz :: 296;
    kIOTimingIDVESA_1792x1344_75hz :: 298;
    kIOTimingIDVESA_1856x1392_60hz :: 300;
    kIOTimingIDVESA_1856x1392_75hz :: 302;
    kIOTimingIDVESA_1920x1440_60hz :: 304;
    kIOTimingIDVESA_1920x1440_75hz :: 306;
    kIOTimingIDSMPTE240M_60hz :: 400;
    kIOTimingIDFilmRate_48hz :: 410;
    kIOTimingIDSony_1600x1024_76hz :: 500;
    kIOTimingIDSony_1920x1080_60hz :: 510;
    kIOTimingIDSony_1920x1080_72hz :: 520;
    kIOTimingIDSony_1920x1200_76hz :: 540;
    kIOTimingIDApple_0x0_0hz_Offline :: 550;
    kIOTimingIDVESA_848x480_60hz :: 570;
    kIOTimingIDVESA_1360x768_60hz :: 590;
}

using anon_enum_59 :: enum u32 {
    kIOHibernatePreviewActive :: 1;
    kIOHibernatePreviewUpdates :: 2;
}

using anon_enum_60 :: enum u32 {
    kIOFBAVSignalTypeUnknown :: 0;
    kIOFBAVSignalTypeVGA :: 1;
    kIOFBAVSignalTypeDVI :: 2;
    kIOFBAVSignalTypeHDMI :: 8;
    kIOFBAVSignalTypeDP :: 16;
}

IOFBDPLinkConfig :: struct {
    version: u16;
    bitRate: u8;
    __reservedA: [1] u8;
    t1Time: u16;
    t2Time: u16;
    t3Time: u16;
    idlePatterns: u8;
    laneCount: u8;
    voltage: u8;
    preEmphasis: u8;
    downspread: u8;
    scrambler: u8;
    maxBitRate: u8;
    maxLaneCount: u8;
    maxDownspread: u8;
    __reservedB: [9] u8;
}



using anon_enum_61 :: enum u32 {
    kIOFBBitRateRBR :: 6;
    kIOFBBitRateHBR :: 10;
    kIOFBBitRateHBR2 :: 20;
}

using anon_enum_62 :: enum u32 {
    kIOFBLinkVoltageLevel0 :: 0;
    kIOFBLinkVoltageLevel1 :: 1;
    kIOFBLinkVoltageLevel2 :: 2;
    kIOFBLinkVoltageLevel3 :: 3;
}

using anon_enum_63 :: enum u32 {
    kIOFBLinkPreEmphasisLevel0 :: 0;
    kIOFBLinkPreEmphasisLevel1 :: 1;
    kIOFBLinkPreEmphasisLevel2 :: 2;
    kIOFBLinkPreEmphasisLevel3 :: 3;
}

using anon_enum_64 :: enum u32 {
    kIOFBLinkDownspreadNone :: 0;
    kIOFBLinkDownspreadMax :: 1;
}

using anon_enum_65 :: enum u32 {
    kIOFBLinkScramblerNormal :: 0;
    kIOFBLinkScramblerAlternate :: 1;
}

using anon_enum_66 :: enum u32 {
    kDisplayVendorIDUnknown :: 1970170734;
    kDisplayProductIDGeneric :: 1815;
}

using anon_enum_67 :: enum u32 {
    kDisplaySubPixelLayoutUndefined :: 0;
    kDisplaySubPixelLayoutRGB :: 1;
    kDisplaySubPixelLayoutBGR :: 2;
    kDisplaySubPixelLayoutQuadGBL :: 3;
    kDisplaySubPixelLayoutQuadGBR :: 4;
    kDisplaySubPixelConfigurationUndefined :: 0;
    kDisplaySubPixelConfigurationDelta :: 1;
    kDisplaySubPixelConfigurationStripe :: 2;
    kDisplaySubPixelConfigurationStripeOffset :: 3;
    kDisplaySubPixelConfigurationQuad :: 4;
    kDisplaySubPixelShapeUndefined :: 0;
    kDisplaySubPixelShapeRound :: 1;
    kDisplaySubPixelShapeSquare :: 2;
    kDisplaySubPixelShapeRectangular :: 3;
    kDisplaySubPixelShapeOval :: 4;
    kDisplaySubPixelShapeElliptical :: 5;
}

evsioKeymapping :: struct {
    size: s32;
    mapping: *s8;
}

NXKeyMapping :: evsioKeymapping;

evsioMouseScaling :: struct {
    numScaleLevels: s32;
    scaleThresholds: [20] s16;
    scaleFactors: [20] s16;
}

NXMouseScaling :: evsioMouseScaling;

using anon_enum_68 :: enum u32 {
    NX_OneButton :: 0;
    NX_LeftButton :: 1;
    NX_RightButton :: 2;
}

NXMouseButton :: anon_enum_68;

__IOFixedPoint32 :: struct {
    x: s32;
    y: s32;
}

IOFixedPoint32 :: __IOFixedPoint32;

NXEventSystemInfoType :: *s32;

NXEventSystemInfoData :: [1024] s32;

anon_struct_69 :: struct {
    interface: s32;
    interface_addr: s32;
    dev_type: s32;
    id: s32;
}

NXEventSystemDevice :: anon_struct_69;

anon_struct_70 :: struct {
    dev: [16] NXEventSystemDevice;
}

NXEventSystemDeviceList :: anon_struct_70;

using anon_enum_71 :: enum u32 {
    EVNOP :: 0;
    EVHIDE :: 1;
    EVSHOW :: 2;
    EVMOVE :: 3;
    EVLEVEL :: 4;
}

EvCmd :: anon_enum_71;

NXCoord :: float32;

_NXPoint :: struct {
    x: NXCoord;
    y: NXCoord;
}

NXPoint :: _NXPoint;

_NXSize :: struct {
    width: NXCoord;
    height: NXCoord;
}

NXSize :: _NXSize;

_NXTabletPointData :: struct {
    x: s32;
    y: s32;
    z: s32;
    buttons: u16;
    pressure: u16;
    
    tilt: struct {
        x: s16;        y: s16;
    };
    rotation: u16;
    tangentialPressure: s16;
    deviceID: u16;
    vendor1: s16;
    vendor2: s16;
    vendor3: s16;
}

NXTabletPointData :: _NXTabletPointData;

NXTabletPointDataPtr :: *_NXTabletPointData;

_NXTabletProximityData :: struct {
    vendorID: u16;
    tabletID: u16;
    pointerID: u16;
    deviceID: u16;
    systemTabletID: u16;
    vendorPointerType: u16;
    pointerSerialNumber: u32;
    uniqueID: u64;
    capabilityMask: u32;
    pointerType: u8;
    enterProximity: u8;
    reserved1: s16;
}

NXTabletProximityData :: _NXTabletProximityData;

NXTabletProximityDataPtr :: *_NXTabletProximityData;

anon_struct_73 :: union {
    
    mouse: struct {
        subx: u8;        suby: u8;        eventNum: s16;        click: s32;        pressure: u8;        buttonNumber: u8;        subType: u8;        reserved2: u8;        reserved3: s32;                tablet: union {
            point: NXTabletPointData;            proximity: NXTabletProximityData;
        };
    };
    
    mouseMove: struct {
        dx: s32;        dy: s32;        subx: u8;        suby: u8;        subType: u8;        reserved1: u8;        reserved2: s32;                tablet: union {
            point: NXTabletPointData;            proximity: NXTabletProximityData;
        };
    };
    
    key: struct {
        origCharSet: u16;        repeat: s16;        charSet: u16;        charCode: u16;        keyCode: u16;        origCharCode: u16;        reserved1: s32;        keyboardType: u32;        reserved2: s32;        reserved3: s32;        reserved4: s32;        reserved5: [4] s32;
    };
    
    tracking: struct {
        reserved: s16;        eventNum: s16;        trackingNum: s32;        userData: s32;        reserved1: s32;        reserved2: s32;        reserved3: s32;        reserved4: s32;        reserved5: s32;        reserved6: [4] s32;
    };
    
    scrollWheel: struct {
        deltaAxis1: s16;        deltaAxis2: s16;        deltaAxis3: s16;        reserved1: s16;        fixedDeltaAxis1: s32;        fixedDeltaAxis2: s32;        fixedDeltaAxis3: s32;        pointDeltaAxis1: s32;        pointDeltaAxis2: s32;        pointDeltaAxis3: s32;        reserved8: [4] s32;
    };
    zoom: struct {
        deltaAxis1: s16;        deltaAxis2: s16;        deltaAxis3: s16;        reserved1: s16;        fixedDeltaAxis1: s32;        fixedDeltaAxis2: s32;        fixedDeltaAxis3: s32;        pointDeltaAxis1: s32;        pointDeltaAxis2: s32;        pointDeltaAxis3: s32;        reserved8: [4] s32;
    };
    
    compound: struct {
        reserved: s16;        subType: s16;                misc: union {
            F: [11] float32;            L: [11] s32;            S: [22] s16;            C: [44] s8;
        };
    };
    
    tablet: struct {
        x: s32;        y: s32;        z: s32;        buttons: u16;        pressure: u16;                tilt: struct {
            x: s16;            y: s16;
        };        rotation: u16;        tangentialPressure: s16;        deviceID: u16;        vendor1: s16;        vendor2: s16;        vendor3: s16;        reserved: [4] s32;
    };
    
    proximity: struct {
        vendorID: u16;        tabletID: u16;        pointerID: u16;        deviceID: u16;        systemTabletID: u16;        vendorPointerType: u16;        pointerSerialNumber: u32;        uniqueID: u64;        capabilityMask: u32;        pointerType: u8;        enterProximity: u8;        reserved1: s16;        reserved2: [4] s32;
    };
}

NXEventData :: anon_struct_73;

_NXEvent :: struct {
    type: s32;
    
    location: struct {
        x: s32;        y: s32;
    };
    time: u64;
    flags: s32;
    window: u32;
    service_id: u64;
    ext_pid: s32;
    data: NXEventData;
}

NXEvent :: _NXEvent;

NXEventPtr :: *_NXEvent;

_NXEventExtension :: struct {
    flags: u32;
}

NXEventExtension :: _NXEventExtension;

_NXEventExt :: struct {
    payload: NXEvent;
    extension: NXEventExtension;
}

NXEventExt :: _NXEventExt;

using anon_enum_87 :: enum u32 {
    kIOHIDButtonMode_BothLeftClicks :: 0;
    kIOHIDButtonMode_ReverseLeftRightClicks :: 1;
    kIOHIDButtonMode_EnableRightClick :: 2;
}

IOHIDButtonModes :: anon_enum_87;

using anon_enum_88 :: enum u32 {
    EVSIOSCS_X :: 0;
    EVSIOSCS_Y :: 1;
}

evsioEVSIOSCSIndices :: anon_enum_88;

using anon_enum_89 :: enum u32 {
    EVSIOCCS_X :: 0;
    EVSIOCCS_Y :: 1;
}

evsioEVSIOCCSIndices :: anon_enum_89;

using anon_enum_90 :: enum u32 {
    kIOHIDCapsLockState :: 1;
    kIOHIDNumLockState :: 2;
    kIOHIDActivityUserIdle :: 3;
    kIOHIDActivityDisplayOn :: 4;
}

IOMessage :: u32;

IOHIDElementCookie :: u32;

using IOHIDElementType :: enum u32 {
    kIOHIDElementTypeInput_Misc :: 1;
    kIOHIDElementTypeInput_Button :: 2;
    kIOHIDElementTypeInput_Axis :: 3;
    kIOHIDElementTypeInput_ScanCodes :: 4;
    kIOHIDElementTypeOutput :: 129;
    kIOHIDElementTypeFeature :: 257;
    kIOHIDElementTypeCollection :: 513;
}



using IOHIDElementCollectionType :: enum u32 {
    kIOHIDElementCollectionTypePhysical :: 0;
    kIOHIDElementCollectionTypeApplication :: 1;
    kIOHIDElementCollectionTypeLogical :: 2;
    kIOHIDElementCollectionTypeReport :: 3;
    kIOHIDElementCollectionTypeNamedArray :: 4;
    kIOHIDElementCollectionTypeUsageSwitch :: 5;
    kIOHIDElementCollectionTypeUsageModifier :: 6;
}



using IOHIDReportType :: enum u32 {
    kIOHIDReportTypeInput :: 0;
    kIOHIDReportTypeOutput :: 1;
    kIOHIDReportTypeFeature :: 2;
    kIOHIDReportTypeCount :: 3;
}

kIOHIDOptionsTypeNone :: 0;
kIOHIDOptionsTypeSeizeDevice :: 1;

IOHIDOptionsType :: u32;

using anon_enum_92 :: enum u32 {
    kIOHIDQueueOptionsTypeNone :: 0;
    kIOHIDQueueOptionsTypeEnqueueAll :: 1;
}

IOHIDQueueOptionsType :: u32;

using anon_enum_93 :: enum u32 {
    kIOHIDElementFlagsConstantMask :: 1;
    kIOHIDElementFlagsVariableMask :: 2;
    kIOHIDElementFlagsRelativeMask :: 4;
    kIOHIDElementFlagsWrapMask :: 8;
    kIOHIDElementFlagsNonLinearMask :: 16;
    kIOHIDElementFlagsNoPreferredMask :: 32;
    kIOHIDElementFlagsNullStateMask :: 64;
    kIOHIDElementFlagsVolativeMask :: 128;
    kIOHIDElementFlagsBufferedByteMask :: 256;
}

IOHIDElementFlags :: u32;

using anon_enum_94 :: enum u32 {
    kIOHIDStandardTypeANSI :: 0;
    kIOHIDStandardTypeISO :: 1;
    kIOHIDStandardTypeJIS :: 2;
}

IOHIDStandardType :: u32;

using anon_enum_95 :: enum u32 {
    kIOHIDValueScaleTypeCalibrated :: 0;
    kIOHIDValueScaleTypePhysical :: 1;
    kIOHIDValueScaleTypeExponent :: 2;
}

IOHIDValueScaleType :: u32;

using anon_enum_96 :: enum u32 {
    kIOHIDValueOptionsFlagRelativeSimple :: 1;
    kIOHIDValueOptionsFlagPrevious :: 2;
    kIOHIDValueOptionsUpdateElementValues :: 4;
}

IOHIDValueOptions :: u32;

__IOHIDDevice :: struct {
}

IOHIDDeviceRef :: *__IOHIDDevice;

__IOHIDElement :: struct {
}

IOHIDElementRef :: *__IOHIDElement;

__IOHIDValue :: struct {
}

IOHIDValueRef :: *__IOHIDValue;

using IOHIDTransactionDirectionType :: enum u32 {
    kIOHIDTransactionDirectionTypeInput :: 0;
    kIOHIDTransactionDirectionTypeOutput :: 1;
}



kIOHIDTransactionOptionDefaultOutputValue: IOOptionBits;

IOHIDCallback :: #type (a0: *void, a1: IOReturn, a2: *void) -> void #c_call;

IOHIDReportCallback :: #type (a0: *void, a1: IOReturn, a2: *void, a3: IOHIDReportType, a4: u32, a5: *u8, a6: CFIndex) -> void #c_call;

IOHIDReportWithTimeStampCallback :: #type (a0: *void, a1: IOReturn, a2: *void, a3: IOHIDReportType, a4: u32, a5: *u8, a6: CFIndex, a7: u64) -> void #c_call;

IOHIDValueCallback :: #type (a0: *void, a1: IOReturn, a2: *void, a3: IOHIDValueRef) -> void #c_call;

IOHIDValueMultipleCallback :: #type (a0: *void, a1: IOReturn, a2: *void, a3: CFDictionaryRef) -> void #c_call;

IOHIDDeviceCallback :: #type (a0: *void, a1: IOReturn, a2: *void, a3: IOHIDDeviceRef) -> void #c_call;

IOHIDDeviceGetTypeID :: () -> CFTypeID #foreign IOKit;

IOHIDDeviceCreate :: (allocator: CFAllocatorRef, service: io_service_t) -> IOHIDDeviceRef #foreign IOKit;

IOHIDDeviceGetService :: (device: IOHIDDeviceRef) -> io_service_t #foreign IOKit;

IOHIDDeviceOpen :: (device: IOHIDDeviceRef, options: IOOptionBits) -> IOReturn #foreign IOKit;

IOHIDDeviceClose :: (device: IOHIDDeviceRef, options: IOOptionBits) -> IOReturn #foreign IOKit;

IOHIDDeviceConformsTo :: (device: IOHIDDeviceRef, usagePage: u32, usage: u32) -> Boolean #foreign IOKit;

IOHIDDeviceGetProperty :: (device: IOHIDDeviceRef, key: CFStringRef) -> CFTypeRef #foreign IOKit;

IOHIDDeviceSetProperty :: (device: IOHIDDeviceRef, key: CFStringRef, property: CFTypeRef) -> Boolean #foreign IOKit;

IOHIDDeviceCopyMatchingElements :: (device: IOHIDDeviceRef, matching: CFDictionaryRef, options: IOOptionBits) -> CFArrayRef #foreign IOKit;

IOHIDDeviceScheduleWithRunLoop :: (device: IOHIDDeviceRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDDeviceUnscheduleFromRunLoop :: (device: IOHIDDeviceRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDDeviceRegisterRemovalCallback :: (device: IOHIDDeviceRef, callback: IOHIDCallback, _context: *void) -> void #foreign IOKit;

IOHIDDeviceRegisterInputValueCallback :: (device: IOHIDDeviceRef, callback: IOHIDValueCallback, _context: *void) -> void #foreign IOKit;

IOHIDDeviceRegisterInputReportCallback :: (device: IOHIDDeviceRef, report: *u8, reportLength: CFIndex, callback: IOHIDReportCallback, _context: *void) -> void #foreign IOKit;

IOHIDDeviceRegisterInputReportWithTimeStampCallback :: (device: IOHIDDeviceRef, report: *u8, reportLength: CFIndex, callback: IOHIDReportWithTimeStampCallback, _context: *void) -> void #foreign IOKit;

IOHIDDeviceSetInputValueMatching :: (device: IOHIDDeviceRef, matching: CFDictionaryRef) -> void #foreign IOKit;

IOHIDDeviceSetInputValueMatchingMultiple :: (device: IOHIDDeviceRef, multiple: CFArrayRef) -> void #foreign IOKit;

IOHIDDeviceSetValue :: (device: IOHIDDeviceRef, element: IOHIDElementRef, value: IOHIDValueRef) -> IOReturn #foreign IOKit;

IOHIDDeviceSetValueMultiple :: (device: IOHIDDeviceRef, multiple: CFDictionaryRef) -> IOReturn #foreign IOKit;

IOHIDDeviceSetValueWithCallback :: (device: IOHIDDeviceRef, element: IOHIDElementRef, value: IOHIDValueRef, timeout: CFTimeInterval, callback: IOHIDValueCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDDeviceSetValueMultipleWithCallback :: (device: IOHIDDeviceRef, multiple: CFDictionaryRef, timeout: CFTimeInterval, callback: IOHIDValueMultipleCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDDeviceGetValue :: (device: IOHIDDeviceRef, element: IOHIDElementRef, pValue: *IOHIDValueRef) -> IOReturn #foreign IOKit;

using IOHIDDeviceGetValueOptions :: enum u32 {
    kIOHIDDeviceGetValueWithUpdate :: 131072;
    kIOHIDDeviceGetValueWithoutUpdate :: 262144;
}



IOHIDDeviceGetValueWithOptions :: (device: IOHIDDeviceRef, element: IOHIDElementRef, pValue: *IOHIDValueRef, options: u32) -> IOReturn #foreign IOKit;

IOHIDDeviceCopyValueMultiple :: (device: IOHIDDeviceRef, elements: CFArrayRef, pMultiple: *CFDictionaryRef) -> IOReturn #foreign IOKit;

IOHIDDeviceGetValueWithCallback :: (device: IOHIDDeviceRef, element: IOHIDElementRef, pValue: *IOHIDValueRef, timeout: CFTimeInterval, callback: IOHIDValueCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDDeviceCopyValueMultipleWithCallback :: (device: IOHIDDeviceRef, elements: CFArrayRef, pMultiple: *CFDictionaryRef, timeout: CFTimeInterval, callback: IOHIDValueMultipleCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDDeviceSetReport :: (device: IOHIDDeviceRef, reportType: IOHIDReportType, reportID: CFIndex, report: *u8, reportLength: CFIndex) -> IOReturn #foreign IOKit;

IOHIDDeviceSetReportWithCallback :: (device: IOHIDDeviceRef, reportType: IOHIDReportType, reportID: CFIndex, report: *u8, reportLength: CFIndex, timeout: CFTimeInterval, callback: IOHIDReportCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDDeviceGetReport :: (device: IOHIDDeviceRef, reportType: IOHIDReportType, reportID: CFIndex, report: *u8, pReportLength: *CFIndex) -> IOReturn #foreign IOKit;

IOHIDDeviceGetReportWithCallback :: (device: IOHIDDeviceRef, reportType: IOHIDReportType, reportID: CFIndex, report: *u8, pReportLength: *CFIndex, timeout: CFTimeInterval, callback: IOHIDReportCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDElementGetTypeID :: () -> CFTypeID #foreign IOKit;

IOHIDElementCreateWithDictionary :: (allocator: CFAllocatorRef, dictionary: CFDictionaryRef) -> IOHIDElementRef #foreign IOKit;

IOHIDElementGetDevice :: (element: IOHIDElementRef) -> IOHIDDeviceRef #foreign IOKit;

IOHIDElementGetParent :: (element: IOHIDElementRef) -> IOHIDElementRef #foreign IOKit;

IOHIDElementGetChildren :: (element: IOHIDElementRef) -> CFArrayRef #foreign IOKit;

IOHIDElementAttach :: (element: IOHIDElementRef, toAttach: IOHIDElementRef) -> void #foreign IOKit;

IOHIDElementDetach :: (element: IOHIDElementRef, toDetach: IOHIDElementRef) -> void #foreign IOKit;

IOHIDElementCopyAttached :: (element: IOHIDElementRef) -> CFArrayRef #foreign IOKit;

IOHIDElementGetCookie :: (element: IOHIDElementRef) -> IOHIDElementCookie #foreign IOKit;

IOHIDElementGetType :: (element: IOHIDElementRef) -> IOHIDElementType #foreign IOKit;

IOHIDElementGetCollectionType :: (element: IOHIDElementRef) -> IOHIDElementCollectionType #foreign IOKit;

IOHIDElementGetUsagePage :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementGetUsage :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementIsVirtual :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementIsRelative :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementIsWrapping :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementIsArray :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementIsNonLinear :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementHasPreferredState :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementHasNullState :: (element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDElementGetName :: (element: IOHIDElementRef) -> CFStringRef #foreign IOKit;

IOHIDElementGetReportID :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementGetReportSize :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementGetReportCount :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementGetUnit :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementGetUnitExponent :: (element: IOHIDElementRef) -> u32 #foreign IOKit;

IOHIDElementGetLogicalMin :: (element: IOHIDElementRef) -> CFIndex #foreign IOKit;

IOHIDElementGetLogicalMax :: (element: IOHIDElementRef) -> CFIndex #foreign IOKit;

IOHIDElementGetPhysicalMin :: (element: IOHIDElementRef) -> CFIndex #foreign IOKit;

IOHIDElementGetPhysicalMax :: (element: IOHIDElementRef) -> CFIndex #foreign IOKit;

IOHIDElementGetProperty :: (element: IOHIDElementRef, key: CFStringRef) -> CFTypeRef #foreign IOKit;

IOHIDElementSetProperty :: (element: IOHIDElementRef, key: CFStringRef, property: CFTypeRef) -> Boolean #foreign IOKit;

IOHIDEventStruct :: struct {
    type: IOHIDElementType;
    elementCookie: IOHIDElementCookie;
    value: s32;
    timestamp: AbsoluteTime;
    longValueSize: u32;
    longValue: *void;
}



IOHIDCallbackFunction :: #type (a0: *void, a1: IOReturn, a2: *void, a3: *void) -> void #c_call;

IOHIDElementCallbackFunction :: #type (a0: *void, a1: IOReturn, a2: *void, a3: *void, a4: IOHIDElementCookie) -> void #c_call;

IOHIDReportCallbackFunction :: #type (a0: *void, a1: IOReturn, a2: *void, a3: *void, a4: u32) -> void #c_call;





IOHIDDeviceInterface :: struct {
    _reserved: *void;
    QueryInterface: #type (a0: *void, a1: REFIID, a2: *LPVOID) -> HRESULT #c_call;
    AddRef: #type (a0: *void) -> ULONG #c_call;
    Release: #type (a0: *void) -> ULONG #c_call;
    createAsyncEventSource: #type (a0: *void, a1: *CFRunLoopSourceRef) -> IOReturn #c_call;
    getAsyncEventSource: #type (a0: *void) -> CFRunLoopSourceRef #c_call;
    createAsyncPort: #type (a0: *void, a1: *mach_port_t) -> IOReturn #c_call;
    getAsyncPort: #type (a0: *void) -> mach_port_t #c_call;
    open: #type (a0: *void, a1: IOOptionBits) -> IOReturn #c_call;
    close: #type (a0: *void) -> IOReturn #c_call;
    setRemovalCallback: #type (a0: *void, a1: IOHIDCallbackFunction, a2: *void, a3: *void) -> IOReturn #c_call;
    getElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    setElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct, a3: u32, a4: IOHIDElementCallbackFunction, a5: *void, a6: *void) -> IOReturn #c_call;
    queryElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct, a3: u32, a4: IOHIDElementCallbackFunction, a5: *void, a6: *void) -> IOReturn #c_call;
    startAllQueues: #type (a0: *void) -> IOReturn #c_call;
    stopAllQueues: #type (a0: *void) -> IOReturn #c_call;
    allocQueue: #type (a0: *void) -> **IOHIDQueueInterface #c_call;
    allocOutputTransaction: #type (a0: *void) -> **IOHIDOutputTransactionInterface #c_call;
    setReport: #type (a0: *void, a1: IOHIDReportType, a2: u32, a3: *void, a4: u32, a5: u32, a6: IOHIDReportCallbackFunction, a7: *void, a8: *void) -> IOReturn #c_call;
    getReport: #type (a0: *void, a1: IOHIDReportType, a2: u32, a3: *void, a4: *u32, a5: u32, a6: IOHIDReportCallbackFunction, a7: *void, a8: *void) -> IOReturn #c_call;
}



IOHIDDeviceInterface121 :: struct {
    _reserved: *void;
    QueryInterface: #type (a0: *void, a1: REFIID, a2: *LPVOID) -> HRESULT #c_call;
    AddRef: #type (a0: *void) -> ULONG #c_call;
    Release: #type (a0: *void) -> ULONG #c_call;
    createAsyncEventSource: #type (a0: *void, a1: *CFRunLoopSourceRef) -> IOReturn #c_call;
    getAsyncEventSource: #type (a0: *void) -> CFRunLoopSourceRef #c_call;
    createAsyncPort: #type (a0: *void, a1: *mach_port_t) -> IOReturn #c_call;
    getAsyncPort: #type (a0: *void) -> mach_port_t #c_call;
    open: #type (a0: *void, a1: IOOptionBits) -> IOReturn #c_call;
    close: #type (a0: *void) -> IOReturn #c_call;
    setRemovalCallback: #type (a0: *void, a1: IOHIDCallbackFunction, a2: *void, a3: *void) -> IOReturn #c_call;
    getElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    setElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct, a3: u32, a4: IOHIDElementCallbackFunction, a5: *void, a6: *void) -> IOReturn #c_call;
    queryElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct, a3: u32, a4: IOHIDElementCallbackFunction, a5: *void, a6: *void) -> IOReturn #c_call;
    startAllQueues: #type (a0: *void) -> IOReturn #c_call;
    stopAllQueues: #type (a0: *void) -> IOReturn #c_call;
    allocQueue: #type (a0: *void) -> **IOHIDQueueInterface #c_call;
    allocOutputTransaction: #type (a0: *void) -> **IOHIDOutputTransactionInterface #c_call;
    setReport: #type (a0: *void, a1: IOHIDReportType, a2: u32, a3: *void, a4: u32, a5: u32, a6: IOHIDReportCallbackFunction, a7: *void, a8: *void) -> IOReturn #c_call;
    getReport: #type (a0: *void, a1: IOHIDReportType, a2: u32, a3: *void, a4: *u32, a5: u32, a6: IOHIDReportCallbackFunction, a7: *void, a8: *void) -> IOReturn #c_call;
}



IOHIDDeviceInterface122 :: struct {
    _reserved: *void;
    QueryInterface: #type (a0: *void, a1: REFIID, a2: *LPVOID) -> HRESULT #c_call;
    AddRef: #type (a0: *void) -> ULONG #c_call;
    Release: #type (a0: *void) -> ULONG #c_call;
    createAsyncEventSource: #type (a0: *void, a1: *CFRunLoopSourceRef) -> IOReturn #c_call;
    getAsyncEventSource: #type (a0: *void) -> CFRunLoopSourceRef #c_call;
    createAsyncPort: #type (a0: *void, a1: *mach_port_t) -> IOReturn #c_call;
    getAsyncPort: #type (a0: *void) -> mach_port_t #c_call;
    open: #type (a0: *void, a1: IOOptionBits) -> IOReturn #c_call;
    close: #type (a0: *void) -> IOReturn #c_call;
    setRemovalCallback: #type (a0: *void, a1: IOHIDCallbackFunction, a2: *void, a3: *void) -> IOReturn #c_call;
    getElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    setElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct, a3: u32, a4: IOHIDElementCallbackFunction, a5: *void, a6: *void) -> IOReturn #c_call;
    queryElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct, a3: u32, a4: IOHIDElementCallbackFunction, a5: *void, a6: *void) -> IOReturn #c_call;
    startAllQueues: #type (a0: *void) -> IOReturn #c_call;
    stopAllQueues: #type (a0: *void) -> IOReturn #c_call;
    allocQueue: #type (a0: *void) -> **IOHIDQueueInterface #c_call;
    allocOutputTransaction: #type (a0: *void) -> **IOHIDOutputTransactionInterface #c_call;
    setReport: #type (a0: *void, a1: IOHIDReportType, a2: u32, a3: *void, a4: u32, a5: u32, a6: IOHIDReportCallbackFunction, a7: *void, a8: *void) -> IOReturn #c_call;
    getReport: #type (a0: *void, a1: IOHIDReportType, a2: u32, a3: *void, a4: *u32, a5: u32, a6: IOHIDReportCallbackFunction, a7: *void, a8: *void) -> IOReturn #c_call;
    copyMatchingElements: #type (a0: *void, a1: CFDictionaryRef, a2: *CFArrayRef) -> IOReturn #c_call;
    setInterruptReportHandlerCallback: #type (a0: *void, a1: *void, a2: u32, a3: IOHIDReportCallbackFunction, a4: *void, a5: *void) -> IOReturn #c_call;
}



IOHIDQueueInterface :: struct {
    _reserved: *void;
    QueryInterface: #type (a0: *void, a1: REFIID, a2: *LPVOID) -> HRESULT #c_call;
    AddRef: #type (a0: *void) -> ULONG #c_call;
    Release: #type (a0: *void) -> ULONG #c_call;
    createAsyncEventSource: #type (a0: *void, a1: *CFRunLoopSourceRef) -> IOReturn #c_call;
    getAsyncEventSource: #type (a0: *void) -> CFRunLoopSourceRef #c_call;
    createAsyncPort: #type (a0: *void, a1: *mach_port_t) -> IOReturn #c_call;
    getAsyncPort: #type (a0: *void) -> mach_port_t #c_call;
    create: #type (a0: *void, a1: u32, a2: u32) -> IOReturn #c_call;
    dispose: #type (a0: *void) -> IOReturn #c_call;
    addElement: #type (a0: *void, a1: IOHIDElementCookie, a2: u32) -> IOReturn #c_call;
    removeElement: #type (a0: *void, a1: IOHIDElementCookie) -> IOReturn #c_call;
    hasElement: #type (a0: *void, a1: IOHIDElementCookie) -> Boolean #c_call;
    start: #type (a0: *void) -> IOReturn #c_call;
    stop: #type (a0: *void) -> IOReturn #c_call;
    getNextEvent: #type (a0: *void, a1: *IOHIDEventStruct, a2: AbsoluteTime, a3: u32) -> IOReturn #c_call;
    setEventCallout: #type (a0: *void, a1: IOHIDCallbackFunction, a2: *void, a3: *void) -> IOReturn #c_call;
    getEventCallout: #type (a0: *void, a1: *IOHIDCallbackFunction, a2: **void, a3: **void) -> IOReturn #c_call;
}

IOHIDOutputTransactionInterface :: struct {
    _reserved: *void;
    QueryInterface: #type (a0: *void, a1: REFIID, a2: *LPVOID) -> HRESULT #c_call;
    AddRef: #type (a0: *void) -> ULONG #c_call;
    Release: #type (a0: *void) -> ULONG #c_call;
    createAsyncEventSource: #type (a0: *void, a1: *CFRunLoopSourceRef) -> IOReturn #c_call;
    getAsyncEventSource: #type (a0: *void) -> CFRunLoopSourceRef #c_call;
    createAsyncPort: #type (a0: *void, a1: *mach_port_t) -> IOReturn #c_call;
    getAsyncPort: #type (a0: *void) -> mach_port_t #c_call;
    create: #type (a0: *void) -> IOReturn #c_call;
    dispose: #type (a0: *void) -> IOReturn #c_call;
    addElement: #type (a0: *void, a1: IOHIDElementCookie) -> IOReturn #c_call;
    removeElement: #type (a0: *void, a1: IOHIDElementCookie) -> IOReturn #c_call;
    hasElement: #type (a0: *void, a1: IOHIDElementCookie) -> Boolean #c_call;
    setElementDefault: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    getElementDefault: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    setElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    getElementValue: #type (a0: *void, a1: IOHIDElementCookie, a2: *IOHIDEventStruct) -> IOReturn #c_call;
    commit: #type (a0: *void, a1: u32, a2: IOHIDCallbackFunction, a3: *void, a4: *void) -> IOReturn #c_call;
    clear: #type (a0: *void) -> IOReturn #c_call;
}

using IOHIDManagerOptions :: enum u32 {
    kIOHIDManagerOptionNone :: 0;
    kIOHIDManagerOptionUsePersistentProperties :: 1;
    kIOHIDManagerOptionDoNotLoadProperties :: 2;
    kIOHIDManagerOptionDoNotSaveProperties :: 4;
}



__IOHIDManager :: struct {
}

IOHIDManagerRef :: *__IOHIDManager;

IOHIDManagerGetTypeID :: () -> CFTypeID #foreign IOKit;

IOHIDManagerCreate :: (allocator: CFAllocatorRef, options: IOOptionBits) -> IOHIDManagerRef #foreign IOKit;

IOHIDManagerOpen :: (manager: IOHIDManagerRef, options: IOOptionBits) -> IOReturn #foreign IOKit;

IOHIDManagerClose :: (manager: IOHIDManagerRef, options: IOOptionBits) -> IOReturn #foreign IOKit;

IOHIDManagerGetProperty :: (manager: IOHIDManagerRef, key: CFStringRef) -> CFTypeRef #foreign IOKit;

IOHIDManagerSetProperty :: (manager: IOHIDManagerRef, key: CFStringRef, value: CFTypeRef) -> Boolean #foreign IOKit;

IOHIDManagerScheduleWithRunLoop :: (manager: IOHIDManagerRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDManagerUnscheduleFromRunLoop :: (manager: IOHIDManagerRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDManagerSetDeviceMatching :: (manager: IOHIDManagerRef, matching: CFDictionaryRef) -> void #foreign IOKit;

IOHIDManagerSetDeviceMatchingMultiple :: (manager: IOHIDManagerRef, multiple: CFArrayRef) -> void #foreign IOKit;

IOHIDManagerCopyDevices :: (manager: IOHIDManagerRef) -> CFSetRef #foreign IOKit;

IOHIDManagerRegisterDeviceMatchingCallback :: (manager: IOHIDManagerRef, callback: IOHIDDeviceCallback, _context: *void) -> void #foreign IOKit;

IOHIDManagerRegisterDeviceRemovalCallback :: (manager: IOHIDManagerRef, callback: IOHIDDeviceCallback, _context: *void) -> void #foreign IOKit;

IOHIDManagerRegisterInputReportCallback :: (manager: IOHIDManagerRef, callback: IOHIDReportCallback, _context: *void) -> void #foreign IOKit;

IOHIDManagerRegisterInputValueCallback :: (manager: IOHIDManagerRef, callback: IOHIDValueCallback, _context: *void) -> void #foreign IOKit;

IOHIDManagerSetInputValueMatching :: (manager: IOHIDManagerRef, matching: CFDictionaryRef) -> void #foreign IOKit;

IOHIDManagerSetInputValueMatchingMultiple :: (manager: IOHIDManagerRef, multiple: CFArrayRef) -> void #foreign IOKit;

IOHIDManagerSaveToPropertyDomain :: (manager: IOHIDManagerRef, applicationID: CFStringRef, userName: CFStringRef, hostName: CFStringRef, options: IOOptionBits) -> void #foreign IOKit;

__IOHIDQueue :: struct {
}

IOHIDQueueRef :: *__IOHIDQueue;

IOHIDQueueGetTypeID :: () -> CFTypeID #foreign IOKit;

IOHIDQueueCreate :: (allocator: CFAllocatorRef, device: IOHIDDeviceRef, depth: CFIndex, options: IOOptionBits) -> IOHIDQueueRef #foreign IOKit;

IOHIDQueueGetDevice :: (queue: IOHIDQueueRef) -> IOHIDDeviceRef #foreign IOKit;

IOHIDQueueGetDepth :: (queue: IOHIDQueueRef) -> CFIndex #foreign IOKit;

IOHIDQueueSetDepth :: (queue: IOHIDQueueRef, depth: CFIndex) -> void #foreign IOKit;

IOHIDQueueAddElement :: (queue: IOHIDQueueRef, element: IOHIDElementRef) -> void #foreign IOKit;

IOHIDQueueRemoveElement :: (queue: IOHIDQueueRef, element: IOHIDElementRef) -> void #foreign IOKit;

IOHIDQueueContainsElement :: (queue: IOHIDQueueRef, element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDQueueStart :: (queue: IOHIDQueueRef) -> void #foreign IOKit;

IOHIDQueueStop :: (queue: IOHIDQueueRef) -> void #foreign IOKit;

IOHIDQueueScheduleWithRunLoop :: (queue: IOHIDQueueRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDQueueUnscheduleFromRunLoop :: (queue: IOHIDQueueRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDQueueRegisterValueAvailableCallback :: (queue: IOHIDQueueRef, callback: IOHIDCallback, _context: *void) -> void #foreign IOKit;

IOHIDQueueCopyNextValue :: (queue: IOHIDQueueRef) -> IOHIDValueRef #foreign IOKit;

IOHIDQueueCopyNextValueWithTimeout :: (queue: IOHIDQueueRef, timeout: CFTimeInterval) -> IOHIDValueRef #foreign IOKit;

kHIDPage_Undefined :: 0;
kHIDPage_GenericDesktop :: 1;
kHIDPage_Simulation :: 2;
kHIDPage_VR :: 3;
kHIDPage_Sport :: 4;
kHIDPage_Game :: 5;
kHIDPage_GenericDeviceControls :: 6;
kHIDPage_KeyboardOrKeypad :: 7;
kHIDPage_LEDs :: 8;
kHIDPage_Button :: 9;
kHIDPage_Ordinal :: 10;
kHIDPage_Telephony :: 11;
kHIDPage_Consumer :: 12;
kHIDPage_Digitizer :: 13;
kHIDPage_PID :: 15;
kHIDPage_Unicode :: 16;
kHIDPage_AlphanumericDisplay :: 20;
kHIDPage_Sensor :: 32;
kHIDPage_Monitor :: 128;
kHIDPage_MonitorEnumerated :: 129;
kHIDPage_MonitorVirtual :: 130;
kHIDPage_MonitorReserved :: 131;
kHIDPage_PowerDevice :: 132;
kHIDPage_BatterySystem :: 133;
kHIDPage_PowerReserved :: 134;
kHIDPage_PowerReserved2 :: 135;
kHIDPage_BarCodeScanner :: 140;
kHIDPage_WeighingDevice :: 141;
kHIDPage_Scale :: 141;
kHIDPage_MagneticStripeReader :: 142;
kHIDPage_CameraControl :: 144;
kHIDPage_Arcade :: 145;
kHIDPage_VendorDefinedStart :: 65280;


kHIDUsage_Undefined :: 0;

kHIDUsage_GD_Pointer :: 1;
kHIDUsage_GD_Mouse :: 2;
kHIDUsage_GD_Joystick :: 4;
kHIDUsage_GD_GamePad :: 5;
kHIDUsage_GD_Keyboard :: 6;
kHIDUsage_GD_Keypad :: 7;
kHIDUsage_GD_MultiAxisController :: 8;
kHIDUsage_GD_TabletPCSystemControls :: 9;
kHIDUsage_GD_AssistiveControl :: 10;
kHIDUsage_GD_X :: 48;
kHIDUsage_GD_Y :: 49;
kHIDUsage_GD_Z :: 50;
kHIDUsage_GD_Rx :: 51;
kHIDUsage_GD_Ry :: 52;
kHIDUsage_GD_Rz :: 53;
kHIDUsage_GD_Slider :: 54;
kHIDUsage_GD_Dial :: 55;
kHIDUsage_GD_Wheel :: 56;
kHIDUsage_GD_Hatswitch :: 57;
kHIDUsage_GD_CountedBuffer :: 58;
kHIDUsage_GD_ByteCount :: 59;
kHIDUsage_GD_MotionWakeup :: 60;
kHIDUsage_GD_Start :: 61;
kHIDUsage_GD_Select :: 62;
kHIDUsage_GD_Vx :: 64;
kHIDUsage_GD_Vy :: 65;
kHIDUsage_GD_Vz :: 66;
kHIDUsage_GD_Vbrx :: 67;
kHIDUsage_GD_Vbry :: 68;
kHIDUsage_GD_Vbrz :: 69;
kHIDUsage_GD_Vno :: 70;
kHIDUsage_GD_SystemControl :: 128;
kHIDUsage_GD_SystemPowerDown :: 129;
kHIDUsage_GD_SystemSleep :: 130;
kHIDUsage_GD_SystemWakeUp :: 131;
kHIDUsage_GD_SystemContextMenu :: 132;
kHIDUsage_GD_SystemMainMenu :: 133;
kHIDUsage_GD_SystemAppMenu :: 134;
kHIDUsage_GD_SystemMenuHelp :: 135;
kHIDUsage_GD_SystemMenuExit :: 136;
kHIDUsage_GD_SystemMenuSelect :: 137;
kHIDUsage_GD_SystemMenu :: 137;
kHIDUsage_GD_SystemMenuRight :: 138;
kHIDUsage_GD_SystemMenuLeft :: 139;
kHIDUsage_GD_SystemMenuUp :: 140;
kHIDUsage_GD_SystemMenuDown :: 141;
kHIDUsage_GD_DPadUp :: 144;
kHIDUsage_GD_DPadDown :: 145;
kHIDUsage_GD_DPadRight :: 146;
kHIDUsage_GD_DPadLeft :: 147;
kHIDUsage_GD_Reserved :: 65535;

kHIDUsage_Sim_FlightSimulationDevice :: 1;
kHIDUsage_Sim_AutomobileSimulationDevice :: 2;
kHIDUsage_Sim_TankSimulationDevice :: 3;
kHIDUsage_Sim_SpaceshipSimulationDevice :: 4;
kHIDUsage_Sim_SubmarineSimulationDevice :: 5;
kHIDUsage_Sim_SailingSimulationDevice :: 6;
kHIDUsage_Sim_MotorcycleSimulationDevice :: 7;
kHIDUsage_Sim_SportsSimulationDevice :: 8;
kHIDUsage_Sim_AirplaneSimulationDevice :: 9;
kHIDUsage_Sim_HelicopterSimulationDevice :: 10;
kHIDUsage_Sim_MagicCarpetSimulationDevice :: 11;
kHIDUsage_Sim_BicycleSimulationDevice :: 12;
kHIDUsage_Sim_FlightControlStick :: 32;
kHIDUsage_Sim_FlightStick :: 33;
kHIDUsage_Sim_CyclicControl :: 34;
kHIDUsage_Sim_CyclicTrim :: 35;
kHIDUsage_Sim_FlightYoke :: 36;
kHIDUsage_Sim_TrackControl :: 37;
kHIDUsage_Sim_Aileron :: 176;
kHIDUsage_Sim_AileronTrim :: 177;
kHIDUsage_Sim_AntiTorqueControl :: 178;
kHIDUsage_Sim_AutopilotEnable :: 179;
kHIDUsage_Sim_ChaffRelease :: 180;
kHIDUsage_Sim_CollectiveControl :: 181;
kHIDUsage_Sim_DiveBrake :: 182;
kHIDUsage_Sim_ElectronicCountermeasures :: 183;
kHIDUsage_Sim_Elevator :: 184;
kHIDUsage_Sim_ElevatorTrim :: 185;
kHIDUsage_Sim_Rudder :: 186;
kHIDUsage_Sim_Throttle :: 187;
kHIDUsage_Sim_FlightCommunications :: 188;
kHIDUsage_Sim_FlareRelease :: 189;
kHIDUsage_Sim_LandingGear :: 190;
kHIDUsage_Sim_ToeBrake :: 191;
kHIDUsage_Sim_Trigger :: 192;
kHIDUsage_Sim_WeaponsArm :: 193;
kHIDUsage_Sim_Weapons :: 194;
kHIDUsage_Sim_WingFlaps :: 195;
kHIDUsage_Sim_Accelerator :: 196;
kHIDUsage_Sim_Brake :: 197;
kHIDUsage_Sim_Clutch :: 198;
kHIDUsage_Sim_Shifter :: 199;
kHIDUsage_Sim_Steering :: 200;
kHIDUsage_Sim_TurretDirection :: 201;
kHIDUsage_Sim_BarrelElevation :: 202;
kHIDUsage_Sim_DivePlane :: 203;
kHIDUsage_Sim_Ballast :: 204;
kHIDUsage_Sim_BicycleCrank :: 205;
kHIDUsage_Sim_HandleBars :: 206;
kHIDUsage_Sim_FrontBrake :: 207;
kHIDUsage_Sim_RearBrake :: 208;
kHIDUsage_Sim_Reserved :: 65535;

kHIDUsage_VR_Belt :: 1;
kHIDUsage_VR_BodySuit :: 2;
kHIDUsage_VR_Flexor :: 3;
kHIDUsage_VR_Glove :: 4;
kHIDUsage_VR_HeadTracker :: 5;
kHIDUsage_VR_HeadMountedDisplay :: 6;
kHIDUsage_VR_HandTracker :: 7;
kHIDUsage_VR_Oculometer :: 8;
kHIDUsage_VR_Vest :: 9;
kHIDUsage_VR_AnimatronicDevice :: 10;
kHIDUsage_VR_StereoEnable :: 32;
kHIDUsage_VR_DisplayEnable :: 33;
kHIDUsage_VR_Reserved :: 65535;

kHIDUsage_Sprt_BaseballBat :: 1;
kHIDUsage_Sprt_GolfClub :: 2;
kHIDUsage_Sprt_RowingMachine :: 3;
kHIDUsage_Sprt_Treadmill :: 4;
kHIDUsage_Sprt_Oar :: 48;
kHIDUsage_Sprt_Slope :: 49;
kHIDUsage_Sprt_Rate :: 50;
kHIDUsage_Sprt_StickSpeed :: 51;
kHIDUsage_Sprt_StickFaceAngle :: 52;
kHIDUsage_Sprt_StickHeelOrToe :: 53;
kHIDUsage_Sprt_StickFollowThrough :: 54;
kHIDUsage_Sprt_StickTempo :: 55;
kHIDUsage_Sprt_StickType :: 56;
kHIDUsage_Sprt_StickHeight :: 57;
kHIDUsage_Sprt_Putter :: 80;
kHIDUsage_Sprt_1Iron :: 81;
kHIDUsage_Sprt_2Iron :: 82;
kHIDUsage_Sprt_3Iron :: 83;
kHIDUsage_Sprt_4Iron :: 84;
kHIDUsage_Sprt_5Iron :: 85;
kHIDUsage_Sprt_6Iron :: 86;
kHIDUsage_Sprt_7Iron :: 87;
kHIDUsage_Sprt_8Iron :: 88;
kHIDUsage_Sprt_9Iron :: 89;
kHIDUsage_Sprt_10Iron :: 90;
kHIDUsage_Sprt_11Iron :: 91;
kHIDUsage_Sprt_SandWedge :: 92;
kHIDUsage_Sprt_LoftWedge :: 93;
kHIDUsage_Sprt_PowerWedge :: 94;
kHIDUsage_Sprt_1Wood :: 95;
kHIDUsage_Sprt_3Wood :: 96;
kHIDUsage_Sprt_5Wood :: 97;
kHIDUsage_Sprt_7Wood :: 98;
kHIDUsage_Sprt_9Wood :: 99;
kHIDUsage_Sprt_Reserved :: 65535;


kHIDUsage_Game_3DGameController :: 1;
kHIDUsage_Game_PinballDevice :: 2;
kHIDUsage_Game_GunDevice :: 3;
kHIDUsage_Game_PointofView :: 32;
kHIDUsage_Game_TurnRightOrLeft :: 33;
kHIDUsage_Game_PitchUpOrDown :: 34;
kHIDUsage_Game_RollRightOrLeft :: 35;
kHIDUsage_Game_MoveRightOrLeft :: 36;
kHIDUsage_Game_MoveForwardOrBackward :: 37;
kHIDUsage_Game_MoveUpOrDown :: 38;
kHIDUsage_Game_LeanRightOrLeft :: 39;
kHIDUsage_Game_LeanForwardOrBackward :: 40;
kHIDUsage_Game_HeightOfPOV :: 41;
kHIDUsage_Game_Flipper :: 42;
kHIDUsage_Game_SecondaryFlipper :: 43;
kHIDUsage_Game_Bump :: 44;
kHIDUsage_Game_NewGame :: 45;
kHIDUsage_Game_ShootBall :: 46;
kHIDUsage_Game_Player :: 47;
kHIDUsage_Game_GunBolt :: 48;
kHIDUsage_Game_GunClip :: 49;
kHIDUsage_Game_Gun :: 50;
kHIDUsage_Game_GunSingleShot :: 51;
kHIDUsage_Game_GunBurst :: 52;
kHIDUsage_Game_GunAutomatic :: 53;
kHIDUsage_Game_GunSafety :: 54;
kHIDUsage_Game_GamepadFireOrJump :: 55;
kHIDUsage_Game_GamepadTrigger :: 57;
kHIDUsage_Game_GamepadFormFitting :: 57;
kHIDUsage_Game_Reserved :: 65535;

using anon_enum_105 :: enum u32 {
    kHIDUsage_GenDevControls_BackgroundControls :: 1;
}

using anon_enum_106 :: enum u32 {
    kHIDUsage_KeyboardErrorRollOver :: 1;
    kHIDUsage_KeyboardPOSTFail :: 2;
    kHIDUsage_KeyboardErrorUndefined :: 3;
    kHIDUsage_KeyboardA :: 4;
    kHIDUsage_KeyboardB :: 5;
    kHIDUsage_KeyboardC :: 6;
    kHIDUsage_KeyboardD :: 7;
    kHIDUsage_KeyboardE :: 8;
    kHIDUsage_KeyboardF :: 9;
    kHIDUsage_KeyboardG :: 10;
    kHIDUsage_KeyboardH :: 11;
    kHIDUsage_KeyboardI :: 12;
    kHIDUsage_KeyboardJ :: 13;
    kHIDUsage_KeyboardK :: 14;
    kHIDUsage_KeyboardL :: 15;
    kHIDUsage_KeyboardM :: 16;
    kHIDUsage_KeyboardN :: 17;
    kHIDUsage_KeyboardO :: 18;
    kHIDUsage_KeyboardP :: 19;
    kHIDUsage_KeyboardQ :: 20;
    kHIDUsage_KeyboardR :: 21;
    kHIDUsage_KeyboardS :: 22;
    kHIDUsage_KeyboardT :: 23;
    kHIDUsage_KeyboardU :: 24;
    kHIDUsage_KeyboardV :: 25;
    kHIDUsage_KeyboardW :: 26;
    kHIDUsage_KeyboardX :: 27;
    kHIDUsage_KeyboardY :: 28;
    kHIDUsage_KeyboardZ :: 29;
    kHIDUsage_Keyboard1 :: 30;
    kHIDUsage_Keyboard2 :: 31;
    kHIDUsage_Keyboard3 :: 32;
    kHIDUsage_Keyboard4 :: 33;
    kHIDUsage_Keyboard5 :: 34;
    kHIDUsage_Keyboard6 :: 35;
    kHIDUsage_Keyboard7 :: 36;
    kHIDUsage_Keyboard8 :: 37;
    kHIDUsage_Keyboard9 :: 38;
    kHIDUsage_Keyboard0 :: 39;
    kHIDUsage_KeyboardReturnOrEnter :: 40;
    kHIDUsage_KeyboardEscape :: 41;
    kHIDUsage_KeyboardDeleteOrBackspace :: 42;
    kHIDUsage_KeyboardTab :: 43;
    kHIDUsage_KeyboardSpacebar :: 44;
    kHIDUsage_KeyboardHyphen :: 45;
    kHIDUsage_KeyboardEqualSign :: 46;
    kHIDUsage_KeyboardOpenBracket :: 47;
    kHIDUsage_KeyboardCloseBracket :: 48;
    kHIDUsage_KeyboardBackslash :: 49;
    kHIDUsage_KeyboardNonUSPound :: 50;
    kHIDUsage_KeyboardSemicolon :: 51;
    kHIDUsage_KeyboardQuote :: 52;
    kHIDUsage_KeyboardGraveAccentAndTilde :: 53;
    kHIDUsage_KeyboardComma :: 54;
    kHIDUsage_KeyboardPeriod :: 55;
    kHIDUsage_KeyboardSlash :: 56;
    kHIDUsage_KeyboardCapsLock :: 57;
    kHIDUsage_KeyboardF1 :: 58;
    kHIDUsage_KeyboardF2 :: 59;
    kHIDUsage_KeyboardF3 :: 60;
    kHIDUsage_KeyboardF4 :: 61;
    kHIDUsage_KeyboardF5 :: 62;
    kHIDUsage_KeyboardF6 :: 63;
    kHIDUsage_KeyboardF7 :: 64;
    kHIDUsage_KeyboardF8 :: 65;
    kHIDUsage_KeyboardF9 :: 66;
    kHIDUsage_KeyboardF10 :: 67;
    kHIDUsage_KeyboardF11 :: 68;
    kHIDUsage_KeyboardF12 :: 69;
    kHIDUsage_KeyboardPrintScreen :: 70;
    kHIDUsage_KeyboardScrollLock :: 71;
    kHIDUsage_KeyboardPause :: 72;
    kHIDUsage_KeyboardInsert :: 73;
    kHIDUsage_KeyboardHome :: 74;
    kHIDUsage_KeyboardPageUp :: 75;
    kHIDUsage_KeyboardDeleteForward :: 76;
    kHIDUsage_KeyboardEnd :: 77;
    kHIDUsage_KeyboardPageDown :: 78;
    kHIDUsage_KeyboardRightArrow :: 79;
    kHIDUsage_KeyboardLeftArrow :: 80;
    kHIDUsage_KeyboardDownArrow :: 81;
    kHIDUsage_KeyboardUpArrow :: 82;
    kHIDUsage_KeypadNumLock :: 83;
    kHIDUsage_KeypadSlash :: 84;
    kHIDUsage_KeypadAsterisk :: 85;
    kHIDUsage_KeypadHyphen :: 86;
    kHIDUsage_KeypadPlus :: 87;
    kHIDUsage_KeypadEnter :: 88;
    kHIDUsage_Keypad1 :: 89;
    kHIDUsage_Keypad2 :: 90;
    kHIDUsage_Keypad3 :: 91;
    kHIDUsage_Keypad4 :: 92;
    kHIDUsage_Keypad5 :: 93;
    kHIDUsage_Keypad6 :: 94;
    kHIDUsage_Keypad7 :: 95;
    kHIDUsage_Keypad8 :: 96;
    kHIDUsage_Keypad9 :: 97;
    kHIDUsage_Keypad0 :: 98;
    kHIDUsage_KeypadPeriod :: 99;
    kHIDUsage_KeyboardNonUSBackslash :: 100;
    kHIDUsage_KeyboardApplication :: 101;
    kHIDUsage_KeyboardPower :: 102;
    kHIDUsage_KeypadEqualSign :: 103;
    kHIDUsage_KeyboardF13 :: 104;
    kHIDUsage_KeyboardF14 :: 105;
    kHIDUsage_KeyboardF15 :: 106;
    kHIDUsage_KeyboardF16 :: 107;
    kHIDUsage_KeyboardF17 :: 108;
    kHIDUsage_KeyboardF18 :: 109;
    kHIDUsage_KeyboardF19 :: 110;
    kHIDUsage_KeyboardF20 :: 111;
    kHIDUsage_KeyboardF21 :: 112;
    kHIDUsage_KeyboardF22 :: 113;
    kHIDUsage_KeyboardF23 :: 114;
    kHIDUsage_KeyboardF24 :: 115;
    kHIDUsage_KeyboardExecute :: 116;
    kHIDUsage_KeyboardHelp :: 117;
    kHIDUsage_KeyboardMenu :: 118;
    kHIDUsage_KeyboardSelect :: 119;
    kHIDUsage_KeyboardStop :: 120;
    kHIDUsage_KeyboardAgain :: 121;
    kHIDUsage_KeyboardUndo :: 122;
    kHIDUsage_KeyboardCut :: 123;
    kHIDUsage_KeyboardCopy :: 124;
    kHIDUsage_KeyboardPaste :: 125;
    kHIDUsage_KeyboardFind :: 126;
    kHIDUsage_KeyboardMute :: 127;
    kHIDUsage_KeyboardVolumeUp :: 128;
    kHIDUsage_KeyboardVolumeDown :: 129;
    kHIDUsage_KeyboardLockingCapsLock :: 130;
    kHIDUsage_KeyboardLockingNumLock :: 131;
    kHIDUsage_KeyboardLockingScrollLock :: 132;
    kHIDUsage_KeypadComma :: 133;
    kHIDUsage_KeypadEqualSignAS400 :: 134;
    kHIDUsage_KeyboardInternational1 :: 135;
    kHIDUsage_KeyboardInternational2 :: 136;
    kHIDUsage_KeyboardInternational3 :: 137;
    kHIDUsage_KeyboardInternational4 :: 138;
    kHIDUsage_KeyboardInternational5 :: 139;
    kHIDUsage_KeyboardInternational6 :: 140;
    kHIDUsage_KeyboardInternational7 :: 141;
    kHIDUsage_KeyboardInternational8 :: 142;
    kHIDUsage_KeyboardInternational9 :: 143;
    kHIDUsage_KeyboardLANG1 :: 144;
    kHIDUsage_KeyboardLANG2 :: 145;
    kHIDUsage_KeyboardLANG3 :: 146;
    kHIDUsage_KeyboardLANG4 :: 147;
    kHIDUsage_KeyboardLANG5 :: 148;
    kHIDUsage_KeyboardLANG6 :: 149;
    kHIDUsage_KeyboardLANG7 :: 150;
    kHIDUsage_KeyboardLANG8 :: 151;
    kHIDUsage_KeyboardLANG9 :: 152;
    kHIDUsage_KeyboardAlternateErase :: 153;
    kHIDUsage_KeyboardSysReqOrAttention :: 154;
    kHIDUsage_KeyboardCancel :: 155;
    kHIDUsage_KeyboardClear :: 156;
    kHIDUsage_KeyboardPrior :: 157;
    kHIDUsage_KeyboardReturn :: 158;
    kHIDUsage_KeyboardSeparator :: 159;
    kHIDUsage_KeyboardOut :: 160;
    kHIDUsage_KeyboardOper :: 161;
    kHIDUsage_KeyboardClearOrAgain :: 162;
    kHIDUsage_KeyboardCrSelOrProps :: 163;
    kHIDUsage_KeyboardExSel :: 164;
    kHIDUsage_KeyboardLeftControl :: 224;
    kHIDUsage_KeyboardLeftShift :: 225;
    kHIDUsage_KeyboardLeftAlt :: 226;
    kHIDUsage_KeyboardLeftGUI :: 227;
    kHIDUsage_KeyboardRightControl :: 228;
    kHIDUsage_KeyboardRightShift :: 229;
    kHIDUsage_KeyboardRightAlt :: 230;
    kHIDUsage_KeyboardRightGUI :: 231;
    kHIDUsage_Keyboard_Reserved :: 65535;
}

using anon_enum_107 :: enum u32 {
    kHIDUsage_LED_NumLock :: 1;
    kHIDUsage_LED_CapsLock :: 2;
    kHIDUsage_LED_ScrollLock :: 3;
    kHIDUsage_LED_Compose :: 4;
    kHIDUsage_LED_Kana :: 5;
    kHIDUsage_LED_Power :: 6;
    kHIDUsage_LED_Shift :: 7;
    kHIDUsage_LED_DoNotDisturb :: 8;
    kHIDUsage_LED_Mute :: 9;
    kHIDUsage_LED_ToneEnable :: 10;
    kHIDUsage_LED_HighCutFilter :: 11;
    kHIDUsage_LED_LowCutFilter :: 12;
    kHIDUsage_LED_EqualizerEnable :: 13;
    kHIDUsage_LED_SoundFieldOn :: 14;
    kHIDUsage_LED_SurroundOn :: 15;
    kHIDUsage_LED_Repeat :: 16;
    kHIDUsage_LED_Stereo :: 17;
    kHIDUsage_LED_SamplingRateDetect :: 18;
    kHIDUsage_LED_Spinning :: 19;
    kHIDUsage_LED_CAV :: 20;
    kHIDUsage_LED_CLV :: 21;
    kHIDUsage_LED_RecordingFormatDetect :: 22;
    kHIDUsage_LED_OffHook :: 23;
    kHIDUsage_LED_Ring :: 24;
    kHIDUsage_LED_MessageWaiting :: 25;
    kHIDUsage_LED_DataMode :: 26;
    kHIDUsage_LED_BatteryOperation :: 27;
    kHIDUsage_LED_BatteryOK :: 28;
    kHIDUsage_LED_BatteryLow :: 29;
    kHIDUsage_LED_Speaker :: 30;
    kHIDUsage_LED_HeadSet :: 31;
    kHIDUsage_LED_Hold :: 32;
    kHIDUsage_LED_Microphone :: 33;
    kHIDUsage_LED_Coverage :: 34;
    kHIDUsage_LED_NightMode :: 35;
    kHIDUsage_LED_SendCalls :: 36;
    kHIDUsage_LED_CallPickup :: 37;
    kHIDUsage_LED_Conference :: 38;
    kHIDUsage_LED_StandBy :: 39;
    kHIDUsage_LED_CameraOn :: 40;
    kHIDUsage_LED_CameraOff :: 41;
    kHIDUsage_LED_OnLine :: 42;
    kHIDUsage_LED_OffLine :: 43;
    kHIDUsage_LED_Busy :: 44;
    kHIDUsage_LED_Ready :: 45;
    kHIDUsage_LED_PaperOut :: 46;
    kHIDUsage_LED_PaperJam :: 47;
    kHIDUsage_LED_Remote :: 48;
    kHIDUsage_LED_Forward :: 49;
    kHIDUsage_LED_Reverse :: 50;
    kHIDUsage_LED_Stop :: 51;
    kHIDUsage_LED_Rewind :: 52;
    kHIDUsage_LED_FastForward :: 53;
    kHIDUsage_LED_Play :: 54;
    kHIDUsage_LED_Pause :: 55;
    kHIDUsage_LED_Record :: 56;
    kHIDUsage_LED_Error :: 57;
    kHIDUsage_LED_Usage :: 58;
    kHIDUsage_LED_UsageInUseIndicator :: 59;
    kHIDUsage_LED_UsageMultiModeIndicator :: 60;
    kHIDUsage_LED_IndicatorOn :: 61;
    kHIDUsage_LED_IndicatorFlash :: 62;
    kHIDUsage_LED_IndicatorSlowBlink :: 63;
    kHIDUsage_LED_IndicatorFastBlink :: 64;
    kHIDUsage_LED_IndicatorOff :: 65;
    kHIDUsage_LED_FlashOnTime :: 66;
    kHIDUsage_LED_SlowBlinkOnTime :: 67;
    kHIDUsage_LED_SlowBlinkOffTime :: 68;
    kHIDUsage_LED_FastBlinkOnTime :: 69;
    kHIDUsage_LED_FastBlinkOffTime :: 70;
    kHIDUsage_LED_UsageIndicatorColor :: 71;
    kHIDUsage_LED_IndicatorRed :: 72;
    kHIDUsage_LED_IndicatorGreen :: 73;
    kHIDUsage_LED_IndicatorAmber :: 74;
    kHIDUsage_LED_GenericIndicator :: 75;
    kHIDUsage_LED_SystemSuspend :: 76;
    kHIDUsage_LED_ExternalPowerConnected :: 77;
    kHIDUsage_LED_PlayerIndicator :: 78;
    kHIDUsage_LED_Player1 :: 79;
    kHIDUsage_LED_Player2 :: 80;
    kHIDUsage_LED_Player3 :: 81;
    kHIDUsage_LED_Player4 :: 82;
    kHIDUsage_LED_Player5 :: 83;
    kHIDUsage_LED_Player6 :: 84;
    kHIDUsage_LED_Player7 :: 85;
    kHIDUsage_LED_Player8 :: 86;
    kHIDUsage_LED_Reserved :: 65535;
}

using anon_enum_108 :: enum u32 {
    kHIDUsage_Button_1 :: 1;
    kHIDUsage_Button_2 :: 2;
    kHIDUsage_Button_3 :: 3;
    kHIDUsage_Button_4 :: 4;
    kHIDUsage_Button_65535 :: 65535;
}

using anon_enum_109 :: enum u32 {
    kHIDUsage_Ord_Instance1 :: 1;
    kHIDUsage_Ord_Instance2 :: 2;
    kHIDUsage_Ord_Instance3 :: 3;
    kHIDUsage_Ord_Instance4 :: 4;
    kHIDUsage_Ord_Instance65535 :: 65535;
}

using anon_enum_110 :: enum u32 {
    kHIDUsage_Tfon_Phone :: 1;
    kHIDUsage_Tfon_AnsweringMachine :: 2;
    kHIDUsage_Tfon_MessageControls :: 3;
    kHIDUsage_Tfon_Handset :: 4;
    kHIDUsage_Tfon_Headset :: 5;
    kHIDUsage_Tfon_TelephonyKeyPad :: 6;
    kHIDUsage_Tfon_ProgrammableButton :: 7;
    kHIDUsage_Tfon_HookSwitch :: 32;
    kHIDUsage_Tfon_Flash :: 33;
    kHIDUsage_Tfon_Feature :: 34;
    kHIDUsage_Tfon_Hold :: 35;
    kHIDUsage_Tfon_Redial :: 36;
    kHIDUsage_Tfon_Transfer :: 37;
    kHIDUsage_Tfon_Drop :: 38;
    kHIDUsage_Tfon_Park :: 39;
    kHIDUsage_Tfon_ForwardCalls :: 40;
    kHIDUsage_Tfon_AlternateFunction :: 41;
    kHIDUsage_Tfon_Line :: 42;
    kHIDUsage_Tfon_SpeakerPhone :: 43;
    kHIDUsage_Tfon_Conference :: 44;
    kHIDUsage_Tfon_RingEnable :: 45;
    kHIDUsage_Tfon_Ring :: 46;
    kHIDUsage_Tfon_PhoneMute :: 47;
    kHIDUsage_Tfon_CallerID :: 48;
    kHIDUsage_Tfon_SpeedDial :: 80;
    kHIDUsage_Tfon_StoreNumber :: 81;
    kHIDUsage_Tfon_RecallNumber :: 82;
    kHIDUsage_Tfon_PhoneDirectory :: 83;
    kHIDUsage_Tfon_VoiceMail :: 112;
    kHIDUsage_Tfon_ScreenCalls :: 113;
    kHIDUsage_Tfon_DoNotDisturb :: 114;
    kHIDUsage_Tfon_Message :: 115;
    kHIDUsage_Tfon_AnswerOnOrOff :: 116;
    kHIDUsage_Tfon_InsideDialTone :: 144;
    kHIDUsage_Tfon_OutsideDialTone :: 145;
    kHIDUsage_Tfon_InsideRingTone :: 146;
    kHIDUsage_Tfon_OutsideRingTone :: 147;
    kHIDUsage_Tfon_PriorityRingTone :: 148;
    kHIDUsage_Tfon_InsideRingback :: 149;
    kHIDUsage_Tfon_PriorityRingback :: 150;
    kHIDUsage_Tfon_LineBusyTone :: 151;
    kHIDUsage_Tfon_ReorderTone :: 152;
    kHIDUsage_Tfon_CallWaitingTone :: 153;
    kHIDUsage_Tfon_ConfirmationTone1 :: 154;
    kHIDUsage_Tfon_ConfirmationTone2 :: 155;
    kHIDUsage_Tfon_TonesOff :: 156;
    kHIDUsage_Tfon_OutsideRingback :: 157;
    kHIDUsage_Tfon_PhoneKey0 :: 176;
    kHIDUsage_Tfon_PhoneKey1 :: 177;
    kHIDUsage_Tfon_PhoneKey2 :: 178;
    kHIDUsage_Tfon_PhoneKey3 :: 179;
    kHIDUsage_Tfon_PhoneKey4 :: 180;
    kHIDUsage_Tfon_PhoneKey5 :: 181;
    kHIDUsage_Tfon_PhoneKey6 :: 182;
    kHIDUsage_Tfon_PhoneKey7 :: 183;
    kHIDUsage_Tfon_PhoneKey8 :: 184;
    kHIDUsage_Tfon_PhoneKey9 :: 185;
    kHIDUsage_Tfon_PhoneKeyStar :: 186;
    kHIDUsage_Tfon_PhoneKeyPound :: 187;
    kHIDUsage_Tfon_PhoneKeyA :: 188;
    kHIDUsage_Tfon_PhoneKeyB :: 189;
    kHIDUsage_Tfon_PhoneKeyC :: 190;
    kHIDUsage_Tfon_PhoneKeyD :: 191;
    kHIDUsage_TFon_Reserved :: 65535;
}

using anon_enum_111 :: enum u32 {
    kHIDUsage_Csmr_ConsumerControl :: 1;
    kHIDUsage_Csmr_NumericKeyPad :: 2;
    kHIDUsage_Csmr_ProgrammableButtons :: 3;
    kHIDUsage_Csmr_Microphone :: 4;
    kHIDUsage_Csmr_Headphone :: 5;
    kHIDUsage_Csmr_GraphicEqualizer :: 6;
    kHIDUsage_Csmr_Plus10 :: 32;
    kHIDUsage_Csmr_Plus100 :: 33;
    kHIDUsage_Csmr_AMOrPM :: 34;
    kHIDUsage_Csmr_Power :: 48;
    kHIDUsage_Csmr_Reset :: 49;
    kHIDUsage_Csmr_Sleep :: 50;
    kHIDUsage_Csmr_SleepAfter :: 51;
    kHIDUsage_Csmr_SleepMode :: 52;
    kHIDUsage_Csmr_Illumination :: 53;
    kHIDUsage_Csmr_FunctionButtons :: 54;
    kHIDUsage_Csmr_Menu :: 64;
    kHIDUsage_Csmr_MenuPick :: 65;
    kHIDUsage_Csmr_MenuUp :: 66;
    kHIDUsage_Csmr_MenuDown :: 67;
    kHIDUsage_Csmr_MenuLeft :: 68;
    kHIDUsage_Csmr_MenuRight :: 69;
    kHIDUsage_Csmr_MenuEscape :: 70;
    kHIDUsage_Csmr_MenuValueIncrease :: 71;
    kHIDUsage_Csmr_MenuValueDecrease :: 72;
    kHIDUsage_Csmr_DataOnScreen :: 96;
    kHIDUsage_Csmr_ClosedCaption :: 97;
    kHIDUsage_Csmr_ClosedCaptionSelect :: 98;
    kHIDUsage_Csmr_VCROrTV :: 99;
    kHIDUsage_Csmr_BroadcastMode :: 100;
    kHIDUsage_Csmr_Snapshot :: 101;
    kHIDUsage_Csmr_Still :: 102;
    kHIDUsage_Csmr_PictureInPictureToggle :: 103;
    kHIDUsage_Csmr_PictureInPictureSwap :: 104;
    kHIDUsage_Csmr_RedMenuButton :: 105;
    kHIDUsage_Csmr_GreenMenuButton :: 106;
    kHIDUsage_Csmr_BlueMenuButton :: 107;
    kHIDUsage_Csmr_YellowMenuButton :: 108;
    kHIDUsage_Csmr_Aspect :: 109;
    kHIDUsage_Csmr_3DModeSelect :: 110;
    kHIDUsage_Csmr_DisplayBrightnessIncrement :: 111;
    kHIDUsage_Csmr_DisplayBrightnessDecrement :: 112;
    kHIDUsage_Csmr_DisplayBrightness :: 113;
    kHIDUsage_Csmr_DisplayBacklightToggle :: 114;
    kHIDUsage_Csmr_DisplayBrightnessMinimum :: 115;
    kHIDUsage_Csmr_DisplayBrightnessMaximum :: 116;
    kHIDUsage_Csmr_DisplayBrightnessSetAutoBrightness :: 117;
    kHIDUsage_Csmr_Selection :: 128;
    kHIDUsage_Csmr_Assign :: 129;
    kHIDUsage_Csmr_ModeStep :: 130;
    kHIDUsage_Csmr_RecallLast :: 131;
    kHIDUsage_Csmr_EnterChannel :: 132;
    kHIDUsage_Csmr_OrderMovie :: 133;
    kHIDUsage_Csmr_Channel :: 134;
    kHIDUsage_Csmr_MediaSelection :: 135;
    kHIDUsage_Csmr_MediaSelectComputer :: 136;
    kHIDUsage_Csmr_MediaSelectTV :: 137;
    kHIDUsage_Csmr_MediaSelectWWW :: 138;
    kHIDUsage_Csmr_MediaSelectDVD :: 139;
    kHIDUsage_Csmr_MediaSelectTelephone :: 140;
    kHIDUsage_Csmr_MediaSelectProgramGuide :: 141;
    kHIDUsage_Csmr_MediaSelectVideoPhone :: 142;
    kHIDUsage_Csmr_MediaSelectGames :: 143;
    kHIDUsage_Csmr_MediaSelectMessages :: 144;
    kHIDUsage_Csmr_MediaSelectCD :: 145;
    kHIDUsage_Csmr_MediaSelectVCR :: 146;
    kHIDUsage_Csmr_MediaSelectTuner :: 147;
    kHIDUsage_Csmr_Quit :: 148;
    kHIDUsage_Csmr_Help :: 149;
    kHIDUsage_Csmr_MediaSelectTape :: 150;
    kHIDUsage_Csmr_MediaSelectCable :: 151;
    kHIDUsage_Csmr_MediaSelectSatellite :: 152;
    kHIDUsage_Csmr_MediaSelectSecurity :: 153;
    kHIDUsage_Csmr_MediaSelectHome :: 154;
    kHIDUsage_Csmr_MediaSelectCall :: 155;
    kHIDUsage_Csmr_ChannelIncrement :: 156;
    kHIDUsage_Csmr_ChannelDecrement :: 157;
    kHIDUsage_Csmr_Media :: 158;
    kHIDUsage_Csmr_VCRPlus :: 160;
    kHIDUsage_Csmr_Once :: 161;
    kHIDUsage_Csmr_Daily :: 162;
    kHIDUsage_Csmr_Weekly :: 163;
    kHIDUsage_Csmr_Monthly :: 164;
    kHIDUsage_Csmr_Play :: 176;
    kHIDUsage_Csmr_Pause :: 177;
    kHIDUsage_Csmr_Record :: 178;
    kHIDUsage_Csmr_FastForward :: 179;
    kHIDUsage_Csmr_Rewind :: 180;
    kHIDUsage_Csmr_ScanNextTrack :: 181;
    kHIDUsage_Csmr_ScanPreviousTrack :: 182;
    kHIDUsage_Csmr_Stop :: 183;
    kHIDUsage_Csmr_Eject :: 184;
    kHIDUsage_Csmr_RandomPlay :: 185;
    kHIDUsage_Csmr_SelectDisc :: 186;
    kHIDUsage_Csmr_EnterDisc :: 187;
    kHIDUsage_Csmr_Repeat :: 188;
    kHIDUsage_Csmr_Tracking :: 189;
    kHIDUsage_Csmr_TrackNormal :: 190;
    kHIDUsage_Csmr_SlowTracking :: 191;
    kHIDUsage_Csmr_FrameForward :: 192;
    kHIDUsage_Csmr_FrameBack :: 193;
    kHIDUsage_Csmr_Mark :: 194;
    kHIDUsage_Csmr_ClearMark :: 195;
    kHIDUsage_Csmr_RepeatFromMark :: 196;
    kHIDUsage_Csmr_ReturnToMark :: 197;
    kHIDUsage_Csmr_SearchMarkForward :: 198;
    kHIDUsage_Csmr_SearchMarkBackwards :: 199;
    kHIDUsage_Csmr_CounterReset :: 200;
    kHIDUsage_Csmr_ShowCounter :: 201;
    kHIDUsage_Csmr_TrackingIncrement :: 202;
    kHIDUsage_Csmr_TrackingDecrement :: 203;
    kHIDUsage_Csmr_StopOrEject :: 204;
    kHIDUsage_Csmr_PlayOrPause :: 205;
    kHIDUsage_Csmr_PlayOrSkip :: 206;
    kHIDUsage_Csmr_VoiceCommand :: 207;
    kHIDUsage_Csmr_Volume :: 224;
    kHIDUsage_Csmr_Balance :: 225;
    kHIDUsage_Csmr_Mute :: 226;
    kHIDUsage_Csmr_Bass :: 227;
    kHIDUsage_Csmr_Treble :: 228;
    kHIDUsage_Csmr_BassBoost :: 229;
    kHIDUsage_Csmr_SurroundMode :: 230;
    kHIDUsage_Csmr_Loudness :: 231;
    kHIDUsage_Csmr_MPX :: 232;
    kHIDUsage_Csmr_VolumeIncrement :: 233;
    kHIDUsage_Csmr_VolumeDecrement :: 234;
    kHIDUsage_Csmr_Speed :: 240;
    kHIDUsage_Csmr_PlaybackSpeed :: 241;
    kHIDUsage_Csmr_StandardPlay :: 242;
    kHIDUsage_Csmr_LongPlay :: 243;
    kHIDUsage_Csmr_ExtendedPlay :: 244;
    kHIDUsage_Csmr_Slow :: 245;
    kHIDUsage_Csmr_FanEnable :: 256;
    kHIDUsage_Csmr_FanSpeed :: 257;
    kHIDUsage_Csmr_LightEnable :: 258;
    kHIDUsage_Csmr_LightIlluminationLevel :: 259;
    kHIDUsage_Csmr_ClimateControlEnable :: 260;
    kHIDUsage_Csmr_RoomTemperature :: 261;
    kHIDUsage_Csmr_SecurityEnable :: 262;
    kHIDUsage_Csmr_FireAlarm :: 263;
    kHIDUsage_Csmr_PoliceAlarm :: 264;
    kHIDUsage_Csmr_Proximity :: 265;
    kHIDUsage_Csmr_Motion :: 266;
    kHIDUsage_Csmr_DuressAlarm :: 267;
    kHIDUsage_Csmr_HoldupAlarm :: 268;
    kHIDUsage_Csmr_MedicalAlarm :: 269;
    kHIDUsage_Csmr_BalanceRight :: 336;
    kHIDUsage_Csmr_BalanceLeft :: 337;
    kHIDUsage_Csmr_BassIncrement :: 338;
    kHIDUsage_Csmr_BassDecrement :: 339;
    kHIDUsage_Csmr_TrebleIncrement :: 340;
    kHIDUsage_Csmr_TrebleDecrement :: 341;
    kHIDUsage_Csmr_SpeakerSystem :: 352;
    kHIDUsage_Csmr_ChannelLeft :: 353;
    kHIDUsage_Csmr_ChannelRight :: 354;
    kHIDUsage_Csmr_ChannelCenter :: 355;
    kHIDUsage_Csmr_ChannelFront :: 356;
    kHIDUsage_Csmr_ChannelCenterFront :: 357;
    kHIDUsage_Csmr_ChannelSide :: 358;
    kHIDUsage_Csmr_ChannelSurround :: 359;
    kHIDUsage_Csmr_ChannelLowFrequencyEnhancement :: 360;
    kHIDUsage_Csmr_ChannelTop :: 361;
    kHIDUsage_Csmr_ChannelUnknown :: 362;
    kHIDUsage_Csmr_SubChannel :: 368;
    kHIDUsage_Csmr_SubChannelIncrement :: 369;
    kHIDUsage_Csmr_SubChannelDecrement :: 370;
    kHIDUsage_Csmr_AlternateAudioIncrement :: 371;
    kHIDUsage_Csmr_AlternateAudioDecrement :: 372;
    kHIDUsage_Csmr_ApplicationLaunchButtons :: 384;
    kHIDUsage_Csmr_ALLaunchButtonConfigurationTool :: 385;
    kHIDUsage_Csmr_ALProgrammableButtonConfiguration :: 386;
    kHIDUsage_Csmr_ALConsumerControlConfiguration :: 387;
    kHIDUsage_Csmr_ALWordProcessor :: 388;
    kHIDUsage_Csmr_ALTextEditor :: 389;
    kHIDUsage_Csmr_ALSpreadsheet :: 390;
    kHIDUsage_Csmr_ALGraphicsEditor :: 391;
    kHIDUsage_Csmr_ALPresentationApp :: 392;
    kHIDUsage_Csmr_ALDatabaseApp :: 393;
    kHIDUsage_Csmr_ALEmailReader :: 394;
    kHIDUsage_Csmr_ALNewsreader :: 395;
    kHIDUsage_Csmr_ALVoicemail :: 396;
    kHIDUsage_Csmr_ALContactsOrAddressBook :: 397;
    kHIDUsage_Csmr_ALCalendarOrSchedule :: 398;
    kHIDUsage_Csmr_ALTaskOrProjectManager :: 399;
    kHIDUsage_Csmr_ALLogOrJournalOrTimecard :: 400;
    kHIDUsage_Csmr_ALCheckbookOrFinance :: 401;
    kHIDUsage_Csmr_ALCalculator :: 402;
    kHIDUsage_Csmr_ALAOrVCaptureOrPlayback :: 403;
    kHIDUsage_Csmr_ALLocalMachineBrowser :: 404;
    kHIDUsage_Csmr_ALLANOrWANBrowser :: 405;
    kHIDUsage_Csmr_ALInternetBrowser :: 406;
    kHIDUsage_Csmr_ALRemoteNetworkingOrISPConnect :: 407;
    kHIDUsage_Csmr_ALNetworkConference :: 408;
    kHIDUsage_Csmr_ALNetworkChat :: 409;
    kHIDUsage_Csmr_ALTelephonyOrDialer :: 410;
    kHIDUsage_Csmr_ALLogon :: 411;
    kHIDUsage_Csmr_ALLogoff :: 412;
    kHIDUsage_Csmr_ALLogonOrLogoff :: 413;
    kHIDUsage_Csmr_ALTerminalLockOrScreensaver :: 414;
    kHIDUsage_Csmr_ALControlPanel :: 415;
    kHIDUsage_Csmr_ALCommandLineProcessorOrRun :: 416;
    kHIDUsage_Csmr_ALProcessOrTaskManager :: 417;
    kHIDUsage_Csmr_AL :: 418;
    kHIDUsage_Csmr_ALNextTaskOrApplication :: 419;
    kHIDUsage_Csmr_ALPreviousTaskOrApplication :: 420;
    kHIDUsage_Csmr_ALPreemptiveHaltTaskOrApplication :: 421;
    kHIDUsage_Csmr_ALIntegratedHelpCenter :: 422;
    kHIDUsage_Csmr_ALDocuments :: 423;
    kHIDUsage_Csmr_ALThesaurus :: 424;
    kHIDUsage_Csmr_ALDictionary :: 425;
    kHIDUsage_Csmr_ALDesktop :: 426;
    kHIDUsage_Csmr_ALSpellCheck :: 427;
    kHIDUsage_Csmr_ALGrammerCheck :: 428;
    kHIDUsage_Csmr_ALWirelessStatus :: 429;
    kHIDUsage_Csmr_ALKeyboardLayout :: 430;
    kHIDUsage_Csmr_ALVirusProtection :: 431;
    kHIDUsage_Csmr_ALEncryption :: 432;
    kHIDUsage_Csmr_ALScreenSaver :: 433;
    kHIDUsage_Csmr_ALAlarms :: 434;
    kHIDUsage_Csmr_ALClock :: 435;
    kHIDUsage_Csmr_ALFileBrowser :: 436;
    kHIDUsage_Csmr_ALPowerStatus :: 437;
    kHIDUsage_Csmr_ALImageBrowser :: 438;
    kHIDUsage_Csmr_ALAudioBrowser :: 439;
    kHIDUsage_Csmr_ALMovieBrowser :: 440;
    kHIDUsage_Csmr_ALDigitalRightsManager :: 441;
    kHIDUsage_Csmr_ALDigitalWallet :: 442;
    kHIDUsage_Csmr_ALInstantMessaging :: 444;
    kHIDUsage_Csmr_ALOEMFeatureBrowser :: 445;
    kHIDUsage_Csmr_ALOEMHelp :: 446;
    kHIDUsage_Csmr_ALOnlineCommunity :: 447;
    kHIDUsage_Csmr_ALEntertainmentContentBrowser :: 448;
    kHIDUsage_Csmr_ALOnlineShoppingBrowswer :: 449;
    kHIDUsage_Csmr_ALSmartCardInformationOrHelp :: 450;
    kHIDUsage_Csmr_ALMarketMonitorOrFinanceBrowser :: 451;
    kHIDUsage_Csmr_ALCustomizedCorporateNewsBrowser :: 452;
    kHIDUsage_Csmr_ALOnlineActivityBrowswer :: 453;
    kHIDUsage_Csmr_ALResearchOrSearchBrowswer :: 454;
    kHIDUsage_Csmr_ALAudioPlayer :: 455;
    kHIDUsage_Csmr_ALNavigation :: 456;
    kHIDUsage_Csmr_GenericGUIApplicationControls :: 512;
    kHIDUsage_Csmr_ACNew :: 513;
    kHIDUsage_Csmr_ACOpen :: 514;
    kHIDUsage_Csmr_ACClose :: 515;
    kHIDUsage_Csmr_ACExit :: 516;
    kHIDUsage_Csmr_ACMaximize :: 517;
    kHIDUsage_Csmr_ACMinimize :: 518;
    kHIDUsage_Csmr_ACSave :: 519;
    kHIDUsage_Csmr_ACPrint :: 520;
    kHIDUsage_Csmr_ACProperties :: 521;
    kHIDUsage_Csmr_ACUndo :: 538;
    kHIDUsage_Csmr_ACCopy :: 539;
    kHIDUsage_Csmr_ACCut :: 540;
    kHIDUsage_Csmr_ACPaste :: 541;
    kHIDUsage_Csmr_AC :: 542;
    kHIDUsage_Csmr_ACFind :: 543;
    kHIDUsage_Csmr_ACFindandReplace :: 544;
    kHIDUsage_Csmr_ACSearch :: 545;
    kHIDUsage_Csmr_ACGoTo :: 546;
    kHIDUsage_Csmr_ACHome :: 547;
    kHIDUsage_Csmr_ACBack :: 548;
    kHIDUsage_Csmr_ACForward :: 549;
    kHIDUsage_Csmr_ACStop :: 550;
    kHIDUsage_Csmr_ACRefresh :: 551;
    kHIDUsage_Csmr_ACPreviousLink :: 552;
    kHIDUsage_Csmr_ACNextLink :: 553;
    kHIDUsage_Csmr_ACBookmarks :: 554;
    kHIDUsage_Csmr_ACHistory :: 555;
    kHIDUsage_Csmr_ACSubscriptions :: 556;
    kHIDUsage_Csmr_ACZoomIn :: 557;
    kHIDUsage_Csmr_ACZoomOut :: 558;
    kHIDUsage_Csmr_ACZoom :: 559;
    kHIDUsage_Csmr_ACFullScreenView :: 560;
    kHIDUsage_Csmr_ACNormalView :: 561;
    kHIDUsage_Csmr_ACViewToggle :: 562;
    kHIDUsage_Csmr_ACScrollUp :: 563;
    kHIDUsage_Csmr_ACScrollDown :: 564;
    kHIDUsage_Csmr_ACScroll :: 565;
    kHIDUsage_Csmr_ACPanLeft :: 566;
    kHIDUsage_Csmr_ACPanRight :: 567;
    kHIDUsage_Csmr_ACPan :: 568;
    kHIDUsage_Csmr_ACNewWindow :: 569;
    kHIDUsage_Csmr_ACTileHorizontally :: 570;
    kHIDUsage_Csmr_ACTileVertically :: 571;
    kHIDUsage_Csmr_ACFormat :: 572;
    kHIDUsage_Csmr_ACEdit :: 573;
    kHIDUsage_Csmr_ACBold :: 574;
    kHIDUsage_Csmr_ACItalics :: 575;
    kHIDUsage_Csmr_ACUnderline :: 576;
    kHIDUsage_Csmr_ACStrikethrough :: 577;
    kHIDUsage_Csmr_ACSubscript :: 578;
    kHIDUsage_Csmr_ACSuperscript :: 579;
    kHIDUsage_Csmr_ACAllCaps :: 580;
    kHIDUsage_Csmr_ACRotate :: 581;
    kHIDUsage_Csmr_ACResize :: 582;
    kHIDUsage_Csmr_ACFlipHorizontal :: 583;
    kHIDUsage_Csmr_ACFlipVertical :: 584;
    kHIDUsage_Csmr_ACMirrorHorizontal :: 585;
    kHIDUsage_Csmr_ACMirrorVertical :: 586;
    kHIDUsage_Csmr_ACFontSelect :: 587;
    kHIDUsage_Csmr_ACFontColor :: 588;
    kHIDUsage_Csmr_ACFontSize :: 589;
    kHIDUsage_Csmr_ACJustifyLeft :: 590;
    kHIDUsage_Csmr_ACJustifyCenterH :: 591;
    kHIDUsage_Csmr_ACJustifyRight :: 592;
    kHIDUsage_Csmr_ACJustifyBlockH :: 593;
    kHIDUsage_Csmr_ACJustifyTop :: 594;
    kHIDUsage_Csmr_ACJustifyCenterV :: 595;
    kHIDUsage_Csmr_ACJustifyBottom :: 596;
    kHIDUsage_Csmr_ACJustifyBlockV :: 597;
    kHIDUsage_Csmr_ACIndentyDecrease :: 598;
    kHIDUsage_Csmr_ACIndentyIncrease :: 599;
    kHIDUsage_Csmr_ACNumberedList :: 600;
    kHIDUsage_Csmr_ACRestartNumbering :: 601;
    kHIDUsage_Csmr_ACBulletedList :: 602;
    kHIDUsage_Csmr_ACPromote :: 603;
    kHIDUsage_Csmr_ACDemote :: 604;
    kHIDUsage_Csmr_ACYes :: 605;
    kHIDUsage_Csmr_ACNo :: 606;
    kHIDUsage_Csmr_ACCancel :: 607;
    kHIDUsage_Csmr_ACCatalog :: 608;
    kHIDUsage_Csmr_ACBuyOrCheckout :: 609;
    kHIDUsage_Csmr_ACAddToCart :: 610;
    kHIDUsage_Csmr_ACExpand :: 611;
    kHIDUsage_Csmr_ACExpandAll :: 612;
    kHIDUsage_Csmr_ACCollapse :: 613;
    kHIDUsage_Csmr_ACCollapseAll :: 614;
    kHIDUsage_Csmr_ACPrintPreview :: 615;
    kHIDUsage_Csmr_ACPasteSpecial :: 616;
    kHIDUsage_Csmr_ACInsertMode :: 617;
    kHIDUsage_Csmr_ACDelete :: 618;
    kHIDUsage_Csmr_ACLock :: 619;
    kHIDUsage_Csmr_ACUnlock :: 620;
    kHIDUsage_Csmr_ACProtect :: 621;
    kHIDUsage_Csmr_ACUnprotect :: 622;
    kHIDUsage_Csmr_ACAttachComment :: 623;
    kHIDUsage_Csmr_ACDetachComment :: 624;
    kHIDUsage_Csmr_ACViewComment :: 625;
    kHIDUsage_Csmr_ACSelectWord :: 626;
    kHIDUsage_Csmr_ACSelectSentence :: 627;
    kHIDUsage_Csmr_ACSelectParagraph :: 628;
    kHIDUsage_Csmr_ACSelectColumn :: 629;
    kHIDUsage_Csmr_ACSelectRow :: 630;
    kHIDUsage_Csmr_ACSelectTable :: 631;
    kHIDUsage_Csmr_ACSelectObject :: 632;
    kHIDUsage_Csmr_ACRedoOrRepeat :: 633;
    kHIDUsage_Csmr_ACSort :: 634;
    kHIDUsage_Csmr_ACSortAscending :: 635;
    kHIDUsage_Csmr_ACSortDescending :: 636;
    kHIDUsage_Csmr_ACFilter :: 637;
    kHIDUsage_Csmr_ACSetClock :: 638;
    kHIDUsage_Csmr_ACViewClock :: 639;
    kHIDUsage_Csmr_ACSelectTimeZone :: 640;
    kHIDUsage_Csmr_ACEditTimeZones :: 641;
    kHIDUsage_Csmr_ACSetAlarm :: 642;
    kHIDUsage_Csmr_ACClearAlarm :: 643;
    kHIDUsage_Csmr_ACSnoozeAlarm :: 644;
    kHIDUsage_Csmr_ACResetAlarm :: 645;
    kHIDUsage_Csmr_ACSynchronize :: 646;
    kHIDUsage_Csmr_ACSendOrReceive :: 647;
    kHIDUsage_Csmr_ACSendTo :: 648;
    kHIDUsage_Csmr_ACReply :: 649;
    kHIDUsage_Csmr_ACReplyAll :: 650;
    kHIDUsage_Csmr_ACForwardMessage :: 651;
    kHIDUsage_Csmr_ACSend :: 652;
    kHIDUsage_Csmr_ACAttachFile :: 653;
    kHIDUsage_Csmr_ACUpload :: 654;
    kHIDUsage_Csmr_ACDownload :: 655;
    kHIDUsage_Csmr_ACSetBorders :: 656;
    kHIDUsage_Csmr_ACInsertRow :: 657;
    kHIDUsage_Csmr_ACInsertColumn :: 658;
    kHIDUsage_Csmr_ACInsertFile :: 659;
    kHIDUsage_Csmr_ACInsertPicture :: 660;
    kHIDUsage_Csmr_ACInsertObject :: 661;
    kHIDUsage_Csmr_ACInsertSymbol :: 662;
    kHIDUsage_Csmr_ACSaveAndClose :: 663;
    kHIDUsage_Csmr_ACRename :: 664;
    kHIDUsage_Csmr_ACMerge :: 665;
    kHIDUsage_Csmr_ACSplit :: 666;
    kHIDUsage_Csmr_ACDistributeH :: 667;
    kHIDUsage_Csmr_ACDistributeV :: 668;
    kHIDUsage_Csmr_ACKeyboardLayoutSelect :: 669;
    kHIDUsage_Csmr_ACNavigationGuidance :: 670;
    kHIDUsage_Csmr_Reserved :: 65535;
}

using anon_enum_112 :: enum u32 {
    kHIDUsage_Dig_Digitizer :: 1;
    kHIDUsage_Dig_Pen :: 2;
    kHIDUsage_Dig_LightPen :: 3;
    kHIDUsage_Dig_TouchScreen :: 4;
    kHIDUsage_Dig_TouchPad :: 5;
    kHIDUsage_Dig_WhiteBoard :: 6;
    kHIDUsage_Dig_CoordinateMeasuringMachine :: 7;
    kHIDUsage_Dig_3DDigitizer :: 8;
    kHIDUsage_Dig_StereoPlotter :: 9;
    kHIDUsage_Dig_ArticulatedArm :: 10;
    kHIDUsage_Dig_Armature :: 11;
    kHIDUsage_Dig_MultiplePointDigitizer :: 12;
    kHIDUsage_Dig_FreeSpaceWand :: 13;
    kHIDUsage_Dig_DeviceConfiguration :: 14;
    kHIDUsage_Dig_Stylus :: 32;
    kHIDUsage_Dig_Puck :: 33;
    kHIDUsage_Dig_Finger :: 34;
    kHIDUsage_Dig_DeviceSettings :: 35;
    kHIDUsage_Dig_GestureCharacter :: 36;
    kHIDUsage_Dig_TipPressure :: 48;
    kHIDUsage_Dig_BarrelPressure :: 49;
    kHIDUsage_Dig_InRange :: 50;
    kHIDUsage_Dig_Touch :: 51;
    kHIDUsage_Dig_Untouch :: 52;
    kHIDUsage_Dig_Tap :: 53;
    kHIDUsage_Dig_Quality :: 54;
    kHIDUsage_Dig_DataValid :: 55;
    kHIDUsage_Dig_TransducerIndex :: 56;
    kHIDUsage_Dig_TabletFunctionKeys :: 57;
    kHIDUsage_Dig_ProgramChangeKeys :: 58;
    kHIDUsage_Dig_BatteryStrength :: 59;
    kHIDUsage_Dig_Invert :: 60;
    kHIDUsage_Dig_XTilt :: 61;
    kHIDUsage_Dig_YTilt :: 62;
    kHIDUsage_Dig_Azimuth :: 63;
    kHIDUsage_Dig_Altitude :: 64;
    kHIDUsage_Dig_Twist :: 65;
    kHIDUsage_Dig_TipSwitch :: 66;
    kHIDUsage_Dig_SecondaryTipSwitch :: 67;
    kHIDUsage_Dig_BarrelSwitch :: 68;
    kHIDUsage_Dig_Eraser :: 69;
    kHIDUsage_Dig_TabletPick :: 70;
    kHIDUsage_Dig_TouchValid :: 71;
    kHIDUsage_Dig_Width :: 72;
    kHIDUsage_Dig_Height :: 73;
    kHIDUsage_Dig_ContactIdentifier :: 81;
    kHIDUsage_Dig_DeviceMode :: 82;
    kHIDUsage_Dig_DeviceIdentifier :: 83;
    kHIDUsage_Dig_ContactCount :: 84;
    kHIDUsage_Dig_ContactCountMaximum :: 85;
    kHIDUsage_Dig_GestureCharacterEnable :: 96;
    kHIDUsage_Dig_GestureCharacterQuality :: 97;
    kHIDUsage_Dig_GestureCharacterDataLength :: 98;
    kHIDUsage_Dig_GestureCharacterData :: 99;
    kHIDUsage_Dig_GestureCharacterEncoding :: 100;
    kHIDUsage_Dig_GestureCharacterEncodingUTF8 :: 101;
    kHIDUsage_Dig_GestureCharacterEncodingUTF16LE :: 102;
    kHIDUsage_Dig_GestureCharacterEncodingUTF16BE :: 103;
    kHIDUsage_Dig_GestureCharacterEncodingUTF32LE :: 104;
    kHIDUsage_Dig_GestureCharacterEncodingUTF32BE :: 105;
    kHIDUsage_Dig_Reserved :: 65535;
}

using anon_enum_113 :: enum u32 {
    kHIDUsage_PID_PhysicalInterfaceDevice :: 1;
    kHIDUsage_PID_Normal :: 32;
    kHIDUsage_PID_SetEffectReport :: 33;
    kHIDUsage_PID_EffectBlockIndex :: 34;
    kHIDUsage_PID_ParamBlockOffset :: 35;
    kHIDUsage_PID_ROM_Flag :: 36;
    kHIDUsage_PID_EffectType :: 37;
    kHIDUsage_PID_ET_ConstantForce :: 38;
    kHIDUsage_PID_ET_Ramp :: 39;
    kHIDUsage_PID_ET_CustomForceData :: 40;
    kHIDUsage_PID_ET_Square :: 48;
    kHIDUsage_PID_ET_Sine :: 49;
    kHIDUsage_PID_ET_Triangle :: 50;
    kHIDUsage_PID_ET_SawtoothUp :: 51;
    kHIDUsage_PID_ET_SawtoothDown :: 52;
    kHIDUsage_PID_ET_Spring :: 64;
    kHIDUsage_PID_ET_Damper :: 65;
    kHIDUsage_PID_ET_Inertia :: 66;
    kHIDUsage_PID_ET_Friction :: 67;
    kHIDUsage_PID_Duration :: 80;
    kHIDUsage_PID_SamplePeriod :: 81;
    kHIDUsage_PID_Gain :: 82;
    kHIDUsage_PID_TriggerButton :: 83;
    kHIDUsage_PID_TriggerRepeatInterval :: 84;
    kHIDUsage_PID_AxesEnable :: 85;
    kHIDUsage_PID_DirectionEnable :: 86;
    kHIDUsage_PID_Direction :: 87;
    kHIDUsage_PID_TypeSpecificBlockOffset :: 88;
    kHIDUsage_PID_BlockType :: 89;
    kHIDUsage_PID_SetEnvelopeReport :: 90;
    kHIDUsage_PID_AttackLevel :: 91;
    kHIDUsage_PID_AttackTime :: 92;
    kHIDUsage_PID_FadeLevel :: 93;
    kHIDUsage_PID_FadeTime :: 94;
    kHIDUsage_PID_SetConditionReport :: 95;
    kHIDUsage_PID_CP_Offset :: 96;
    kHIDUsage_PID_PositiveCoefficient :: 97;
    kHIDUsage_PID_NegativeCoefficient :: 98;
    kHIDUsage_PID_PositiveSaturation :: 99;
    kHIDUsage_PID_NegativeSaturation :: 100;
    kHIDUsage_PID_DeadBand :: 101;
    kHIDUsage_PID_DownloadForceSample :: 102;
    kHIDUsage_PID_IsochCustomForceEnable :: 103;
    kHIDUsage_PID_CustomForceDataReport :: 104;
    kHIDUsage_PID_CustomForceData :: 105;
    kHIDUsage_PID_CustomForceVendorDefinedData :: 106;
    kHIDUsage_PID_SetCustomForceReport :: 107;
    kHIDUsage_PID_CustomForceDataOffset :: 108;
    kHIDUsage_PID_SampleCount :: 109;
    kHIDUsage_PID_SetPeriodicReport :: 110;
    kHIDUsage_PID_Offset :: 111;
    kHIDUsage_PID_Magnitude :: 112;
    kHIDUsage_PID_Phase :: 113;
    kHIDUsage_PID_Period :: 114;
    kHIDUsage_PID_SetConstantForceReport :: 115;
    kHIDUsage_PID_SetRampForceReport :: 116;
    kHIDUsage_PID_RampStart :: 117;
    kHIDUsage_PID_RampEnd :: 118;
    kHIDUsage_PID_EffectOperationReport :: 119;
    kHIDUsage_PID_EffectOperation :: 120;
    kHIDUsage_PID_OpEffectStart :: 121;
    kHIDUsage_PID_OpEffectStartSolo :: 122;
    kHIDUsage_PID_OpEffectStop :: 123;
    kHIDUsage_PID_LoopCount :: 124;
    kHIDUsage_PID_DeviceGainReport :: 125;
    kHIDUsage_PID_DeviceGain :: 126;
    kHIDUsage_PID_PoolReport :: 127;
    kHIDUsage_PID_RAM_PoolSize :: 128;
    kHIDUsage_PID_ROM_PoolSize :: 129;
    kHIDUsage_PID_ROM_EffectBlockCount :: 130;
    kHIDUsage_PID_SimultaneousEffectsMax :: 131;
    kHIDUsage_PID_PoolAlignment :: 132;
    kHIDUsage_PID_PoolMoveReport :: 133;
    kHIDUsage_PID_MoveSource :: 134;
    kHIDUsage_PID_MoveDestination :: 135;
    kHIDUsage_PID_MoveLength :: 136;
    kHIDUsage_PID_BlockLoadReport :: 137;
    kHIDUsage_PID_BlockLoadStatus :: 139;
    kHIDUsage_PID_BlockLoadSuccess :: 140;
    kHIDUsage_PID_BlockLoadFull :: 141;
    kHIDUsage_PID_BlockLoadError :: 142;
    kHIDUsage_PID_BlockHandle :: 143;
    kHIDUsage_PID_BlockFreeReport :: 144;
    kHIDUsage_PID_TypeSpecificBlockHandle :: 145;
    kHIDUsage_PID_StateReport :: 146;
    kHIDUsage_PID_EffectPlaying :: 148;
    kHIDUsage_PID_DeviceControlReport :: 149;
    kHIDUsage_PID_DeviceControl :: 150;
    kHIDUsage_PID_DC_EnableActuators :: 151;
    kHIDUsage_PID_DC_DisableActuators :: 152;
    kHIDUsage_PID_DC_StopAllEffects :: 153;
    kHIDUsage_PID_DC_DeviceReset :: 154;
    kHIDUsage_PID_DC_DevicePause :: 155;
    kHIDUsage_PID_DC_DeviceContinue :: 156;
    kHIDUsage_PID_DevicePaused :: 159;
    kHIDUsage_PID_ActuatorsEnabled :: 160;
    kHIDUsage_PID_SafetySwitch :: 164;
    kHIDUsage_PID_ActuatorOverrideSwitch :: 165;
    kHIDUsage_PID_ActuatorPower :: 166;
    kHIDUsage_PID_StartDelay :: 167;
    kHIDUsage_PID_ParameterBlockSize :: 168;
    kHIDUsage_PID_DeviceManagedPool :: 169;
    kHIDUsage_PID_SharedParameterBlocks :: 170;
    kHIDUsage_PID_CreateNewEffectReport :: 171;
    kHIDUsage_PID_RAM_PoolAvailable :: 172;
    kHIDUsage_PID_Reserved :: 65535;
}

using anon_enum_114 :: enum u32 {
    kHIDUsage_AD_AlphanumericDisplay :: 1;
    kHIDUsage_AD_DisplayAttributesReport :: 32;
    kHIDUsage_AD_ASCIICharacterSet :: 33;
    kHIDUsage_AD_DataReadBack :: 34;
    kHIDUsage_AD_FontReadBack :: 35;
    kHIDUsage_AD_DisplayControlReport :: 36;
    kHIDUsage_AD_ClearDisplay :: 37;
    kHIDUsage_AD_DisplayEnable :: 38;
    kHIDUsage_AD_ScreenSaverDelay :: 39;
    kHIDUsage_AD_ScreenSaverEnable :: 40;
    kHIDUsage_AD_VerticalScroll :: 41;
    kHIDUsage_AD_HorizontalScroll :: 42;
    kHIDUsage_AD_CharacterReport :: 43;
    kHIDUsage_AD_DisplayData :: 44;
    kHIDUsage_AD_DisplayStatus :: 45;
    kHIDUsage_AD_StatNotReady :: 46;
    kHIDUsage_AD_StatReady :: 47;
    kHIDUsage_AD_ErrNotaloadablecharacter :: 48;
    kHIDUsage_AD_ErrFontdatacannotberead :: 49;
    kHIDUsage_AD_CursorPositionReport :: 50;
    kHIDUsage_AD_Row :: 51;
    kHIDUsage_AD_Column :: 52;
    kHIDUsage_AD_Rows :: 53;
    kHIDUsage_AD_Columns :: 54;
    kHIDUsage_AD_CursorPixelPositioning :: 55;
    kHIDUsage_AD_CursorMode :: 56;
    kHIDUsage_AD_CursorEnable :: 57;
    kHIDUsage_AD_CursorBlink :: 58;
    kHIDUsage_AD_FontReport :: 59;
    kHIDUsage_AD_FontData :: 60;
    kHIDUsage_AD_CharacterWidth :: 61;
    kHIDUsage_AD_CharacterHeight :: 62;
    kHIDUsage_AD_CharacterSpacingHorizontal :: 63;
    kHIDUsage_AD_CharacterSpacingVertical :: 64;
    kHIDUsage_AD_UnicodeCharacterSet :: 65;
    kHIDUsage_AD_Reserved :: 65535;
}

using anon_enum_115 :: enum u32 {
    kHIDUsage_Snsr_Undefined :: 0;
    kHIDUsage_Snsr_Sensor :: 1;
    kHIDUsage_Snsr_Biometric :: 16;
    kHIDUsage_Snsr_Biometric_HumanPresence :: 17;
    kHIDUsage_Snsr_Biometric_HumanProximity :: 18;
    kHIDUsage_Snsr_Biometric_HumanTouch :: 19;
    kHIDUsage_Snsr_Electrical :: 32;
    kHIDUsage_Snsr_Electrical_Capacitance :: 33;
    kHIDUsage_Snsr_Electrical_Current :: 34;
    kHIDUsage_Snsr_Electrical_Power :: 35;
    kHIDUsage_Snsr_Electrical_Inductance :: 36;
    kHIDUsage_Snsr_Electrical_Resistance :: 37;
    kHIDUsage_Snsr_Electrical_Voltage :: 38;
    kHIDUsage_Snsr_Electrical_Potentiometer :: 39;
    kHIDUsage_Snsr_Electrical_Frequency :: 40;
    kHIDUsage_Snsr_Electrical_Period :: 41;
    kHIDUsage_Snsr_Environmental :: 48;
    kHIDUsage_Snsr_Environmental_AtmosphericPressure :: 49;
    kHIDUsage_Snsr_Environmental_Humidity :: 50;
    kHIDUsage_Snsr_Environmental_Temperature :: 51;
    kHIDUsage_Snsr_Environmental_WindDirection :: 52;
    kHIDUsage_Snsr_Environmental_WindSpeed :: 53;
    kHIDUsage_Snsr_Light :: 64;
    kHIDUsage_Snsr_Light_AmbientLight :: 65;
    kHIDUsage_Snsr_Light_ConsumerInfrared :: 66;
    kHIDUsage_Snsr_Location :: 80;
    kHIDUsage_Snsr_Location_Broadcast :: 81;
    kHIDUsage_Snsr_Location_DeadReckoning :: 82;
    kHIDUsage_Snsr_Location_GPS :: 83;
    kHIDUsage_Snsr_Location_Lookup :: 84;
    kHIDUsage_Snsr_Location_Other :: 85;
    kHIDUsage_Snsr_Location_Static :: 86;
    kHIDUsage_Snsr_Location_Triangulation :: 87;
    kHIDUsage_Snsr_Mechanical :: 96;
    kHIDUsage_Snsr_Mechanical_BooleanSwitch :: 97;
    kHIDUsage_Snsr_Mechanical_BooleanSwitchArray :: 98;
    kHIDUsage_Snsr_Mechanical_MultivalueSwitch :: 99;
    kHIDUsage_Snsr_Mechanical_Force :: 100;
    kHIDUsage_Snsr_Mechanical_Pressure :: 101;
    kHIDUsage_Snsr_Mechanical_Strain :: 102;
    kHIDUsage_Snsr_Mechanical_Weight :: 103;
    kHIDUsage_Snsr_Mechanical_HapticVibrator :: 104;
    kHIDUsage_Snsr_Mechanical_HallEffectSwitch :: 105;
    kHIDUsage_Snsr_Motion :: 112;
    kHIDUsage_Snsr_Motion_Accelerometer1D :: 113;
    kHIDUsage_Snsr_Motion_Accelerometer2D :: 114;
    kHIDUsage_Snsr_Motion_Accelerometer3D :: 115;
    kHIDUsage_Snsr_Motion_Gyrometer1D :: 116;
    kHIDUsage_Snsr_Motion_Gyrometer2D :: 117;
    kHIDUsage_Snsr_Motion_Gyrometer3D :: 118;
    kHIDUsage_Snsr_Motion_MotionDetector :: 119;
    kHIDUsage_Snsr_Motion_Speedometer :: 120;
    kHIDUsage_Snsr_Motion_Accelerometer :: 121;
    kHIDUsage_Snsr_Motion_Gyrometer :: 122;
    kHIDUsage_Snsr_Orientation :: 128;
    kHIDUsage_Snsr_Orientation_Compass1D :: 129;
    kHIDUsage_Snsr_Orientation_Compass2D :: 130;
    kHIDUsage_Snsr_Orientation_Compass3D :: 131;
    kHIDUsage_Snsr_Orientation_Inclinometer1D :: 132;
    kHIDUsage_Snsr_Orientation_Inclinometer2D :: 133;
    kHIDUsage_Snsr_Orientation_Inclinometer3D :: 134;
    kHIDUsage_Snsr_Orientation_Distance1D :: 135;
    kHIDUsage_Snsr_Orientation_Distance2D :: 136;
    kHIDUsage_Snsr_Orientation_Distance3D :: 137;
    kHIDUsage_Snsr_Orientation_DeviceOrientation :: 138;
    kHIDUsage_Snsr_Orientation_CompassD :: 139;
    kHIDUsage_Snsr_Orientation_InclinometerD :: 140;
    kHIDUsage_Snsr_Orientation_DistanceD :: 141;
    kHIDUsage_Snsr_Scanner :: 144;
    kHIDUsage_Snsr_Scanner_Barcode :: 145;
    kHIDUsage_Snsr_Scanner_RFID :: 146;
    kHIDUsage_Snsr_Scanner_NFC :: 147;
    kHIDUsage_Snsr_Time :: 160;
    kHIDUsage_Snsr_Time_AlarmTimer :: 161;
    kHIDUsage_Snsr_Time_RealTimeClock :: 162;
    kHIDUsage_Snsr_Other :: 224;
    kHIDUsage_Snsr_Other_Custom :: 225;
    kHIDUsage_Snsr_Other_Generic :: 226;
    kHIDUsage_Snsr_Other_GenericEnumerator :: 227;
    kHIDUsage_Snsr_Modifier_None :: 0;
    kHIDUsage_Snsr_Modifier_ChangeSensitivityAbsolute :: 1;
    kHIDUsage_Snsr_Modifier_Max :: 2;
    kHIDUsage_Snsr_Modifier_Min :: 3;
    kHIDUsage_Snsr_Modifier_Accuracy :: 4;
    kHIDUsage_Snsr_Modifier_Resolution :: 5;
    kHIDUsage_Snsr_Modifier_ThresholdHigh :: 6;
    kHIDUsage_Snsr_Modifier_ThresholdLow :: 7;
    kHIDUsage_Snsr_Modifier_CalibrationOffset :: 8;
    kHIDUsage_Snsr_Modifier_CalibrationMultiplier :: 9;
    kHIDUsage_Snsr_Modifier_ReportInterval :: 10;
    kHIDUsage_Snsr_Modifier_FrequencyMax :: 11;
    kHIDUsage_Snsr_Modifier_PeriodMax :: 12;
    kHIDUsage_Snsr_Modifier_ChangeSensitivityPercentRange :: 13;
    kHIDUsage_Snsr_Modifier_ChangeSensitivityPercentRelative :: 14;
    kHIDUsage_Snsr_Modifier_VendorDefined :: 15;
    kHIDUsage_Snsr_Event :: 512;
    kHIDUsage_Snsr_Event_SensorState :: 513;
    kHIDUsage_Snsr_Event_SensorEvent :: 514;
    kHIDUsage_Snsr_Event_SensorState_Undefined :: 2048;
    kHIDUsage_Snsr_Event_SensorState_Ready :: 2049;
    kHIDUsage_Snsr_Event_SensorState_NotAvailable :: 2050;
    kHIDUsage_Snsr_Event_SensorState_NoData :: 2051;
    kHIDUsage_Snsr_Event_SensorState_Initializing :: 2052;
    kHIDUsage_Snsr_Event_SensorState_AccessDenied :: 2053;
    kHIDUsage_Snsr_Event_SensorState_Error :: 2054;
    kHIDUsage_Snsr_Event_SensorEvent_Unknown :: 2064;
    kHIDUsage_Snsr_Event_SensorEvent_StateChanged :: 2065;
    kHIDUsage_Snsr_Event_SensorEvent_PropertyChanged :: 2066;
    kHIDUsage_Snsr_Event_SensorEvent_DataUpdated :: 2067;
    kHIDUsage_Snsr_Event_SensorEvent_PollResponse :: 2068;
    kHIDUsage_Snsr_Event_SensorEvent_ChangeSensitivity :: 2069;
    kHIDUsage_Snsr_Event_SensorEvent_RangeMaxReached :: 2070;
    kHIDUsage_Snsr_Event_SensorEvent_RangeMinReached :: 2071;
    kHIDUsage_Snsr_Event_SensorEvent_HighThresholdCrossUp :: 2072;
    kHIDUsage_Snsr_Event_SensorEvent_HighThresholdCrossDown :: 2073;
    kHIDUsage_Snsr_Event_SensorEvent_LowThresholdCrossUp :: 2074;
    kHIDUsage_Snsr_Event_SensorEvent_LowThresholdCrossDown :: 2075;
    kHIDUsage_Snsr_Event_SensorEvent_ZeroThresholdCrossUp :: 2076;
    kHIDUsage_Snsr_Event_SensorEvent_ZeroThresholdCrossDown :: 2077;
    kHIDUsage_Snsr_Event_SensorEvent_PeriodExceeded :: 2078;
    kHIDUsage_Snsr_Event_SensorEvent_FrequencyExceeded :: 2079;
    kHIDUsage_Snsr_Event_SensorEvent_ComplexTrigger :: 2080;
    kHIDUsage_Snsr_Property :: 768;
    kHIDUsage_Snsr_Property_FriendlyName :: 769;
    kHIDUsage_Snsr_Property_PersistentUniqueID :: 770;
    kHIDUsage_Snsr_Property_SensorStatus :: 771;
    kHIDUsage_Snsr_Property_MinimumReportInterval :: 772;
    kHIDUsage_Snsr_Property_Manufacturer :: 773;
    kHIDUsage_Snsr_Property_Model :: 774;
    kHIDUsage_Snsr_Property_SerialNumber :: 775;
    kHIDUsage_Snsr_Property_Description :: 776;
    kHIDUsage_Snsr_Property_ConnectionType :: 777;
    kHIDUsage_Snsr_Property_DevicePath :: 778;
    kHIDUsage_Snsr_Property_HardwareRevision :: 779;
    kHIDUsage_Snsr_Property_FirmwareVersion :: 780;
    kHIDUsage_Snsr_Property_ReleaseData :: 781;
    kHIDUsage_Snsr_Property_ReportInterval :: 782;
    kHIDUsage_Snsr_Property_ChangeSensitivityAbsolute :: 783;
    kHIDUsage_Snsr_Property_ChangeSensitivityPercentRange :: 784;
    kHIDUsage_Snsr_Property_ChangeSensitivityPercentRelative :: 785;
    kHIDUsage_Snsr_Property_Accuracy :: 786;
    kHIDUsage_Snsr_Property_Resolution :: 787;
    kHIDUsage_Snsr_Property_Maximum :: 788;
    kHIDUsage_Snsr_Property_Minimum :: 789;
    kHIDUsage_Snsr_Property_ReportingState :: 790;
    kHIDUsage_Snsr_Property_SamplingRate :: 791;
    kHIDUsage_Snsr_Property_ResponseCurve :: 792;
    kHIDUsage_Snsr_Property_PowerState :: 793;
    kHIDUsage_Snsr_Property_ConnectionType_Integrated :: 2096;
    kHIDUsage_Snsr_Property_ConnectionType_Attached :: 2097;
    kHIDUsage_Snsr_Property_ConnectionType_External :: 2098;
    kHIDUsage_Snsr_Property_ReportingState_NoEvents :: 2112;
    kHIDUsage_Snsr_Property_ReportingState_AllEvents :: 2113;
    kHIDUsage_Snsr_Property_ReportingState_ThresholdEvents :: 2114;
    kHIDUsage_Snsr_Property_ReportingState_WakeNoEvents :: 2115;
    kHIDUsage_Snsr_Property_ReportingState_WakeAllEvents :: 2116;
    kHIDUsage_Snsr_Property_ReportingState_WakeThresholdEvents :: 2117;
    kHIDUsage_Snsr_Property_PowerState_Undefined :: 2128;
    kHIDUsage_Snsr_Property_PowerState_D0_FullPower :: 2129;
    kHIDUsage_Snsr_Property_PowerState_D1_LowPower :: 2130;
    kHIDUsage_Snsr_Property_PowerState_D2_Standby :: 2131;
    kHIDUsage_Snsr_Property_PowerState_D3_Sleep :: 2132;
    kHIDUsage_Snsr_Property_PowerState_D4_PowerOff :: 2133;
    kHIDUsage_Snsr_Light_Illuminance :: 1233;
    kHIDUsage_Snsr_Data_Location :: 1024;
    kHIDUsage_Snsr_Data_Location_Reserved :: 1025;
    kHIDUsage_Snsr_Data_Location_AltitudeAntennaSeaLevel :: 1026;
    kHIDUsage_Snsr_Data_Location_DifferentialReferenceStationID :: 1027;
    kHIDUsage_Snsr_Data_Location_AltitudeEllipsoidError :: 1028;
    kHIDUsage_Snsr_Data_Location_AltitudeEllipsoid :: 1029;
    kHIDUsage_Snsr_Data_Location_AltitudeSeaLevelError :: 1030;
    kHIDUsage_Snsr_Data_Location_AltitudeSeaLevel :: 1031;
    kHIDUsage_Snsr_Data_Location_DifferentialGPSDataAge :: 1032;
    kHIDUsage_Snsr_Data_Location_ErrorRadius :: 1033;
    kHIDUsage_Snsr_Data_Location_FixQuality :: 1034;
    kHIDUsage_Snsr_Data_Location_FixQualityNoFix :: 2160;
    kHIDUsage_Snsr_Data_Location_FixQualityGPS :: 2161;
    kHIDUsage_Snsr_Data_Location_FixQualityDGPS :: 2162;
    kHIDUsage_Snsr_Data_Location_FixType :: 1035;
    kHIDUsage_Snsr_Data_Location_FixTypeNoFix :: 2176;
    kHIDUsage_Snsr_Data_Location_FixTypeGPSSPSMode :: 2177;
    kHIDUsage_Snsr_Data_Location_FixTypeDGPSSPSMode :: 2178;
    kHIDUsage_Snsr_Data_Location_FixTypeGPSPPSMode :: 2179;
    kHIDUsage_Snsr_Data_Location_FixTypeRealTimeKinematic :: 2180;
    kHIDUsage_Snsr_Data_Location_FixTypeFloatRTK :: 2181;
    kHIDUsage_Snsr_Data_Location_FixTypeEstimated :: 2182;
    kHIDUsage_Snsr_Data_Location_FixTypeManualInputMode :: 2183;
    kHIDUsage_Snsr_Data_Location_FixTypeSimulatorMode :: 2184;
    kHIDUsage_Snsr_Data_Location_GeoidalSeparation :: 1036;
    kHIDUsage_Snsr_Data_Location_GPSOperationMode :: 1037;
    kHIDUsage_Snsr_Data_Location_GPSOperationModeManual :: 2192;
    kHIDUsage_Snsr_Data_Location_GPSOperationModeAutomatic :: 2193;
    kHIDUsage_Snsr_Data_Location_GPSSelectionMode :: 1038;
    kHIDUsage_Snsr_Data_Location_GPSSelectionModeAutonomous :: 2208;
    kHIDUsage_Snsr_Data_Location_GPSSelectionModeDGPS :: 2209;
    kHIDUsage_Snsr_Data_Location_GPSSelectionModeEstimated :: 2210;
    kHIDUsage_Snsr_Data_Location_GPSSelectionModeManualInput :: 2211;
    kHIDUsage_Snsr_Data_Location_GPSSelectionModeSimulator :: 2212;
    kHIDUsage_Snsr_Data_Location_GPSSelectionModeDataNotValid :: 2213;
    kHIDUsage_Snsr_Data_Location_GPSStatus :: 1039;
    kHIDUsage_Snsr_Data_Location_GPSStatusDataValid :: 2224;
    kHIDUsage_Snsr_Data_Location_GPSStatusDataNotValid :: 2225;
    kHIDUsage_Snsr_Data_Location_PositionDilutionOfPrecision :: 1040;
    kHIDUsage_Snsr_Data_Location_HorizontalDilutionOfPrecision :: 1041;
    kHIDUsage_Snsr_Data_Location_VerticalDilutionOfPrecision :: 1042;
    kHIDUsage_Snsr_Data_Location_Latitude :: 1043;
    kHIDUsage_Snsr_Data_Location_Longitude :: 1044;
    kHIDUsage_Snsr_Data_Location_TrueHeading :: 1045;
    kHIDUsage_Snsr_Data_Location_MagneticHeading :: 1046;
    kHIDUsage_Snsr_Data_Location_MagneticVariation :: 1047;
    kHIDUsage_Snsr_Data_Location_Speed :: 1048;
    kHIDUsage_Snsr_Data_Location_SatellitesInView :: 1049;
    kHIDUsage_Snsr_Data_Location_SatellitesInViewAzimuth :: 1050;
    kHIDUsage_Snsr_Data_Location_SatellitesInViewElevation :: 1051;
    kHIDUsage_Snsr_Data_Location_SatellitesInViewIDs :: 1052;
    kHIDUsage_Snsr_Data_Location_SatellitesInViewPRNs :: 1053;
    kHIDUsage_Snsr_Data_Location_SatellitesInViewSNRatios :: 1054;
    kHIDUsage_Snsr_Data_Location_SatellitesUsedCount :: 1055;
    kHIDUsage_Snsr_Data_Location_SatellitesUsedPRNs :: 1056;
    kHIDUsage_Snsr_Data_Location_NMEASentence :: 1057;
    kHIDUsage_Snsr_Data_Location_AddressLine1 :: 1058;
    kHIDUsage_Snsr_Data_Location_AddressLine2 :: 1059;
    kHIDUsage_Snsr_Data_Location_City :: 1060;
    kHIDUsage_Snsr_Data_Location_StateOrProvince :: 1061;
    kHIDUsage_Snsr_Data_Location_CountryOrRegion :: 1062;
    kHIDUsage_Snsr_Data_Location_PostalCode :: 1063;
    kHIDUsage_Snsr_Property_Location :: 1066;
    kHIDUsage_Snsr_Property_Location_DesiredAccuracy :: 1067;
    kHIDUsage_Snsr_Property_Location_AccuracyDefault :: 2144;
    kHIDUsage_Snsr_Property_Location_AccuracyHigh :: 2145;
    kHIDUsage_Snsr_Property_Location_AccuracyMedium :: 2146;
    kHIDUsage_Snsr_Property_Location_AccuracyLow :: 2147;
    kHIDUsage_Snsr_Data_Environmental :: 1072;
    kHIDUsage_Snsr_Data_Environmental_AtmosphericPressure :: 1073;
    kHIDUsage_Snsr_Data_Environmental_Reserved :: 1074;
    kHIDUsage_Snsr_Data_Environmental_RelativeHumidity :: 1075;
    kHIDUsage_Snsr_Data_Environmental_Temperature :: 1076;
    kHIDUsage_Snsr_Data_Environmental_WindDirection :: 1077;
    kHIDUsage_Snsr_Data_Environmental_WindSpeed :: 1078;
    kHIDUsage_Snsr_Property_Environmental :: 1088;
    kHIDUsage_Snsr_Property_Environmental_ReferencePressure :: 1089;
    kHIDUsage_Snsr_Data_Motion :: 1104;
    kHIDUsage_Snsr_Data_Motion_State :: 1105;
    kHIDUsage_Snsr_Data_Motion_Acceleration :: 1106;
    kHIDUsage_Snsr_Data_Motion_AccelerationAxisX :: 1107;
    kHIDUsage_Snsr_Data_Motion_AccelerationAxisY :: 1108;
    kHIDUsage_Snsr_Data_Motion_AccelerationAxisZ :: 1109;
    kHIDUsage_Snsr_Data_Motion_AngularVelocity :: 1110;
    kHIDUsage_Snsr_Data_Motion_AngularVelocityXAxis :: 1111;
    kHIDUsage_Snsr_Data_Motion_AngularVelocityYAxis :: 1112;
    kHIDUsage_Snsr_Data_Motion_AngularVelocityZAxis :: 1113;
    kHIDUsage_Snsr_Data_Motion_AngularPosition :: 1114;
    kHIDUsage_Snsr_Data_Motion_AngularPositionXAxis :: 1115;
    kHIDUsage_Snsr_Data_Motion_AngularPositionYAxis :: 1116;
    kHIDUsage_Snsr_Data_Motion_AngularPositionZAxis :: 1117;
    kHIDUsage_Snsr_Data_Motion_Speed :: 1118;
    kHIDUsage_Snsr_Data_Motion_Intensity :: 1119;
    kHIDUsage_Snsr_Data_Orientation :: 1136;
    kHIDUsage_Snsr_Data_Orientation_Heading :: 1137;
    kHIDUsage_Snsr_Data_Orientation_HeadingXAxis :: 1138;
    kHIDUsage_Snsr_Data_Orientation_HeadingYAxis :: 1139;
    kHIDUsage_Snsr_Data_Orientation_HeadingZAxis :: 1140;
    kHIDUsage_Snsr_Data_Orientation_HeadingCompensatedMagneticNorth :: 1141;
    kHIDUsage_Snsr_Data_Orientation_HeadingCompensatedTrueNorth :: 1142;
    kHIDUsage_Snsr_Data_Orientation_HeadingMagneticNorth :: 1143;
    kHIDUsage_Snsr_Data_Orientation_HeadingTrueNorth :: 1144;
    kHIDUsage_Snsr_Data_Orientation_Distance :: 1145;
    kHIDUsage_Snsr_Data_Orientation_DistanceXAxis :: 1146;
    kHIDUsage_Snsr_Data_Orientation_DistanceYAxis :: 1147;
    kHIDUsage_Snsr_Data_Orientation_DistanceZAxis :: 1148;
    kHIDUsage_Snsr_Data_Orientation_DistanceOutOfRange :: 1149;
    kHIDUsage_Snsr_Data_Orientation_Tilt :: 1150;
    kHIDUsage_Snsr_Data_Orientation_TiltXAxis :: 1151;
    kHIDUsage_Snsr_Data_Orientation_TiltYAxis :: 1152;
    kHIDUsage_Snsr_Data_Orientation_TiltZAxis :: 1153;
    kHIDUsage_Snsr_Data_Orientation_RotationMatrix :: 1154;
    kHIDUsage_Snsr_Data_Orientation_Quaternion :: 1155;
    kHIDUsage_Snsr_Data_Orientation_MagneticFlux :: 1156;
    kHIDUsage_Snsr_Data_Orientation_MagneticFluxXAxis :: 1157;
    kHIDUsage_Snsr_Data_Orientation_MagneticFluxYAxis :: 1158;
    kHIDUsage_Snsr_Data_Orientation_MagneticFluxZAxis :: 1159;
    kHIDUsage_Snsr_Data_Mechanical :: 1168;
    kHIDUsage_Snsr_Data_Mechanical_BooleanSwitchState :: 1169;
    kHIDUsage_Snsr_Data_Mechanical_BooleanSwitchArrayStates :: 1170;
    kHIDUsage_Snsr_Data_Mechanical_MultivalueSwitchValue :: 1171;
    kHIDUsage_Snsr_Data_Mechanical_Force :: 1172;
    kHIDUsage_Snsr_Data_Mechanical_AbsolutePressure :: 1173;
    kHIDUsage_Snsr_Data_Mechanical_GaugePressure :: 1174;
    kHIDUsage_Snsr_Data_Mechanical_Strain :: 1175;
    kHIDUsage_Snsr_Data_Mechanical_Weight :: 1176;
    kHIDUsage_Snsr_Property_Mechanical :: 1184;
    kHIDUsage_Snsr_Property_Mechanical_VibrationState :: 1185;
    kHIDUsage_Snsr_Property_Mechanical_ForwardVibrationSpeed :: 1186;
    kHIDUsage_Snsr_Property_Mechanical_BackwardVibrationSpeed :: 1187;
    kHIDUsage_Snsr_Data_Biometric :: 1200;
    kHIDUsage_Snsr_Data_Biometric_HumanPresence :: 1201;
    kHIDUsage_Snsr_Data_Biometric_HumanProximityRange :: 1202;
    kHIDUsage_Snsr_Data_Biometric_HumanProximityOutOfRange :: 1203;
    kHIDUsage_Snsr_Data_Biometric_HumanTouchState :: 1204;
    kHIDUsage_Snsr_Data_Light :: 1232;
    kHIDUsage_Snsr_Data_Light_Illuminance :: 1233;
    kHIDUsage_Snsr_Data_Light_ColorTemperature :: 1234;
    kHIDUsage_Snsr_Data_Light_Chromaticity :: 1235;
    kHIDUsage_Snsr_Data_Light_ChromaticityX :: 1236;
    kHIDUsage_Snsr_Data_Light_ChromaticityY :: 1237;
    kHIDUsage_Snsr_Data_Light_ConsumerIRSentenceReceive :: 1238;
    kHIDUsage_Snsr_Property_Light :: 1248;
    kHIDUsage_Snsr_Property_Light_ConsumerIRSentenceSend :: 1249;
    kHIDUsage_Snsr_Data_Scanner :: 1264;
    kHIDUsage_Snsr_Data_Scanner_RFIDTag40Bit :: 1265;
    kHIDUsage_Snsr_Data_Scanner_NFCSentenceReceive :: 1266;
    kHIDUsage_Snsr_Property_Scanner :: 1272;
    kHIDUsage_Snsr_Property_Scanner_NFCSentenceSend :: 3913;
    kHIDUsage_Snsr_Data_Electrical :: 1280;
    kHIDUsage_Snsr_Data_Electrical_Capacitance :: 1281;
    kHIDUsage_Snsr_Data_Electrical_Current :: 1282;
    kHIDUsage_Snsr_Data_Electrical_ElectricalPower :: 1283;
    kHIDUsage_Snsr_Data_Electrical_Inductance :: 1284;
    kHIDUsage_Snsr_Data_Electrical_Resistance :: 1285;
    kHIDUsage_Snsr_Data_Electrical_Voltage :: 1286;
    kHIDUsage_Snsr_Data_Electrical_Frequency :: 1287;
    kHIDUsage_Snsr_Data_Electrical_Period :: 1288;
    kHIDUsage_Snsr_Data_Electrical_PercentOfRange :: 1289;
    kHIDUsage_Snsr_Data_Time :: 1312;
    kHIDUsage_Snsr_Data_Time_Year :: 1313;
    kHIDUsage_Snsr_Data_Time_Month :: 1314;
    kHIDUsage_Snsr_Data_Time_Day :: 1315;
    kHIDUsage_Snsr_Data_Time_DayOfWeek :: 1316;
    kHIDUsage_Snsr_Data_Time_DayOfWeekSunday :: 2240;
    kHIDUsage_Snsr_Data_Time_DayOfWeekMonday :: 2241;
    kHIDUsage_Snsr_Data_Time_DayOfWeekTuesday :: 2242;
    kHIDUsage_Snsr_Data_Time_DayOfWeekWednesday :: 2243;
    kHIDUsage_Snsr_Data_Time_DayOfWeekThursday :: 2244;
    kHIDUsage_Snsr_Data_Time_DayOfWeekFriday :: 2245;
    kHIDUsage_Snsr_Data_Time_DayOfWeekSaturday :: 2246;
    kHIDUsage_Snsr_Data_Time_Hour :: 1317;
    kHIDUsage_Snsr_Data_Time_Minute :: 1318;
    kHIDUsage_Snsr_Data_Time_Second :: 1319;
    kHIDUsage_Snsr_Data_Time_Millisecond :: 1320;
    kHIDUsage_Snsr_Data_Time_Timestamp :: 1321;
    kHIDUsage_Snsr_Data_Time_JulianDayOfYear :: 1322;
    kHIDUsage_Snsr_Property_Time :: 1328;
    kHIDUsage_Snsr_Property_Time_TimeZoneOffsetFromUTC :: 1329;
    kHIDUsage_Snsr_Property_Time_TimeZoneName :: 1330;
    kHIDUsage_Snsr_Property_Time_DaylightSavingsTimeObserved :: 1331;
    kHIDUsage_Snsr_Property_Time_TimeTrimAdjustment :: 1332;
    kHIDUsage_Snsr_Property_Time_ArmAlarm :: 1333;
    kHIDUsage_Snsr_Data_Custom :: 1344;
    kHIDUsage_Snsr_Data_Custom_Usage :: 1345;
    kHIDUsage_Snsr_Data_Custom_BooleanArray :: 1346;
    kHIDUsage_Snsr_Data_Custom_Value :: 1347;
    kHIDUsage_Snsr_Data_Custom_Value1 :: 1348;
    kHIDUsage_Snsr_Data_Custom_Value2 :: 1349;
    kHIDUsage_Snsr_Data_Custom_Value3 :: 1350;
    kHIDUsage_Snsr_Data_Custom_Value4 :: 1351;
    kHIDUsage_Snsr_Data_Custom_Value5 :: 1352;
    kHIDUsage_Snsr_Data_Custom_Value6 :: 1353;
}

using anon_enum_116 :: enum u32 {
    kHIDUsage_PD_Undefined :: 0;
    kHIDUsage_PD_iName :: 1;
    kHIDUsage_PD_PresentStatus :: 2;
    kHIDUsage_PD_ChangedStatus :: 3;
    kHIDUsage_PD_UPS :: 4;
    kHIDUsage_PD_PowerSupply :: 5;
    kHIDUsage_PD_PeripheralDevice :: 6;
    kHIDUsage_PD_BatterySystem :: 16;
    kHIDUsage_PD_BatterySystemID :: 17;
    kHIDUsage_PD_Battery :: 18;
    kHIDUsage_PD_BatteryID :: 19;
    kHIDUsage_PD_Charger :: 20;
    kHIDUsage_PD_ChargerID :: 21;
    kHIDUsage_PD_PowerConverter :: 22;
    kHIDUsage_PD_PowerConverterID :: 23;
    kHIDUsage_PD_OutletSystem :: 24;
    kHIDUsage_PD_OutletSystemID :: 25;
    kHIDUsage_PD_Input :: 26;
    kHIDUsage_PD_InputID :: 27;
    kHIDUsage_PD_Output :: 28;
    kHIDUsage_PD_OutputID :: 29;
    kHIDUsage_PD_Flow :: 30;
    kHIDUsage_PD_FlowID :: 31;
    kHIDUsage_PD_Outlet :: 32;
    kHIDUsage_PD_OutletID :: 33;
    kHIDUsage_PD_Gang :: 34;
    kHIDUsage_PD_GangID :: 35;
    kHIDUsage_PD_PowerSummary :: 36;
    kHIDUsage_PD_PowerSummaryID :: 37;
    kHIDUsage_PD_Voltage :: 48;
    kHIDUsage_PD_Current :: 49;
    kHIDUsage_PD_Frequency :: 50;
    kHIDUsage_PD_ApparentPower :: 51;
    kHIDUsage_PD_ActivePower :: 52;
    kHIDUsage_PD_PercentLoad :: 53;
    kHIDUsage_PD_Temperature :: 54;
    kHIDUsage_PD_Humidity :: 55;
    kHIDUsage_PD_BadCount :: 56;
    kHIDUsage_PD_ConfigVoltage :: 64;
    kHIDUsage_PD_ConfigCurrent :: 65;
    kHIDUsage_PD_ConfigFrequency :: 66;
    kHIDUsage_PD_ConfigApparentPower :: 67;
    kHIDUsage_PD_ConfigActivePower :: 68;
    kHIDUsage_PD_ConfigPercentLoad :: 69;
    kHIDUsage_PD_ConfigTemperature :: 70;
    kHIDUsage_PD_ConfigHumidity :: 71;
    kHIDUsage_PD_SwitchOnControl :: 80;
    kHIDUsage_PD_SwitchOffControl :: 81;
    kHIDUsage_PD_ToggleControl :: 82;
    kHIDUsage_PD_LowVoltageTransfer :: 83;
    kHIDUsage_PD_HighVoltageTransfer :: 84;
    kHIDUsage_PD_DelayBeforeReboot :: 85;
    kHIDUsage_PD_DelayBeforeStartup :: 86;
    kHIDUsage_PD_DelayBeforeShutdown :: 87;
    kHIDUsage_PD_Test :: 88;
    kHIDUsage_PD_ModuleReset :: 89;
    kHIDUsage_PD_AudibleAlarmControl :: 90;
    kHIDUsage_PD_Present :: 96;
    kHIDUsage_PD_Good :: 97;
    kHIDUsage_PD_InternalFailure :: 98;
    kHIDUsage_PD_VoltageOutOfRange :: 99;
    kHIDUsage_PD_FrequencyOutOfRange :: 100;
    kHIDUsage_PD_Overload :: 101;
    kHIDUsage_PD_OverCharged :: 102;
    kHIDUsage_PD_OverTemperature :: 103;
    kHIDUsage_PD_ShutdownRequested :: 104;
    kHIDUsage_PD_ShutdownImminent :: 105;
    kHIDUsage_PD_SwitchOnOff :: 107;
    kHIDUsage_PD_Switchable :: 108;
    kHIDUsage_PD_Used :: 109;
    kHIDUsage_PD_Boost :: 110;
    kHIDUsage_PD_Buck :: 111;
    kHIDUsage_PD_Initialized :: 112;
    kHIDUsage_PD_Tested :: 113;
    kHIDUsage_PD_AwaitingPower :: 114;
    kHIDUsage_PD_CommunicationLost :: 115;
    kHIDUsage_PD_iManufacturer :: 253;
    kHIDUsage_PD_iProduct :: 254;
    kHIDUsage_PD_iserialNumber :: 255;
}

using anon_enum_117 :: enum u32 {
    kHIDUsage_BS_Undefined :: 0;
    kHIDUsage_BS_SMBBatteryMode :: 1;
    kHIDUsage_BS_SMBBatteryStatus :: 2;
    kHIDUsage_BS_SMBAlarmWarning :: 3;
    kHIDUsage_BS_SMBChargerMode :: 4;
    kHIDUsage_BS_SMBChargerStatus :: 5;
    kHIDUsage_BS_SMBChargerSpecInfo :: 6;
    kHIDUsage_BS_SMBSelectorState :: 7;
    kHIDUsage_BS_SMBSelectorPresets :: 8;
    kHIDUsage_BS_SMBSelectorInfo :: 9;
    kHIDUsage_BS_OptionalMfgFunction1 :: 16;
    kHIDUsage_BS_OptionalMfgFunction2 :: 17;
    kHIDUsage_BS_OptionalMfgFunction3 :: 18;
    kHIDUsage_BS_OptionalMfgFunction4 :: 19;
    kHIDUsage_BS_OptionalMfgFunction5 :: 20;
    kHIDUsage_BS_ConnectionToSMBus :: 21;
    kHIDUsage_BS_OutputConnection :: 22;
    kHIDUsage_BS_ChargerConnection :: 23;
    kHIDUsage_BS_BatteryInsertion :: 24;
    kHIDUsage_BS_Usenext :: 25;
    kHIDUsage_BS_OKToUse :: 26;
    kHIDUsage_BS_BatterySupported :: 27;
    kHIDUsage_BS_SelectorRevision :: 28;
    kHIDUsage_BS_ChargingIndicator :: 29;
    kHIDUsage_BS_ManufacturerAccess :: 40;
    kHIDUsage_BS_RemainingCapacityLimit :: 41;
    kHIDUsage_BS_RemainingTimeLimit :: 42;
    kHIDUsage_BS_AtRate :: 43;
    kHIDUsage_BS_CapacityMode :: 44;
    kHIDUsage_BS_BroadcastToCharger :: 45;
    kHIDUsage_BS_PrimaryBattery :: 46;
    kHIDUsage_BS_ChargeController :: 47;
    kHIDUsage_BS_TerminateCharge :: 64;
    kHIDUsage_BS_TerminateDischarge :: 65;
    kHIDUsage_BS_BelowRemainingCapacityLimit :: 66;
    kHIDUsage_BS_RemainingTimeLimitExpired :: 67;
    kHIDUsage_BS_Charging :: 68;
    kHIDUsage_BS_Discharging :: 69;
    kHIDUsage_BS_FullyCharged :: 70;
    kHIDUsage_BS_FullyDischarged :: 71;
    kHIDUsage_BS_ConditioningFlag :: 72;
    kHIDUsage_BS_AtRateOK :: 73;
    kHIDUsage_BS_SMBErrorCode :: 74;
    kHIDUsage_BS_NeedReplacement :: 75;
    kHIDUsage_BS_AtRateTimeToFull :: 96;
    kHIDUsage_BS_AtRateTimeToEmpty :: 97;
    kHIDUsage_BS_AverageCurrent :: 98;
    kHIDUsage_BS_Maxerror :: 99;
    kHIDUsage_BS_RelativeStateOfCharge :: 100;
    kHIDUsage_BS_AbsoluteStateOfCharge :: 101;
    kHIDUsage_BS_RemainingCapacity :: 102;
    kHIDUsage_BS_FullChargeCapacity :: 103;
    kHIDUsage_BS_RunTimeToEmpty :: 104;
    kHIDUsage_BS_AverageTimeToEmpty :: 105;
    kHIDUsage_BS_AverageTimeToFull :: 106;
    kHIDUsage_BS_CycleCount :: 107;
    kHIDUsage_BS_BattPackModelLevel :: 128;
    kHIDUsage_BS_InternalChargeController :: 129;
    kHIDUsage_BS_PrimaryBatterySupport :: 130;
    kHIDUsage_BS_DesignCapacity :: 131;
    kHIDUsage_BS_SpecificationInfo :: 132;
    kHIDUsage_BS_ManufacturerDate :: 133;
    kHIDUsage_BS_SerialNumber :: 134;
    kHIDUsage_BS_iManufacturerName :: 135;
    kHIDUsage_BS_iDevicename :: 136;
    kHIDUsage_BS_iDeviceChemistry :: 137;
    kHIDUsage_BS_ManufacturerData :: 138;
    kHIDUsage_BS_Rechargable :: 139;
    kHIDUsage_BS_WarningCapacityLimit :: 140;
    kHIDUsage_BS_CapacityGranularity1 :: 141;
    kHIDUsage_BS_CapacityGranularity2 :: 142;
    kHIDUsage_BS_iOEMInformation :: 143;
    kHIDUsage_BS_InhibitCharge :: 192;
    kHIDUsage_BS_EnablePolling :: 193;
    kHIDUsage_BS_ResetToZero :: 194;
    kHIDUsage_BS_ACPresent :: 208;
    kHIDUsage_BS_BatteryPresent :: 209;
    kHIDUsage_BS_PowerFail :: 210;
    kHIDUsage_BS_AlarmInhibited :: 211;
    kHIDUsage_BS_ThermistorUnderRange :: 212;
    kHIDUsage_BS_ThermistorHot :: 213;
    kHIDUsage_BS_ThermistorCold :: 214;
    kHIDUsage_BS_ThermistorOverRange :: 215;
    kHIDUsage_BS_VoltageOutOfRange :: 216;
    kHIDUsage_BS_CurrentOutOfRange :: 217;
    kHIDUsage_BS_CurrentNotRegulated :: 218;
    kHIDUsage_BS_VoltageNotRegulated :: 219;
    kHIDUsage_BS_MasterMode :: 220;
    kHIDUsage_BS_ChargerSelectorSupport :: 240;
    kHIDUsage_BS_ChargerSpec :: 241;
    kHIDUsage_BS_Level2 :: 242;
    kHIDUsage_BS_Level3 :: 243;
}

using anon_enum_118 :: enum u32 {
    kHIDUsage_BCS_Undefined :: 0;
    kHIDUsage_BCS_BadgeReader :: 1;
    kHIDUsage_BCS_BarCodeScanner :: 2;
    kHIDUsage_BCS_DumbBarCodeScanner :: 3;
    kHIDUsage_BCS_CordlessScannerBase :: 4;
    kHIDUsage_BCS_BarCodeScannerCradle :: 5;
    kHIDUsage_BCS_AttributeReport :: 16;
    kHIDUsage_BCS_SettingsReport :: 17;
    kHIDUsage_BCS_ScannedDataReport :: 18;
    kHIDUsage_BCS_RawScannedDataReport :: 19;
    kHIDUsage_BCS_TriggerReport :: 20;
    kHIDUsage_BCS_StatusReport :: 21;
    kHIDUsage_BCS_UPC_EANControlReport :: 22;
    kHIDUsage_BCS_EAN2_3LabelControlReport :: 23;
    kHIDUsage_BCS_Code39ControlReport :: 24;
    kHIDUsage_BCS_Interleaved2of5ControlReport :: 25;
    kHIDUsage_BCS_Standard2of5ControlReport :: 26;
    kHIDUsage_BCS_MSIPlesseyControlReport :: 27;
    kHIDUsage_BCS_CodabarControlReport :: 28;
    kHIDUsage_BCS_Code128ControlReport :: 29;
    kHIDUsage_BCS_Misc1DControlReport :: 30;
    kHIDUsage_BCS_2DControlReport :: 31;
    kHIDUsage_BCS_Aiming_PointerMide :: 48;
    kHIDUsage_BCS_BarCodePresentSensor :: 49;
    kHIDUsage_BCS_Class1ALaser :: 50;
    kHIDUsage_BCS_Class2Laser :: 51;
    kHIDUsage_BCS_HeaterPresent :: 52;
    kHIDUsage_BCS_ContactScanner :: 53;
    kHIDUsage_BCS_ElectronicArticleSurveillanceNotification :: 54;
    kHIDUsage_BCS_ConstantElectronicArticleSurveillance :: 55;
    kHIDUsage_BCS_ErrorIndication :: 56;
    kHIDUsage_BCS_FixedBeeper :: 57;
    kHIDUsage_BCS_GoodDecodeIndication :: 58;
    kHIDUsage_BCS_HandsFreeScanning :: 59;
    kHIDUsage_BCS_IntrinsicallySafe :: 60;
    kHIDUsage_BCS_KlasseEinsLaser :: 61;
    kHIDUsage_BCS_LongRangeScanner :: 62;
    kHIDUsage_BCS_MirrorSpeedControl :: 63;
    kHIDUsage_BCS_NotOnFileIndication :: 64;
    kHIDUsage_BCS_ProgrammableBeeper :: 65;
    kHIDUsage_BCS_Triggerless :: 66;
    kHIDUsage_BCS_Wand :: 67;
    kHIDUsage_BCS_WaterResistant :: 68;
    kHIDUsage_BCS_MultiRangeScanner :: 69;
    kHIDUsage_BCS_ProximitySensor :: 70;
    kHIDUsage_BCS_FragmentDecoding :: 77;
    kHIDUsage_BCS_ScannerReadConfidence :: 78;
    kHIDUsage_BCS_DataPrefix :: 79;
    kHIDUsage_BCS_PrefixAIMI :: 80;
    kHIDUsage_BCS_PrefixNone :: 81;
    kHIDUsage_BCS_PrefixProprietary :: 82;
    kHIDUsage_BCS_ActiveTime :: 85;
    kHIDUsage_BCS_AimingLaserPattern :: 86;
    kHIDUsage_BCS_BarCodePresent :: 87;
    kHIDUsage_BCS_BeeperState :: 88;
    kHIDUsage_BCS_LaserOnTime :: 89;
    kHIDUsage_BCS_LaserState :: 90;
    kHIDUsage_BCS_LockoutTime :: 91;
    kHIDUsage_BCS_MotorState :: 92;
    kHIDUsage_BCS_MotorTimeout :: 93;
    kHIDUsage_BCS_PowerOnResetScanner :: 94;
    kHIDUsage_BCS_PreventReadOfBarcodes :: 95;
    kHIDUsage_BCS_InitiateBarcodeRead :: 96;
    kHIDUsage_BCS_TriggerState :: 97;
    kHIDUsage_BCS_TriggerMode :: 98;
    kHIDUsage_BCS_TriggerModeBlinkingLaserOn :: 99;
    kHIDUsage_BCS_TriggerModeContinuousLaserOn :: 100;
    kHIDUsage_BCS_TriggerModeLaserOnWhilePulled :: 101;
    kHIDUsage_BCS_TriggerModeLaserStaysOnAfterTriggerRelease :: 102;
    kHIDUsage_BCS_CommitParametersToNVM :: 109;
    kHIDUsage_BCS_ParameterScanning :: 110;
    kHIDUsage_BCS_ParametersChanged :: 111;
    kHIDUsage_BCS_SetParameterDefaultValues :: 112;
    kHIDUsage_BCS_ScannerInCradle :: 117;
    kHIDUsage_BCS_ScannerInRange :: 118;
    kHIDUsage_BCS_AimDuration :: 122;
    kHIDUsage_BCS_GoodReadLampDuration :: 123;
    kHIDUsage_BCS_GoodReadLampIntensity :: 124;
    kHIDUsage_BCS_GoodReadLED :: 125;
    kHIDUsage_BCS_GoodReadToneFrequency :: 126;
    kHIDUsage_BCS_GoodReadToneLength :: 127;
    kHIDUsage_BCS_GoodReadToneVolume :: 128;
    kHIDUsage_BCS_NoReadMessage :: 130;
    kHIDUsage_BCS_NotOnFileVolume :: 131;
    kHIDUsage_BCS_PowerupBeep :: 132;
    kHIDUsage_BCS_SoundErrorBeep :: 133;
    kHIDUsage_BCS_SoundGoodReadBeep :: 134;
    kHIDUsage_BCS_SoundNotOnFileBeep :: 135;
    kHIDUsage_BCS_GoodReadWhenToWrite :: 136;
    kHIDUsage_BCS_GRWTIAfterDecode :: 137;
    kHIDUsage_BCS_GRWTIBeep_LampAfterTransmit :: 138;
    kHIDUsage_BCS_GRWTINoBeep_LampUseAtAll :: 139;
    kHIDUsage_BCS_BooklandEAN :: 145;
    kHIDUsage_BCS_ConvertEAN8To13Type :: 146;
    kHIDUsage_BCS_ConvertUPCAToEAN_13 :: 147;
    kHIDUsage_BCS_ConvertUPC_EToA :: 148;
    kHIDUsage_BCS_EAN_13 :: 149;
    kHIDUsage_BCS_EAN_8 :: 150;
    kHIDUsage_BCS_EAN_99_128_Mandatory :: 151;
    kHIDUsage_BCS_EAN_99_P5_128_Optional :: 152;
    kHIDUsage_BCS_UPC_EAN :: 154;
    kHIDUsage_BCS_UPC_EANCouponCode :: 155;
    kHIDUsage_BCS_UPC_EANPeriodicals :: 156;
    kHIDUsage_BCS_UPC_A :: 157;
    kHIDUsage_BCS_UPC_AWith128Mandatory :: 158;
    kHIDUsage_BCS_UPC_AWith128Optical :: 159;
    kHIDUsage_BCS_UPC_AWithP5Optional :: 160;
    kHIDUsage_BCS_UPC_E :: 161;
    kHIDUsage_BCS_UPC_E1 :: 162;
    kHIDUsage_BCS_Periodical :: 169;
    kHIDUsage_BCS_PeriodicalAutoDiscriminatePlus2 :: 170;
    kHIDUsage_BCS_PeriodicalOnlyDecodeWithPlus2 :: 171;
    kHIDUsage_BCS_PeriodicalIgnorePlus2 :: 172;
    kHIDUsage_BCS_PeriodicalAutoDiscriminatePlus5 :: 173;
    kHIDUsage_BCS_PeriodicalOnlyDecodeWithPlus5 :: 174;
    kHIDUsage_BCS_PeriodicalIgnorePlus5 :: 175;
    kHIDUsage_BCS_Check :: 176;
    kHIDUsage_BCS_CheckDisablePrice :: 177;
    kHIDUsage_BCS_CheckEnable4DigitPrice :: 178;
    kHIDUsage_BCS_CheckEnable5DigitPrice :: 179;
    kHIDUsage_BCS_CheckEnableEuropean4DigitPrice :: 180;
    kHIDUsage_BCS_CheckEnableEuropean5DigitPrice :: 181;
    kHIDUsage_BCS_EANTwoLabel :: 183;
    kHIDUsage_BCS_EANThreeLabel :: 184;
    kHIDUsage_BCS_EAN8FlagDigit1 :: 185;
    kHIDUsage_BCS_EAN8FlagDigit2 :: 186;
    kHIDUsage_BCS_EAN8FlagDigit3 :: 187;
    kHIDUsage_BCS_EAN13FlagDigit1 :: 188;
    kHIDUsage_BCS_EAN13FlagDigit2 :: 189;
    kHIDUsage_BCS_EAN13FlagDigit3 :: 190;
    kHIDUsage_BCS_AddEAN2_3LabelDefinition :: 191;
    kHIDUsage_BCS_ClearAllEAN2_3LabelDefinitions :: 192;
    kHIDUsage_BCS_Codabar :: 195;
    kHIDUsage_BCS_Code128 :: 196;
    kHIDUsage_BCS_Code39 :: 199;
    kHIDUsage_BCS_Code93 :: 200;
    kHIDUsage_BCS_FullASCIIConversion :: 201;
    kHIDUsage_BCS_Interleaved2of5 :: 202;
    kHIDUsage_BCS_ItalianPharmacyCode :: 203;
    kHIDUsage_BCS_MSI_Plessey :: 204;
    kHIDUsage_BCS_Standard2of5IATA :: 205;
    kHIDUsage_BCS_Standard2of5 :: 206;
    kHIDUsage_BCS_TransmitStart_Stop :: 211;
    kHIDUsage_BCS_TriOptic :: 212;
    kHIDUsage_BCS_UCC_EAN_128 :: 213;
    kHIDUsage_BCS_CheckDigit :: 214;
    kHIDUsage_BCS_CheckDigitDisable :: 215;
    kHIDUsage_BCS_CheckDigitEnableInterleaved2of5OPCC :: 216;
    kHIDUsage_BCS_CheckDigitEnableInterleaved2of5USS :: 217;
    kHIDUsage_BCS_CheckDigitEnableStandard2of5OPCC :: 216;
    kHIDUsage_BCS_CheckDigitEnableStandard2of5USS :: 217;
    kHIDUsage_BCS_CheckDigitEnableOneMSIPlessey :: 220;
    kHIDUsage_BCS_CheckDigitEnableTwoMSIPlessey :: 221;
    kHIDUsage_BCS_CheckDigitCodabarEnable :: 222;
    kHIDUsage_BCS_CheckDigitCode99Enable :: 223;
    kHIDUsage_BCS_TransmitCheckDigit :: 240;
    kHIDUsage_BCS_DisableCheckDigitTransmit :: 241;
    kHIDUsage_BCS_EnableCheckDigitTransmit :: 242;
    kHIDUsage_BCS_SymbologyIdentifier1 :: 251;
    kHIDUsage_BCS_SymbologyIdentifier2 :: 252;
    kHIDUsage_BCS_SymbologyIdentifier3 :: 253;
    kHIDUsage_BCS_DecodedData :: 254;
    kHIDUsage_BCS_DecodeDataContinued :: 255;
    kHIDUsage_BCS_BarSpaceData :: 256;
    kHIDUsage_BCS_ScannerDataAccuracy :: 257;
    kHIDUsage_BCS_RawDataPolarity :: 258;
    kHIDUsage_BCS_PolarityInvertedBarCode :: 259;
    kHIDUsage_BCS_PolarityNormalBarCode :: 259;
    kHIDUsage_BCS_MinimumLengthToDecode :: 262;
    kHIDUsage_BCS_MaximumLengthToDecode :: 263;
    kHIDUsage_BCS_FirstDiscreteLengthToDecode :: 264;
    kHIDUsage_BCS_SecondDiscreteLengthToDecode :: 265;
    kHIDUsage_BCS_DataLengthMethod :: 266;
    kHIDUsage_BCS_DLMethodReadAny :: 267;
    kHIDUsage_BCS_DLMethodCheckInRange :: 268;
    kHIDUsage_BCS_DLMethodCheckForDiscrete :: 269;
    kHIDUsage_BCS_AztecCode :: 272;
    kHIDUsage_BCS_BC412 :: 273;
    kHIDUsage_BCS_ChannelCode :: 274;
    kHIDUsage_BCS_Code16 :: 275;
    kHIDUsage_BCS_Code32 :: 276;
    kHIDUsage_BCS_Code49 :: 277;
    kHIDUsage_BCS_CodeOne :: 278;
    kHIDUsage_BCS_Colorcode :: 279;
    kHIDUsage_BCS_DataMatrix :: 280;
    kHIDUsage_BCS_MaxiCode :: 281;
    kHIDUsage_BCS_MicroPDF :: 282;
    kHIDUsage_BCS_PDF_417 :: 283;
    kHIDUsage_BCS_PosiCode :: 284;
    kHIDUsage_BCS_QRCode :: 285;
    kHIDUsage_BCS_SuperCode :: 286;
    kHIDUsage_BCS_UltraCode :: 287;
    kHIDUsage_BCS_USB_5_SlugCode :: 288;
    kHIDUsage_BCS_VeriCode :: 289;
}

using anon_enum_119 :: enum u32 {
    kHIDUsage_WD_Undefined :: 0;
    kHIDUsage_WD_WeighingDevice :: 1;
    kHIDUsage_WD_ScaleScaleDevice :: 32;
    kHIDUsage_WD_ScaleScaleClassIMetricCL :: 33;
    kHIDUsage_WD_ScaleScaleClassIMetric :: 34;
    kHIDUsage_WD_ScaleScaleClassIIMetric :: 35;
    kHIDUsage_WD_ScaleScaleClassIIIMetric :: 36;
    kHIDUsage_WD_ScaleScaleClassIIILMetric :: 37;
    kHIDUsage_WD_ScaleScaleClassIVMetric :: 38;
    kHIDUsage_WD_ScaleScaleClassIIIEnglish :: 39;
    kHIDUsage_WD_ScaleScaleClassIIILEnglish :: 40;
    kHIDUsage_WD_ScaleScaleClassIVEnglish :: 41;
    kHIDUsage_WD_ScaleScaleClassGeneric :: 42;
    kHIDUsage_WD_ScaleAtrributeReport :: 48;
    kHIDUsage_WD_ScaleControlReport :: 49;
    kHIDUsage_WD_ScaleDataReport :: 50;
    kHIDUsage_WD_ScaleStatusReport :: 51;
    kHIDUsage_WD_ScaleWeightLimitReport :: 52;
    kHIDUsage_WD_ScaleStatisticsReport :: 53;
    kHIDUsage_WD_DataWeight :: 64;
    kHIDUsage_WD_DataScaling :: 65;
    kHIDUsage_WD_WeightUnit :: 80;
    kHIDUsage_WD_WeightUnitMilligram :: 81;
    kHIDUsage_WD_WeightUnitGram :: 82;
    kHIDUsage_WD_WeightUnitKilogram :: 83;
    kHIDUsage_WD_WeightUnitCarats :: 84;
    kHIDUsage_WD_WeightUnitTaels :: 85;
    kHIDUsage_WD_WeightUnitGrains :: 86;
    kHIDUsage_WD_WeightUnitPennyweights :: 87;
    kHIDUsage_WD_WeightUnitMetricTon :: 88;
    kHIDUsage_WD_WeightUnitAvoirTon :: 89;
    kHIDUsage_WD_WeightUnitTroyOunce :: 90;
    kHIDUsage_WD_WeightUnitOunce :: 91;
    kHIDUsage_WD_WeightUnitPound :: 92;
    kHIDUsage_WD_CalibrationCount :: 96;
    kHIDUsage_WD_RezeroCount :: 97;
    kHIDUsage_WD_ScaleStatus :: 112;
    kHIDUsage_WD_ScaleStatusFault :: 113;
    kHIDUsage_WD_ScaleStatusStableAtZero :: 114;
    kHIDUsage_WD_ScaleStatusInMotion :: 115;
    kHIDUsage_WD_ScaleStatusWeightStable :: 116;
    kHIDUsage_WD_ScaleStatusUnderZero :: 117;
    kHIDUsage_WD_ScaleStatusOverWeightLimit :: 118;
    kHIDUsage_WD_ScaleStatusRequiresCalibration :: 119;
    kHIDUsage_WD_ScaleStatusRequiresRezeroing :: 120;
    kHIDUsage_WD_ZeroScale :: 128;
    kHIDUsage_WD_EnforcedZeroReturn :: 129;
}

using anon_enum_120 :: enum u32 {
    kHIDUsage_MSR_Undefined :: 0;
    kHIDUsage_MSR_DeviceReadOnly :: 1;
    kHIDUsage_MSR_Track1Length :: 17;
    kHIDUsage_MSR_Track2Length :: 18;
    kHIDUsage_MSR_Track3Length :: 19;
    kHIDUsage_MSR_TrackJISLength :: 20;
    kHIDUsage_MSR_TrackData :: 32;
    kHIDUsage_MSR_Track1Data :: 33;
    kHIDUsage_MSR_Track2Data :: 34;
    kHIDUsage_MSR_Track3Data :: 35;
    kHIDUsage_MSR_TrackJISData :: 36;
}

IOHIDValueGetTypeID :: () -> CFTypeID #foreign IOKit;

IOHIDValueCreateWithIntegerValue :: (allocator: CFAllocatorRef, element: IOHIDElementRef, timeStamp: u64, value: CFIndex) -> IOHIDValueRef #foreign IOKit;

IOHIDValueCreateWithBytes :: (allocator: CFAllocatorRef, element: IOHIDElementRef, timeStamp: u64, bytes: *u8, length: CFIndex) -> IOHIDValueRef #foreign IOKit;

IOHIDValueCreateWithBytesNoCopy :: (allocator: CFAllocatorRef, element: IOHIDElementRef, timeStamp: u64, bytes: *u8, length: CFIndex) -> IOHIDValueRef #foreign IOKit;

IOHIDValueGetElement :: (value: IOHIDValueRef) -> IOHIDElementRef #foreign IOKit;

IOHIDValueGetTimeStamp :: (value: IOHIDValueRef) -> u64 #foreign IOKit;

IOHIDValueGetLength :: (value: IOHIDValueRef) -> CFIndex #foreign IOKit;

IOHIDValueGetBytePtr :: (value: IOHIDValueRef) -> *u8 #foreign IOKit;

IOHIDValueGetIntegerValue :: (value: IOHIDValueRef) -> CFIndex #foreign IOKit;

IOHIDValueGetScaledValue :: (value: IOHIDValueRef, type: IOHIDValueScaleType) -> float64 #foreign IOKit;

__IOHIDTransaction :: struct {
}

IOHIDTransactionRef :: *__IOHIDTransaction;

IOHIDTransactionGetTypeID :: () -> CFTypeID #foreign IOKit;

IOHIDTransactionCreate :: (allocator: CFAllocatorRef, device: IOHIDDeviceRef, direction: IOHIDTransactionDirectionType, options: IOOptionBits) -> IOHIDTransactionRef #foreign IOKit;

IOHIDTransactionGetDevice :: (transaction: IOHIDTransactionRef) -> IOHIDDeviceRef #foreign IOKit;

IOHIDTransactionGetDirection :: (transaction: IOHIDTransactionRef) -> IOHIDTransactionDirectionType #foreign IOKit;

IOHIDTransactionSetDirection :: (transaction: IOHIDTransactionRef, direction: IOHIDTransactionDirectionType) -> void #foreign IOKit;

IOHIDTransactionAddElement :: (transaction: IOHIDTransactionRef, element: IOHIDElementRef) -> void #foreign IOKit;

IOHIDTransactionRemoveElement :: (transaction: IOHIDTransactionRef, element: IOHIDElementRef) -> void #foreign IOKit;

IOHIDTransactionContainsElement :: (transaction: IOHIDTransactionRef, element: IOHIDElementRef) -> Boolean #foreign IOKit;

IOHIDTransactionScheduleWithRunLoop :: (transaction: IOHIDTransactionRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDTransactionUnscheduleFromRunLoop :: (transaction: IOHIDTransactionRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) -> void #foreign IOKit;

IOHIDTransactionSetValue :: (transaction: IOHIDTransactionRef, element: IOHIDElementRef, value: IOHIDValueRef, options: IOOptionBits) -> void #foreign IOKit;

IOHIDTransactionGetValue :: (transaction: IOHIDTransactionRef, element: IOHIDElementRef, options: IOOptionBits) -> IOHIDValueRef #foreign IOKit;

IOHIDTransactionCommit :: (transaction: IOHIDTransactionRef) -> IOReturn #foreign IOKit;

IOHIDTransactionCommitWithCallback :: (transaction: IOHIDTransactionRef, timeout: CFTimeInterval, callback: IOHIDCallback, _context: *void) -> IOReturn #foreign IOKit;

IOHIDTransactionClear :: (transaction: IOHIDTransactionRef) -> void #foreign IOKit;

#scope_file

IOKit :: #system_library "IOKit";


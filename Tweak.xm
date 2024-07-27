#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore2.h>
#import <QuartzCore/CAAnimation.h>
#import <IOSurface/IOSurface.h>
#import <UIKit/UIGraphics.h>
#import <Foundation/Foundation.h>
//#import <SpringBoard/SpringBoard.h>
//#import <substrate.h>
#import <GraphicsServices/GSEvent.h>
#import <Foundation/NSObject.h>
//#import <logos/logos.h>

//Stack blur is the fastest blur I have found thus far for 3.1.3.
#import "UIImage+StackBlur.h"
#import "UIImage+Resize.h"
#import "UIImage+LiveBlur.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MPMusicPlayerController.h>

//Maybe not all of these need to be imported :P
#import <sys/types.h>
#import <sys/stat.h>
#import <objc/runtime.h>
#import <stdio.h>
#import <string.h>
#import <stdlib.h>
#import <notify.h>
#import <unistd.h>
#import <IOKit/IOKitLib.h>
#import <sys/sysctl.h> // This shuts up a warning about sysctlbyname
#import <sys/param.h>
#import <sys/types.h>

//Used for opening libraries
#import <dlfcn.h>

#define WD_CCSettingsReloadNotification "com.whited00r.controlcenter.reloadPrefs" //Used later on for something maybe?
#define WD_CCSettingsPlistPath "/var/mobile/Library/Preferences/com.whited00r.controlcenter.plist"


%class SBStatusBarContentView

//For the screenshot of the open things
UIKIT_EXTERN CGImageRef UIGetScreenImage();

//More stuff used int he blur :P
@interface UIImage (CropThis)

- (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect;

@end

@implementation UIImage (CropThis)
- (UIImage *)croppedToRect:(CGRect)rect {

   CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef); 
    return cropped;
}
@end

//Good for the buttons I suppose, I use something like this in the new WD7UI for coloring all the images (so don't share how I do it :P )
@interface UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor;

@end

@implementation UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor {
  UIGraphicsBeginImageContext(self.size);
  CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
  [self drawInRect:drawRect];
  [tintColor set];
  UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tintedImage;
}

@end





//Stuff above this isn't entirely by me :P I just modified some of it to compile/work on 3.1.3 and be quicker for what I needed.


static UIImage *backgroundImage;

static UIImageView *backgroundImageView;

static BOOL shouldUpdateBackground = TRUE;

static BOOL isLoaded = FALSE;

static BOOL isShowing = FALSE;

static BOOL wifi = FALSE;

static BOOL bluetooth = FALSE;


static BOOL closeAndHome = FALSE;

static BOOL isLocked = TRUE;

static BOOL isIphone = FALSE;

static BOOL blurBackground = FALSE;
static BOOL tintBlur = TRUE;

static BOOL orientationLocked;

@interface SBWiFiManager

-(BOOL)wiFiEnabled;
@end




//Grab the value new each time... Slow-ish but good enough to use. It can't be a BOOL though as it's from different classes and the extern BOOL thing I couldn't figure out in time for the release :P
BOOL isOrientationLocked()
{
NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@WD_CCSettingsPlistPath];
orientationLocked = [[dict objectForKey:@"orientationLocked"] boolValue];
[dict release];
return orientationLocked;
}

//So it writes it to the file for the orientation one :P
void setOrientationLocked(BOOL enable)
{

                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@WD_CCSettingsPlistPath];
                if (!dict)
                        dict = [[NSMutableDictionary alloc] init];
                [dict setObject:[NSNumber numberWithBool:enable] forKey:@"orientationLocked"];
                [dict writeToFile:@WD_CCSettingsPlistPath atomically:TRUE];
                //ReloadPreferences();
                //notify_post("com.whited00r.controlcenter.reloadPrefs");

}

static BOOL isThisWhited00r = FALSE; //You knew when I asked if it was at the top above everything? ;) It wasn't. I moved it up here.

static BOOL loadedPrefs = FALSE;

static BOOL airplaneMode = FALSE;

static void loadPrefs(); //Meh

@interface SBUIController 
-(BOOL)isWhited00r; //Fix for the conversion thingy.
@end

@interface SBMediaController
-(BOOL)isPlaying;
-(id)nowPlayingArtist;
-(id)nowPlayingTitle;
-(id)nowPlayingAlbum;
-(BOOL)changeTrack:(int)track;
-(BOOL)togglePlayPause;
-(float)volume;
-(void)setVolume:(float)volume;
-(void)_changeVolumeBy:(float)by;
-(void)increaseVolume;
-(void)decreaseVolume;
@end

@interface ControlCenter : UIView
-(void)unloadControlCenter;
-(void)loadControlCenter;
-(void)closedControlCenter;
-(void)isNotUse;
-(void)loadCalculator;
-(void)loadClock;
-(void)loadCamera;
-(void)sliderLuminosity;
-(void)setVolume;
-(void)lockOrientation;
-(void)setWifi;
-(void)setBluetooth;
-(void)openBundle;
-(void)openApp;
-(void)toggleBluetooth;
-(void)showInfoLabel:(NSString*)newText;
-(void)hideInfoLabel;
-(void)unlock;
-(void)previousSong;
-(void)nextSong;
-(void)playPause;
-(void)updateMusic;
- (void)updateWindowLevel:(NSNotification *)notification;
NSString *appID;
NSMutableDictionary *plistDict;
NSString *filePath;
UISlider *slider;
UISlider *volumeSlider;
UIButton *calculatorOpen;
UIButton *flashLight;
UIButton *clockOpen;
UIButton *cameraOpen;
UIButton *Orientation;
UIButton *DND;
UIButton *Bluetooth;
UIButton *Wifi;
UIButton *Airplane;
UIButton *PlayPause;
UIButton *next;
UIButton *prev; 
UILabel *infoLabel;
UILabel *songTitleLabel;
UILabel *artistLabel;
UIView *flashLightView;
BOOL registeredForMusic;
float oldBrightness;
CGPoint startPoint;
-(BOOL)playing;
-(id)artist;
-(id)title;
-(id)album;
@end


%class SBApplication



static void loadPrefs(){

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *prefsPlist = @"/var/mobile/Library/Preferences/com.whited00r.controlcenter.plist";
    if([[NSFileManager defaultManager]fileExistsAtPath:prefsPlist]){
        NSDictionary *prefs=[[NSDictionary alloc]initWithContentsOfFile:prefsPlist];
        blurBackground=[[prefs objectForKey:@"blurBackground"]boolValue];
        tintBlur = [[prefs objectForKey:@"tintBlur"] boolValue];
        [prefs release];

    }
    else{
        NSDictionary *prefs=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:FALSE],@"blurBackground", [NSNumber numberWithBool:FALSE], @"tintBlur", nil];
        [prefs writeToFile:prefsPlist atomically:YES];
        [prefs release];
    }
//CFNotificationCenterAddObserver( CFNotificationCenterGetDarwinNotifyCenter(), NULL, (void (*)(CFNotificationCenterRef, void *, CFStringRef, const void *, CFDictionaryRef))ReloadPreferences, CFSTR("com.whited00r.controlcenter.reloadPrefs"), NULL, CFNotificationSuspensionBehaviorHold );
    loadedPrefs = TRUE;
    [pool drain];
}
 
static UIWindow *window;
static ControlCenter *controlCenter; //Declaring this for use everywhere. 
 
@interface SwipeRecognizer : UIImageView //Oops. UIImageView can be transparent images for the background. :s (or rather image)
CGPoint startLocation;
NSString *swipeDirection;
@property(nonatomic, assign) NSString *swipeDirection;
@property (nonatomic, assign) id  delegate; //So it can call stuff off in the original tweak stuff :P
@end
 

static SwipeRecognizer *swipeIt; //heee heee

@implementation SwipeRecognizer
@synthesize swipeDirection, delegate;
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
 
 
startLocation = [[touches anyObject] locationInView:self]; //Saving the start position...
[[self superview] bringSubviewToFront:self]; //Might need to be done, doesn't do any harm if it doesn't.

//So it doesn't remake the blur when it's open
if(blurBackground){
if(shouldUpdateBackground){

backgroundImage = nil;
backgroundImage = [UIImage liveBlurForScreenWithQuality:4 interpolation:4 blurRadius:15];
if(tintBlur){
	backgroundImage = [backgroundImage tintedImageUsingColor:[UIColor colorWithWhite:0.6 alpha:0.5]];
}
[backgroundImage retain];
backgroundImageView.image = backgroundImage;

//backgroundImage = [UIImage imageWithCGImage:screen];


}
}
}
 
 
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
// Calculate offset
if(window){
CGPoint pt = [[touches anyObject] locationInView:window]; //Changed this only so it knows the actual location :P
float dx = pt.x - startLocation.x;
float dy = pt.y - startLocation.y;
 
float newCenterY = window.center.y + dy;
if(newCenterY >= 700){
        newCenterY = 700;
}

window.center = CGPointMake(window.center.x, newCenterY);
//Moving the blur background thing to match
if(blurBackground){
backgroundImageView.image = [backgroundImage croppedToRect:CGRectMake(0,window.frame.origin.y + 15, 320, 480 - window.frame.origin.y + 15)];
backgroundImageView.frame = CGRectMake(0,0, 320, 480 - window.frame.origin.y - 15);
}
}


 
}
 
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{

//For when the swipe is released 

//Okay, so I changed it. It doesn't so much detect swipes as much as changes in frame. less customizable and more expandable. 

CGPoint pt = [[touches anyObject] locationInView:self];
float dx = pt.x - startLocation.x;
float dy = pt.y - startLocation.y;

// < is equal to up
// > is equal to down
// y is down/up
// x is left/right

if(window.frame.origin.y <= 420 && !isShowing){
 [controlCenter loadControlCenter]; //Has it been swiped up?  As you go up, you substract from 480 on the screen. 
}

if(window.frame.origin.y <= 100 && isShowing){
 [controlCenter loadControlCenter]; //Has it been swiped up even more and it is already open? Shouldn't close, but rather revert the view back to normal.
}

if(window.frame.origin.y >= 120 && isShowing){
 [controlCenter unloadControlCenter]; //Was it swiped down? Lets unload it.
}

if(window.frame.origin.y <= 119 && isShowing){
 [controlCenter loadControlCenter]; //Is it just above where it should recognize the swipe and close? If so, close!
}

if(window.frame.origin.y >= 420 && !isShowing){
 [controlCenter unloadControlCenter]; //Is it below the height needed to open it? Then lets revert it back to hiding.
}



}
@end

/*
Okay. So, this should clean things up a little. For some reason, you declared control center, but never actually made the subclass so all those instance variables you made are never used.
Either declare them as static, or make an 
@interface SBStatusWindow
//Declarations here
@end
and then those instance variables you made will only work in that method.
*/
@implementation ControlCenter

-(id)initWithFrame:(CGRect)frame{
 self = [super initWithFrame:frame]; //Basic init stuff
 
 if(self){
if([[[UIDevice currentDevice] model] isEqualToString:@"iPhone"]){
isIphone = TRUE;
}

NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//ReloadPreferences();
//Adding this in before any other views

if(blurBackground){
backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,320, 480)];
backgroundImageView.image = [UIImage imageWithContentsOfFile:@"/Library/ControlCenter/Background.png"]; // Doesn't have a blur on the background the first time -__-



[self addSubview:backgroundImageView];
[backgroundImageView release];
}

//So, I move the background to here. For the blurred background, it uses the same image, except with the background color transparent. :) Same effect, but better results ;)
UIImageView *buttonOverlays = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,320,480)];
if(blurBackground){
    buttonOverlays.image = [UIImage imageWithContentsOfFile:@"/Library/ControlCenter/BackgroundBlur.png"];
}
else{
    buttonOverlays.image = [UIImage imageWithContentsOfFile:@"/Library/ControlCenter/Background.png"];
}
[self addSubview:buttonOverlays];
[buttonOverlays release];

infoLabel = [[UILabel alloc] init];
infoLabel.textAlignment = UITextAlignmentCenter;
infoLabel.font = [UIFont boldSystemFontOfSize:15];
infoLabel.frame = CGRectMake(0, 0, 320, 20);
if(blurBackground){
infoLabel.backgroundColor = [UIColor colorWithPatternImage:[backgroundImageView.image croppedToRect:CGRectMake(0,0, 320, 20)]];
}
else{
infoLabel.backgroundColor = [UIColor colorWithRed:213/255.0 green:213/255.0 blue:213/255.0 alpha:1.0];
}
infoLabel.text = @"";
infoLabel.textColor = [UIColor whiteColor];
infoLabel.alpha = 0.0;

songTitleLabel = [[UILabel alloc] init];
songTitleLabel.textAlignment = UITextAlignmentCenter;
songTitleLabel.font = [UIFont boldSystemFontOfSize:15];
songTitleLabel.frame = CGRectMake(0, 100, 320, 100);
[songTitleLabel setBackgroundColor:[UIColor clearColor]];
songTitleLabel.textColor = [UIColor whiteColor];

artistLabel = [[UILabel alloc] init];
artistLabel.textAlignment = UITextAlignmentCenter;
artistLabel.font = [UIFont boldSystemFontOfSize:12];
artistLabel.frame = CGRectMake(0, 150, 320, 40);
[artistLabel setBackgroundColor:[UIColor clearColor]];
artistLabel.textColor = [UIColor blackColor];

[self addSubview:songTitleLabel];
[self addSubview:artistLabel];
[self addSubview:infoLabel];
[infoLabel release];
[songTitleLabel release];
[artistLabel release];

flashLight = [UIButton buttonWithType: UIButtonTypeCustom];
flashLight.frame = CGRectMake(16,320,60,60);
[flashLight addTarget:self action:@selector(flashLight) forControlEvents:UIControlEventTouchUpInside];
[self addSubview:flashLight];

clockOpen = [UIButton buttonWithType: UIButtonTypeCustom];
clockOpen.frame = CGRectMake(92,320,60,60);
[clockOpen addTarget:self action:@selector(loadClock) forControlEvents:UIControlEventTouchUpInside];
[self addSubview:clockOpen];

calculatorOpen = [UIButton buttonWithType: UIButtonTypeCustom];
calculatorOpen.frame = CGRectMake(168,320,60,60);
[calculatorOpen addTarget:self action:@selector(loadCalculator) forControlEvents:UIControlEventTouchUpInside];
[self addSubview:calculatorOpen];

cameraOpen = [UIButton buttonWithType: UIButtonTypeCustom];
cameraOpen.frame = CGRectMake(244,320,60,60);
[cameraOpen addTarget:self action:@selector(loadCamera) forControlEvents:UIControlEventTouchUpInside];
if(isIphone){
[cameraOpen setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/CameraBottom.png"] forState:UIControlStateNormal];
[cameraOpen setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/CameraBottom.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
}
else{
[cameraOpen setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/NotesBottom.png"] forState:UIControlStateNormal];
[cameraOpen setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/NotesBottom.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
}
[self addSubview:cameraOpen];
//end shortcut buttons
//start toggles
Orientation = [UIButton buttonWithType: UIButtonTypeCustom];
Orientation.frame = CGRectMake(251,17,55,55);
[Orientation addTarget:self action:@selector(toggleOrientation) forControlEvents:UIControlEventTouchUpInside];

if(!isOrientationLocked()){
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOff.png"] forState:UIControlStateNormal];
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateHighlighted];
[[%c(SBStatusBarController) sharedStatusBarController] removeStatusBarItem:@"OrientationLock"]; 
}
else{
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateNormal];
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOff.png"] forState:UIControlStateHighlighted];

[[%c(SBStatusBarController) sharedStatusBarController] addStatusBarItem:@"OrientationLock"];

}
[self addSubview:Orientation];

DND = [UIButton buttonWithType: UIButtonTypeCustom];
DND.frame = CGRectMake(191,17,55,55);
[DND addTarget:self action:@selector(isNotUse) forControlEvents:UIControlEventTouchUpInside];
[DND setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/DND.png"] forState:UIControlStateNormal];
[self addSubview:DND];

Bluetooth = [UIButton buttonWithType: UIButtonTypeCustom];
Bluetooth.frame = CGRectMake(131,17,55,55);
[Bluetooth addTarget:self action:@selector(setBluetooth) forControlEvents:UIControlEventTouchUpInside];
[Bluetooth setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/BluetoothOff.png"] forState:UIControlStateNormal];
[Bluetooth setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/BluetoothOn.png"] forState:UIControlStateHighlighted];
[self addSubview:Bluetooth];

Wifi = [UIButton buttonWithType: UIButtonTypeCustom];
Wifi.frame = CGRectMake(71,17,55,55);
[Wifi addTarget:self action:@selector(setWifi) forControlEvents:UIControlEventTouchUpInside];
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOff.png"] forState:UIControlStateNormal];
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOn.png"] forState:UIControlStateHighlighted];
[self addSubview:Wifi];

Airplane = [UIButton buttonWithType: UIButtonTypeCustom];
Airplane.frame = CGRectMake(11,17,55,55);
[Airplane addTarget:self action:@selector(airplaneModeSwitch) forControlEvents:UIControlEventTouchUpInside];
[Airplane setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] forState:UIControlStateNormal];
[Airplane setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
[self addSubview:Airplane];
//end toggles

//Start music controls
prev = [UIButton buttonWithType: UIButtonTypeCustom];
prev.frame = CGRectMake(50,200,40,30);
[prev addTarget:self action:@selector(previousSong) forControlEvents:UIControlEventTouchUpInside];
[prev setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/prevtrack.png"] forState:UIControlStateNormal];
[prev setImage:[[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/prevtrack.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
[self addSubview:prev];

next = [UIButton buttonWithType: UIButtonTypeCustom];
next.frame = CGRectMake(220,200,40,30);
[next addTarget:self action:@selector(nextSong) forControlEvents:UIControlEventTouchUpInside];
[next setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/nexttrack.png"] forState:UIControlStateNormal];
[next setImage:[[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/nexttrack.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
[self addSubview:next];

PlayPause = [UIButton buttonWithType: UIButtonTypeCustom];
PlayPause.frame = CGRectMake(145,200,25,30);
[PlayPause addTarget:self action:@selector(playPause) forControlEvents:UIControlEventTouchUpInside];
if(![[%c(SBMediaController) sharedInstance] isPlaying]){ //If it's not playing, make the button the play button, otherwise it's paused.
[PlayPause setImage:[[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
[PlayPause setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"] forState:UIControlStateNormal];
}
else{
[PlayPause setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"] forState:UIControlStateNormal]; //So it changes :p
[PlayPause setImage:[[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
}
[self addSubview:PlayPause];

//HEEHEEE

//setting some stuff for luminosity
//alloc the luminosity slider
slider = [[UISlider alloc] initWithFrame:CGRectMake(53, 85, 205, 3)];
    [slider addTarget:self action:@selector(sliderLuminosity:) forControlEvents:UIControlEventValueChanged];
    [slider setBackgroundColor:[UIColor clearColor]];
    slider.minimumValue = 0.01f;
    slider.maximumValue = 1.0f;
    slider.continuous = YES;
 slider.userInteractionEnabled = TRUE;
 [slider setMinimumTrackImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/LuminosityMinimum.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal ];
[slider setMaximumTrackImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/LuminosityFull.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal ];
[slider setThumbImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/LuminosityPoint.png"] forState:UIControlStateNormal];
[self addSubview:slider];
[slider release];
[plistDict release];

//volumeSlider
float volume = [[%c(SBMediaController) sharedInstance] volume];
volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(50, 253, 210, 3)];
    [volumeSlider addTarget:self action:@selector(setVolume:) forControlEvents:UIControlEventValueChanged];
    [volumeSlider setBackgroundColor:[UIColor clearColor]];
    volumeSlider.minimumValue = 0.01f;
    volumeSlider.maximumValue = 1.0f;
    volumeSlider.continuous = YES;
    volumeSlider.value = volume;
 volumeSlider.userInteractionEnabled = TRUE;
[volumeSlider setMinimumTrackImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/LuminosityMinimum.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal ];
[volumeSlider setMaximumTrackImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/LuminosityFull.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal ];
[volumeSlider setThumbImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/LuminosityPoint.png"] forState:UIControlStateNormal];
[self addSubview:volumeSlider];
[volumeSlider release];


flashLightView = [[UIView alloc] initWithFrame:CGRectMake(0, -60, 320, 480)];
flashLightView.alpha = 0.0;
flashLightView.backgroundColor = [UIColor whiteColor];

UIButton *flashLightClose = [UIButton buttonWithType: UIButtonTypeCustom];
flashLightClose.frame = CGRectMake(0,0,320,480);
[flashLightClose addTarget:self action:@selector(flashLight) forControlEvents:UIControlEventTouchUpInside];
[flashLightView addSubview:flashLightClose];
[self addSubview:flashLightView];
[flashLightView release];
[pool drain];
 }

 return self;
}



-(void)loadControlCenter{
if(isThisWhited00r){
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
shouldUpdateBackground = FALSE; //So it doesn't update when open.
filePath = @"/var/mobile/Library/Preferences/com.apple.springboard.plist";
plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];

slider.value = [[plistDict objectForKey:@"SBBacklightLevel2"] floatValue]; //Shorter code?
volumeSlider.value = [[%c(SBMediaController) sharedInstance] volume];

if(!isOrientationLocked()){
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOff.png"] forState:UIControlStateNormal];
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateHighlighted];
[[%c(SBStatusBarController) sharedStatusBarController] removeStatusBarItem:@"OrientationLock"]; 
}
else{
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateNormal];
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOff.png"] forState:UIControlStateHighlighted];

[[%c(SBStatusBarController) sharedStatusBarController] addStatusBarItem:@"OrientationLock"];

}

if([self airplaneModeEnabled]){
[Airplane setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] forState:UIControlStateHighlighted];
[Airplane setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateNormal];

}
else{
[Airplane setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] forState:UIControlStateNormal];
[Airplane setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];

}

[self updateWifi];

[self updateMusic:nil];

[UIView beginAnimations:@"curlup" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
[UIView setAnimationDidStopSelector:@selector(openedControlCenter:finished:context:)];
window.frame = CGRectMake(0,60,320,480);
if(blurBackground){
infoLabel.backgroundColor = [UIColor colorWithPatternImage:[backgroundImage croppedToRect:CGRectMake(0,window.frame.origin.y + 15, 320, 20)]];
backgroundImageView.image = [backgroundImage croppedToRect:CGRectMake(0,window.frame.origin.y + 15, 320, 480 - window.frame.origin.y + 15)];
backgroundImageView.frame = CGRectMake(0,0,320, 480 - window.frame.origin.y - 15);
}
[UIView commitAnimations];
 //now its opened, swipe downnnn to close :3

[plistDict release];
[pool drain];
}
}


- (void)openedControlCenter:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
 isShowing = TRUE;
 swipeIt.swipeDirection = @"Down";
 if(blurBackground){
 backgroundImageView.image = [backgroundImage croppedToRect:CGRectMake(0,window.frame.origin.y + 15, 320, 480 - window.frame.origin.y + 15)];

backgroundImageView.frame = CGRectMake(0,0,320, 480 - window.frame.origin.y - 15);
}
}

-(void)unloadControlCenter{
shouldUpdateBackground = TRUE; //So it recreates the image it on load up of the next time :p
[UIView beginAnimations:@"curldown" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
[UIView setAnimationDidStopSelector:@selector(closedControlCenter:finished:context:)]; //call off a method after the animation completes.
window.frame = CGRectMake(0,465,320,480);
if(flashLightView.alpha == 1.0){
flashLightView.alpha = 0.0;
GSEventSetBacklightLevel(oldBrightness);
[[%c(SBBrightnessController) sharedBrightnessController] adjustBacklightLevel:TRUE];
}
[UIView commitAnimations];
[self hideInfoLabel];
}

-(void)closedControlCenter:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
swipeIt.swipeDirection = @"Up";
isShowing = FALSE;
}

-(void)loadCamera{
[self unloadControlCenter];
if(isIphone){
appID = @"com.apple.mobileslideshow"; //Setting the appID before calling off the other method
}
else{
appID = @"com.apple.mobilenotes";
}
//In the updated UI tweak there is code to handle all this intelligently and quickly :) Means if something fails, it's in a central place and easy to debug. Also means nothing breaks randomly from two tweaks using the same code but in different methods.
[[%c(SBUIController) sharedInstance] openAppWithBundleID:appID]; //Using this as I added in another couple of methods and central logic code for this.
}

-(void)loadClock{
[self unloadControlCenter];

[[%c(SBUIController) sharedInstance] openAppWithBundleID:[NSString stringWithFormat:@"com.apple.mobiletimer"]];
}

-(void)loadCalculator{
[self unloadControlCenter];

[[%c(SBUIController) sharedInstance] openAppWithBundleID:[NSString stringWithFormat:@"com.apple.calculator"]];
}

-(void)flashLight{

[UIView beginAnimations:@"flashing" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.2];

    if(flashLightView.alpha == 0.0){
        oldBrightness = slider.value; //So we know what it was before it was opened so it can go back to nromal later :P
        flashLightView.alpha = 1.0;
        GSEventSetBacklightLevel(1.0);
        [[%c(SBBrightnessController) sharedBrightnessController] adjustBacklightLevel:TRUE];
    }
    else{
    	if(![[%c(SBUIController) sharedInstance] isWhited00r]){
    		[self isNotUse];
    	}
    	else{
        flashLightView.alpha = 0.0;
        GSEventSetBacklightLevel(oldBrightness);
        [[%c(SBBrightnessController) sharedBrightnessController] adjustBacklightLevel:TRUE];
    }
    }
[UIView commitAnimations];
}

-(void)sliderLuminosity:(id)sender{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
slider = (UISlider *)sender;
float val = slider.value;
if(![[%c(SBUIController) sharedInstance] isWhited00r]){
	val = 0.0;
}
  GSEventSetBacklightLevel(val);
  filePath = @"/var/mobile/Library/Preferences/com.apple.springboard.plist";
  plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        [plistDict setValue:[NSNumber numberWithFloat:val] forKey:@"SBBacklightLevel2"];
        [plistDict writeToFile:filePath atomically: YES];
  [[%c(SBBrightnessController) sharedBrightnessController] adjustBacklightLevel:TRUE];
  [plistDict release];
  [pool drain];
}

-(void)setVolume:(id)sender{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
volumeSlider = (UISlider *)sender;
float val = volumeSlider.value;

if(![[%c(SBUIController) sharedInstance] isWhited00r]){
val = 1.0;
}
//might need to add more here
  [[%c(SBMediaController) sharedInstance] setVolume:val];
  [pool drain];
}

-(void)updateWifi{
wifi = [[%c(SBWiFiManager) sharedInstance] wiFiEnabled];
if(!wifi){
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOff.png"] forState:UIControlStateNormal];
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOn.png"] forState:UIControlStateHighlighted];
}
else{
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOn.png"] forState:UIControlStateNormal];
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOff.png"] forState:UIControlStateHighlighted];
}
}

-(void)setWifi{
wifi = [[%c(SBWiFiManager) sharedInstance] wiFiEnabled];
if(wifi){
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOff.png"] forState:UIControlStateNormal];
[[%c(SBWiFiManager) sharedInstance] setWiFiEnabled:FALSE];
wifi = FALSE;
[self showInfoLabel:@"WiFi Disabled"]; //Show the disabled info label.
}
else{
[Wifi setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/WifiOn.png"] forState:UIControlStateNormal];
[[%c(SBWiFiManager) sharedInstance] setWiFiEnabled:TRUE];
wifi = TRUE;
[self showInfoLabel:@"WiFi Enabled"];
}
}

-(void)setBluetooth{
if(bluetooth){
[Bluetooth setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/BluetoothOff.png"] forState:UIControlStateNormal];
bluetooth = FALSE;
[self performSelectorInBackground:@selector(toggleBluetooth) withObject:nil]; //So it doesn't freeze for several seconds.

[self showInfoLabel:@"Bluetooth Disabled"];
}
else{
[Bluetooth setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/BluetoothOn.png"] forState:UIControlStateNormal];
bluetooth = TRUE;
[self performSelectorInBackground:@selector(toggleBluetooth) withObject:nil]; //So it doesn't freeze for several seconds.

[self showInfoLabel:@"Bluetooth Enabled"];
}
}

-(void)toggleBluetooth{
[[%c(BluetoothManager) sharedInstance] setEnabled:bluetooth]; //Now this isn't clogging up the main thread ;)
}

-(void)toggleOrientation{
//Checking the bool that is loaded each time :s couldn't get it read from UIKit even using extern BOOl (probably don't understand well enough how that works, but then again this is how even darlo did this as it wrote to a file)
if(isOrientationLocked()){

//Calling off the magic static void!
setOrientationLocked(FALSE);

[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOff.png"] forState:UIControlStateNormal];
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateHighlighted];
[[%c(SBStatusBarController) sharedStatusBarController] removeStatusBarItem:@"OrientationLock"]; //It uses a string as an argument, and it handles the rest automatically. The string should be the name of the images in SpringBoard.app with the prefixes of Default_ and FSO_ (for light and dark status bar)

[self showInfoLabel:@"Rotation lock Disabled"];
}
else{
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateNormal];
[Orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOff.png"] forState:UIControlStateHighlighted];
//[orientation setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/RotationOn.png"] forState:UIControlStateNormal];
setOrientationLocked(TRUE);
//[self performSelectorInBackground:@selector(toggleOrientation) withObject:nil]; //So it doesn't freeze for several seconds.
[[%c(SBStatusBarController) sharedStatusBarController] addStatusBarItem:@"OrientationLock"];
[self showInfoLabel:@"Rotation lock Enabled"];
}
}

-(BOOL)airplaneModeEnabled{
// void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
//Okay, don't ask for this. I really don't understand. This isn't found online anywhere, and the methods found online don't compile.
//I didn't have time to learn it so I did what I do best and patched it together. Intelligently mind you, but I patched two samples from online together because there literally was nothing that worked for 3.1.3.
//I don't know entirely why it works, but it does.
if(isIphone){
    int (*AirplaneMode)();
    *(void **)(&AirplaneMode) = dlsym(RTLD_DEFAULT, "CTPowerGetAirplaneMode");
    int status = AirplaneMode();
    return status;
}
}

-(void)airplaneModeSwitch{
//void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);

if(isIphone){
//It's actually just the two lines after this I don't understand for the whole * and the (void) (&enable) stuff. I have used dlopen before for simpler stuff :P

int (*enable)(int enable);
*(void **)(&enable) = dlsym(RTLD_DEFAULT, "CTPowerSetAirplaneMode");

if(![self airplaneModeEnabled]){
//[[%c(SBTelephonyManager) sharedTelephonyManager] setIsUsingWirelessModem:FALSE];
airplaneMode = TRUE;
[Airplane setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] forState:UIControlStateHighlighted];
[Airplane setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateNormal];
[self showInfoLabel:@"AirPlane Mode Enabled"];
if(enable){
    //(*enable)(1);
    enable(1);
}
}
else{
//[[%c(SBTelephonyManager) sharedTelephonyManager] setIsUsingWirelessModem:TRUE];
[Airplane setImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] forState:UIControlStateNormal];
[Airplane setImage:[[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/AirPlane.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
airplaneMode = FALSE;   
[self showInfoLabel:@"AirPlane Mode Disabled"];
if(enable){
    //(*enable)(0);
    enable(0);
}
}
}
else{
    [self isNotUse];
}

//[self isNotUse];
}

-(void)updateMusic:(NSNotification*)notification{
[self performSelector:@selector(backgroundMusicUpdate) withObject:nil afterDelay:1]; //So it doesn't pause breifly while the buttons update. 
}

-(void)backgroundMusicUpdate{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
BOOL playing = [[%c(SBMediaController) sharedInstance] isPlaying];
id artist = [[%c(SBMediaController) sharedInstance] nowPlayingArtist];
id title = [[%c(SBMediaController) sharedInstance] nowPlayingTitle];
id album = [[%c(SBMediaController) sharedInstance] nowPlayingAlbum];  //What do these return? Aren't they already NSStrings?

songTitleLabel.text = title; //It's an object of NSString, it's already a string.
if(album){
artistLabel.text = [NSString stringWithFormat:@"%@ - %@", artist, album]; 
}
else{
artistLabel.text = artist;
}

//Refresh the button.
if(![[%c(SBMediaController) sharedInstance] isPlaying]){ //If it's not playing, make the button the play button, otherwise it's paused.
[PlayPause setImage:[[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
[PlayPause setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"] forState:UIControlStateNormal];
}
else{
[PlayPause setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"] forState:UIControlStateNormal]; //So it changes :p
[PlayPause setImage:[[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"] tintedImageUsingColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
}
[pool drain];
}

-(void)unlock{
    //In for legacy. No longer used because it's all handled by the UI tweak
[[%c(SBAwayController) sharedAwayController] unlockWithSound:YES];
[self performSelector:@selector(openApp) withObject:nil afterDelay:1.0];
}

-(void)openApp{
//And then going to the homescreen, and then opening the app
closeAndHome = TRUE; //Setting up the bypass for the home button press... Bloody hope this works.
[[%c(SBUIController) sharedInstance] clickedMenuButton]; //So the launch code works :P
[self performSelector:@selector(openBundle) withObject:nil afterDelay:1];
}

-(void)openBundle{
//Opening up the app :P
if(appID){

[[%c(SBUIController) sharedInstance] activateApplicationAnimated:[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:appID]]; //Long but was giving errors for me with my toolchain
}
}

-(void)isNotUse{
UIAlertView *noUseAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, this function is currently not available." delegate:self cancelButtonTitle:@"Got it" otherButtonTitles:nil];
[noUseAlert show];
[window addSubview:noUseAlert];
[noUseAlert release];
}

-(void)showInfoLabel:(NSString*)newText{
[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideInfoLabel) object:nil]; //Canceling the previous code to dismiss the text label.
[infoLabel setText:newText]; //Setting the new text beforehand (before animating it in or out or whatever it is.)
[UIView beginAnimations:@"ShowInfoLabel" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.2];
infoLabel.alpha = 1.0; //Make it visible, but animate it in so it looks like a fade.

[UIView commitAnimations];
[self performSelector:@selector(hideInfoLabel) withObject:nil afterDelay:3.0]; //Run this method after 3 seconds.
}

-(void)hideInfoLabel{
[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideInfoLabel) object:nil]; //In case it was called off beforehand
[UIView beginAnimations:@"HideInfoLabel" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.2];
infoLabel.alpha = 0.0;

[UIView commitAnimations];
}

-(void)playPause{

if(!registeredForMusic){
[[%c(MPMusicPlayerController) iPodMusicPlayer] beginGeneratingPlaybackNotifications]; //Double check it's registering for notifications
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMusic:) name:@"MPMusicPlayerControllerPlaybackStateDidChangeNotification" object:nil]; //Register for song change and stuff...
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMusic:) name:@"MPMusicPlayerControllerNowPlayingItemDidChangeNotification" object:nil];//It does freeze the main thread for a couple seconds on reboot or respring. However, if done in a background thread it won't work at all.
registeredForMusic = TRUE;
}
[[%c(SBMediaController) sharedInstance] togglePlayPause];

//[self performSelectorInBackground:@selector(updateMusic) withObject:nil];
}

-(void)nextSong{
if(!registeredForMusic){
[[%c(MPMusicPlayerController) iPodMusicPlayer] beginGeneratingPlaybackNotifications]; //Double check it's registering for notifications
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMusic:) name:@"MPMusicPlayerControllerPlaybackStateDidChangeNotification" object:nil]; //Register for song change and stuff...
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMusic:) name:@"MPMusicPlayerControllerNowPlayingItemDidChangeNotification" object:nil];//It does freeze the main thread for a couple seconds on reboot or respring. However, if done in a background thread it won't work at all.
registeredForMusic = TRUE;
}
[[%c(SBMediaController) sharedInstance] changeTrack:(1)];
//[self performSelectorInBackground:@selector(updateMusic) withObject:nil];
}

-(void)previousSong{
if(!registeredForMusic){
[[%c(MPMusicPlayerController) iPodMusicPlayer] beginGeneratingPlaybackNotifications]; //Double check it's registering for notifications
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMusic:) name:@"MPMusicPlayerControllerPlaybackStateDidChangeNotification" object:nil]; //Register for song change and stuff...
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMusic:) name:@"MPMusicPlayerControllerNowPlayingItemDidChangeNotification" object:nil];//It does freeze the main thread for a couple seconds on reboot or respring. However, if done in a background thread it won't work at all.
registeredForMusic = TRUE;
}

[[%c(SBMediaController) sharedInstance] changeTrack:(-1)];
//[self performSelectorInBackground:@selector(updateMusic) withObject:nil];
}


- (void)updateWindowLevel:(NSNotification *)notification{
window.hidden = FALSE;
[window makeKeyAndVisible];
window.windowLevel = 9000;	
}
@end


%hook SBWiFiManager

- (void)_powerStateDidChange
{
    //To try and sync up with the system toggle for wifi :p
        %orig;
       if(controlCenter) [controlCenter updateWifi];
}

%end

@interface SBStatusWindow : UIWindow

@end



%hook SBAwayView
-(id)initWithFrame:(CGRect)frame{
self = %orig;
isThisWhited00r = [[%c(SBUIController) sharedInstance] isWhited00r];
if(self){

//If the window doesn't exist, make it once.
if(!window){
if(!loadedPrefs){
    loadPrefs(); //Loading up the magic settings :P Only for the background now...
}
CGRect viewRect = CGRectMake(0, 15, 320, 480); //Changed this to 15 because I may have ballsed something up in the image I have :P
controlCenter = [[ControlCenter alloc] initWithFrame:viewRect]; //Creating the instance of the custom class.
//controlCenter.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithContentsOfFile:@"/Library/ControlCenter/Background.png"]];
controlCenter.backgroundColor = [UIColor clearColor]; //Better....  I set it as a subview so the blur is happy.
controlCenter.userInteractionEnabled = YES;

window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 465, 320, 480)]; //x, y, width, height
window.windowLevel = 9000;
window.alpha = 1.0;
window.userInteractionEnabled = TRUE;
window.backgroundColor = [UIColor clearColor];

[window addSubview:controlCenter];

[window makeKeyAndVisible];

window.hidden = FALSE;

//allocate the swiperecognizer we just coded
swipeIt = [[SwipeRecognizer alloc] initWithFrame:CGRectMake(0,0,320,30)];
swipeIt.image = [UIImage imageWithContentsOfFile:@"/Library/ControlCenter/SwipeIt.png"]; //Set the image as the image not the background color...
//swipeIt.backgroundColor = [UIColor blueColor];
swipeIt.delegate = controlCenter; //So now the subclass has a reference to the main code ;) (or rather the instance of ControlCenter now)
swipeIt.swipeDirection = @"Up";
swipeIt.userInteractionEnabled = TRUE;

[window addSubview:swipeIt];

[[NSNotificationCenter defaultCenter] addObserver:controlCenter  selector:@selector(updateWindowLevel:)  name:UIApplicationDidFinishLaunchingNotification  object:nil];
[controlCenter release];
}


 //otherwise, if the window exist, make it do this
window.hidden = FALSE;
[window makeKeyAndVisible];
window.windowLevel = 9000;



isLoaded = TRUE;

}

/*else{
UIAlertView *roar = [[UIAlertView alloc] initWithTitle:@"BUGGER" message:@"This only works on wd7 ;)" delegate:self cancelButtonTitle:@"I am stupid, sorry" otherButtonTitles:nil];
[roar show];
[roar release];
}*/

return self;

}


%end



%hook SBAwayController
-(void)lock{ //Hooking this to handle when the screen locks.
 %orig;
 if(isShowing && controlCenter){
  [controlCenter unloadControlCenter];
 }
isLocked = TRUE;
}

-(void)_undimScreen{ //Hooked this to handle when the screen is locked and the control center is open.
 %orig;
 if(isShowing && controlCenter){
  [controlCenter unloadControlCenter];
 }
}

-(BOOL)handleMenuButtonTap{ //Lockscreen handles home button presses itself.
 if(isShowing && controlCenter){
  [controlCenter unloadControlCenter];
 }

 return %orig;

}

-(BOOL)handleMenuButtonDoubleTap{ //Double press it. Oh yes.
 if(isShowing && controlCenter){
  [controlCenter unloadControlCenter];
 }

 return %orig;
}

-(void)unlockWithSound:(BOOL)sound{
%orig;
isLocked = FALSE;
}

%end

%hook SBUIController
-(BOOL)clickedMenuButton{ //Might screw with bruce and a lotttt of other things... Maybe it's best to return %orig always. I say that because bruce and this tweak even rely on it closing to the homescreen and it would require re-writing this and more logic code in all the tweaks that depend on it to make it only do it for this.
 if(isShowing && controlCenter){
  [controlCenter unloadControlCenter];
  if(closeAndHome){
   closeAndHome = FALSE; //Resetting it...
   return %orig;
  }
 }
else{
 return %orig; //It's not showing controlCenter... run the original code!
}

}

%end

%hook bruceBanner
-(void)bannerPressed{ //Hooking my own bloody tweak -___- I must be crazy.
//Even though they use different launch methods now and don't require going home, maybe it is best to do this? Or maybe just dismiss control center...
if(controlCenter && isShowing) [controlCenter unloadControlCenter]; //Not in the current release, just something I noticed I should use :P 
closeAndHome = TRUE; 
%orig;
}

%end


@interface UIApplication (Orientation)
BOOL internalOrientationLocked;
-(void)setOrientationLocked:(BOOL)locked;
@end


%hook UIApplication
/*
-(BOOL)handleEvent:(GSEventRef)event{
if (event){
    if (GSEventGetType(event) == 50){
        if (orientationLocked){
            return nil;
        }
    }
}
return %orig;
}
*/


-(BOOL)handleEvent:(GSEventRef)event withNewEvent:(GSEventRef)newEvent{
if (event){
    if (GSEventGetType(event) == 50 || GSEventGetType(newEvent) == 50){
        if (isOrientationLocked()){ //grabbing that bool that reads from a file ;)
             //[controlCenter isNotUse];
            //So it doesn't return anything and thus doesn't rotate.
            return nil;
        }
    }
}
return %orig;
}

/*
-(void)setUIOrientation:(int)orientation{
    if(orientationLocked){
       
        %orig(0);
    }
    else{
        %orig;
    }
}
*/
%end

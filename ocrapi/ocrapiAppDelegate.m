//
//  ocrapiAppDelegate.m
//  ocrapi
//
//  Created by iBrad on 29/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ocrapiAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "Singleton.h"
#import <Parse/Parse.h>

#import "ZipFile.h"
#import "ZipWriteStream.h"
#include <sys/xattr.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@implementation ocrapiAppDelegate

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@synthesize window=_window;
@synthesize viewController=_viewController;
@synthesize btnclk;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    sleep(.5);
    launchCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"theLaunchCount"];
    launchCount ++;
    [self readySounds];
    [[NSUserDefaults standardUserDefaults] setInteger:launchCount forKey:@"theLaunchCount"];
    if (launchCount == 1) {
        NSArray *languageArray = [NSMutableArray arrayWithObjects:@"Arabic", @"Bulgarian", @"Catalan",@"Czech", @"Chinese Simplified", @"Chinese Traditional", @"Danish", @"Dutch", @"German", @"Greek", @"English", @"Finnish", @"French", @"Hebrew", @"Hindi", @"Croatian", @"Hungarian", @"Indonesian", @"Italian", @"Japanese", @"Korean", @"Latvian", @"Lithuanian", @"Norwegian", @"Polish", @"Portuguese", @"Romanian", @"Russian", @"Slovak", @"Slovenian", @"Spanish", @"Serbian", @"Swedish", @"Tagalog", @"Thai", @"Turkish", @"Ukrainian", @"Vietnamese", nil];
        [[NSUserDefaults standardUserDefaults] setObject:languageArray forKey:@"LanguageArray"];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"en" forKey:@"theLanguageabr"];
        [[NSUserDefaults standardUserDefaults] setObject:@"English" forKey:@"LanguageText"];
    }
    
    //Crash-Reporting Service
    [Fabric with:@[CrashlyticsKit]];
    
    //Initialize Firebase
    [FIRApp configure];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AutoBorder"];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Appirater launcher
    [Appirater setAppId:@"486512712"];
    [Appirater appLaunched:YES];
    
    //Push Notifications
    [Parse setApplicationId:@"8BJfAdikK8lUlEnzTzSgFuZbnyvoiWL0wjVeX4Q7"
                  clientKey:@"6ydJe1vJ0AdioFMDDPwc7iZlt1DOPaScMfcXnVD8"];
    // Register for push notifications (iOS 8 Compatibility)
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // use registerUserNotificationSettings
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [application registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    
    NSString *suffixString = @"NotesList";
    self.viewController = [[[NotesList alloc] initWithNibName:suffixString bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

//Push Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    [PFPush storeDeviceToken:newDeviceToken]; // Send parse the device token
    // Subscribe this user to the broadcast channel, ""
    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Successfully subscribed to the broadcast channel.");
        } else {
            NSLog(@"Failed to subscribe to the broadcast channel.");
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}
///////////////////////////

- (void)readySounds {
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    NSBundle * mainBundle = [NSBundle mainBundle];
    self.btnclk = [[self newAudioPlayerForFile:@"ButtonClick" extension:@"mp3" inBundle:mainBundle] autorelease];
    [pool release], pool = nil;
}

- (void)playButtonClick {
    btnclk.currentTime = 0;
    [self.btnclk play];
}

- (AVAudioPlayer *)newAudioPlayerForFile:(NSString *)fileName extension:(NSString *)extension inBundle:(NSBundle *)bundle
{
    assert(fileName && extension && bundle);
    NSURL *url = [bundle URLForResource:fileName withExtension:extension];
    if (nil == url) {
        assert(0 && "could not locate resource");
        return nil;
    }
    
    NSError * error = 0;
    AVAudioPlayer * spieler = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    assert(spieler);
    
    if (nil != error) {
        NSLog(@"Error encountered creating audio player for file (%@): %@", fileName, error);
        [spieler release], spieler = nil;
        return nil;
    }
    
    [spieler prepareToPlay];
    [spieler setDelegate:self];
    
    return spieler;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //Also save objects to documents directory for iTunes File Sharing
    //So get the title from the dict in array and check if it has been saved before
    NSArray *cellArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"cellArray"];
    for (NSDictionary *dict in cellArray) {
        NSString *OCRtitle = [NSString stringWithFormat:@"%@.zip", [dict objectForKey:@"Title"]];
        NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* foofile = [documentsPath stringByAppendingPathComponent:OCRtitle];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:foofile];
        //If not, convert to .zip and save to documents directory
        if (!fileExists) {
            NSString *path = [self getZip:dict];
            //Take .zip and save to documents directory
            [[NSData dataWithContentsOfFile:path] writeToFile:path atomically:YES];
            [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:cellArray forKey:@"cellArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)getZip:(NSDictionary*)dict {
    NSString *titleText = [dict objectForKey:@"Title"];
    NSString *OCRtitle = [NSString stringWithFormat:@"%@.zip", titleText];
    NSData *fullImage = [dict objectForKey:@"OCRImage"];
    NSData *textData = [[dict objectForKey:@"OCRText"] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:OCRtitle];
    ZipFile *readFile = [[ZipFile alloc] initWithFileName:path mode:ZipFileModeCreate];
    
    //Get image and text in zip and write
    NSString *pictureTitle = [NSString stringWithFormat:@"%@ (Image).png", titleText];
    ZipWriteStream *imageWrite = [readFile writeFileInZipWithName:pictureTitle compressionLevel:ZipCompressionLevelFastest];
    [imageWrite writeData:fullImage];
    [imageWrite finishedWriting];
    //Write the .txt file
    NSString *textTitle = [NSString stringWithFormat:@"%@ (Text).txt", titleText];
    ZipWriteStream *textWrite = [readFile writeFileInZipWithName:textTitle compressionLevel:ZipCompressionLevelFastest];
    [textWrite writeData:textData];
    [textWrite finishedWriting];
    [readFile close];
    [readFile release];
    
    return path;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [Appirater appEnteredForeground:YES];
}

- (void)dealloc {
    [_window release];
    [_viewController release];
    [btnclk release]; btnclk = nil;
    [super dealloc];
}

@end

@implementation NSFileManager (DoNotBackup)

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    return [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
}

@end

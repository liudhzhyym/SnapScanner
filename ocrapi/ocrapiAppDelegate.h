//
//  ocrapiAppDelegate.h
//  ocrapi
//
//  Created by iBrad on 29/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NotesList.h"
#import "Appirater.h"

@import Firebase;

@interface ocrapiAppDelegate : NSObject <UIApplicationDelegate, AVAudioPlayerDelegate> {
    int launchCount;
    AVAudioPlayer *btnclk;
}
@property (nonatomic, retain) AVAudioPlayer *btnclk;
- (NSString*)getZip:(NSDictionary*)dict;
- (void)readySounds;
- (void)playButtonClick;
- (AVAudioPlayer *)newAudioPlayerForFile:(NSString *)fileName extension:(NSString *)extension inBundle:(NSBundle *)bundle;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NotesList *viewController;

@end

@interface NSFileManager (DoNotBackup)

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

@end

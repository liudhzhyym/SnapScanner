//
//  Singleton.h
//  AppFall3
//
//  Created by Brad Chessin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NotesList.h"
#import "NoteDetailView.h"

@interface Singleton : NSObject {
    NSMutableDictionary *dictionary;
    UIImage *croppedImage;
    NSURLConnection *ocrConnection;
    NSMutableDictionary *reocrDict;
}

@property (assign) NSURLConnection *ocrConnection;
@property (nonatomic, retain) NSMutableDictionary *dictionary;
@property (assign) UIImage *croppedImage;
@property (nonatomic, retain) NSMutableDictionary *reocrDict;
@property (assign) int infoRow;

+(Singleton*)sharedSingleton;
@end

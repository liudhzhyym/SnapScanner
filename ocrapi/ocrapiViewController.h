//
//  ocrapiViewController.h
//  ocrapi
//
//  Created by iBrad on 29/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OcrApiManagerDelegate.h"
#import "NotesList.h"

@class NotesList;

// Implement PostHttpDataManager delegate to process the post events to the OCR API
@interface ocrapiViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, OcrApiManagerDelegate> {
    
        IBOutlet NotesList *notesView;
        IBOutlet UITextView *textView;  
        IBOutlet UIImageView *noimageAvailable;
        IBOutlet UITextField *titletextField;
        UIImage *resizedImage;
        
        UILabel *lblImgSelected;
        UIButton *imgPic;
        UIActivityIndicatorView *activityIndicator;
        NSMutableArray *cellArray;
        
        //Screen Sizes
        int kWidth;
        int kHeight;
        
        BOOL isSaved;
    
        //iPad
        IBOutlet UIButton *photolibrarybutton;
        UIPopoverController *popoverController;
    
        //Accounts
        NSArray *accountArray;
    
        //iOS 4 iPad tintColor
        IBOutlet UINavigationItem *navigationBar;
}
// GUI Controls
@property (nonatomic, retain) IBOutlet UIButton *imgPic;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic) BOOL isSaved;
@property (nonatomic, retain) NSArray *accountArray;

@property (nonatomic, retain) NSMutableArray *cellArray;

- (IBAction)switchViews;
- (IBAction)useCamera;
- (IBAction)usePhotoLibrary;
- (IBAction)saveOCRNote;
- (IBAction)savePhoto;

- (IBAction)photoLibraryiPad;

// Methods
- (void) startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate withType:(UIImagePickerControllerSourceType)sourceType;
- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end

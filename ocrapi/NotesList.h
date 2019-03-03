//
//  NotesList.h
//  ocrapi
//
//  Created by Brad Chessin on 12/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoteDetailView.h"
#import "CustomCell.h"
#import <MessageUI/MessageUI.h>

#import "IPDFCamera.h"
#import "CLImageEditor.h"

@class NoteDetailView;
@class CustomCell;

@import Firebase;

@interface NotesList : UIViewController <UIPopoverControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource,CLImageEditorDelegate,IPDFCameraSessionDelegate, MFMailComposeViewControllerDelegate> {
    
    IBOutlet UITableView *thetableView;
    IPDFCamera *camController;
    
    //Views
    IBOutlet NoteDetailView *view3;
    
    //Screen Sizes
    int kWidth;
    int kHeight;
    
    CustomCell *ivCustomTableCell;
    
    //Main View stuff
    UIPopoverController *popoverController;
    
    //Elapsed Time
    int timeInt;
    NSTimer *timeTimer;
    
    //Black Box
    IBOutlet UIView *blackBox;
    IBOutlet UIButton *buttonCancel;
    IBOutlet UILabel *secondsLabel;
    IBOutlet UIImageView *imageView;
    IBOutlet UIActivityIndicatorView *boxIndicator;
    
    //Outlets
    IBOutlet UIButton *editButton;
    IBOutlet UIButton *cameraButton;
    IBOutlet UIButton *photolibrarybutton;
    
    //DidChange textField
    UITextField *tempTextField;
    
    //Rounded UITableViewCorners
    IBOutlet UIView *viewfortableView;
    
    //Language Button
    IBOutlet UIButton *languageButton;
    IBOutlet UIPickerView *pickerView;
    NSArray *languageArray;
    NSString *languageAbr;
    NSString *fulllanguageString;
    
    IBOutlet UIButton *lastImageButton;
    
    UIImagePickerController *thePicker;
    
    BOOL noimagesalertShowing;
    BOOL isfirstEnumeration;
    BOOL isEditing;
    BOOL isreOCR;
    
    NSMutableArray *notesArray;
}
- (void)updateTitle;

@property (nonatomic/*, retain*/) IBOutlet CustomCell *CustomTableCell;
@property (nonatomic/*, retain*/) id labelCellNib;
//@property (nonatomic, retain) IBOutlet UITableView *thetableView;
@property (nonatomic, retain) IBOutlet UIButton *languageButton;
//@property (nonatomic, strong) IPDFCamera *camController;

//Main View Stuff
@property (nonatomic, retain) UIPopoverController *popoverController;

- (IBAction)useCamera;
- (IBAction)usePhotoLibrary:(id)sender;
- (IBAction)lastImageChoose;
- (IBAction)infoAlert;
- (id)labelCellNib;
- (IBAction)changeLanguage;
- (void) startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate withType:(UIImagePickerControllerSourceType)sourceType;
- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
- (void)textFieldDidChange;

- (void)edithelperMethod:(BOOL)isReOCR;

- (IBAction)cancelOCR;
- (IBAction)mdeleteNotes;

@end

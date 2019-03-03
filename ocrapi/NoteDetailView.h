//
//  NoteDetailView.h
//  ocrapi
//
//  Created by Brad Chessin on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotesList.h"
#import "CLImageEditor.h"

@class NotesList;

@interface NoteDetailView : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate, UIPrintInteractionControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate, CLImageEditorDelegate> {
    
    IBOutlet UITextView *textView;
    IBOutlet UITextField *textField;
    IBOutlet UIButton *noteImage;
    
    IBOutlet NotesList *nlView;
    
    //New 3.0 connections
    IBOutlet UILabel *titleLabel;
    IBOutlet UIImageView *topBar;
    IBOutlet UIButton *backArrow;
    
    //Screen Sizes
    int kWidth;
    int kHeight;
    
    BOOL isredoOCR;
    BOOL isDeleted;
    
    NSMutableArray *notesArray;
    NSString *originalOCRTitle;
}

//Share Menu
- (IBAction)share;

- (IBAction)actualswitchViews:(UIImage*)updatedImage;
- (IBAction)copytoClipboard;
- (void)printText;

- (IBAction)saveImage;

- (void)saveDictionary;
- (void)textFieldViewChange;

- (IBAction)deleteNote;
- (IBAction)spellFixer;

- (IBAction)reOCR;
- (IBAction)removeLineBreaks;

- (void) moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end

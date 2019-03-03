//
//  NoteDetailView.m
//  ocrapi
//
//  Created by Brad Chessin on 12/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NoteDetailView.h"

#import "ZipFile.h"
#import "ZipWriteStream.h"

#import <Twitter/TWTweetComposeViewController.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Singleton.h"
#import "ocrapiAppDelegate.h"

#import "SCLAlertView.h"

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface NoteDetailView ()

@end

@implementation NoteDetailView

- (BOOL)textView:(UITextView *)txtView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound ) {
        return YES;
    }
    [txtView resignFirstResponder];
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self textFieldViewChange]; //Shows placeholder now
    return YES;
}

- (void)textFieldViewChange {
    titleLabel.text = textField.text;
    if (textField.text.length >= 1) {
        NSString *title = [NSString stringWithFormat:@"Note %i", [Singleton sharedSingleton].infoRow + 1];
        [textField setPlaceholder:title];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)thetextField {
    [thetextField resignFirstResponder];
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)thetextView {
    [thetextView resignFirstResponder];
    return YES;
}

- (IBAction)copytoClipboard {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = textView.text;
}

- (IBAction)deleteNote {
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert addButton:@"Yes, Delete" actionBlock:^(void) {
        isDeleted = YES;

        //We have to delete data from documents directory
        NSDictionary *dict = [notesArray objectAtIndex:[Singleton sharedSingleton].infoRow];
        NSString *pathToDelete = [dict objectForKey:@"OCRImageName"];
        [self removeImageData:pathToDelete];
        
        [notesArray removeObjectAtIndex:[Singleton sharedSingleton].infoRow];
        [[NSUserDefaults standardUserDefaults] setObject:notesArray forKey:@"cellArray"];
        
        [self actualswitchViews:nil];
    }];
    [alert showWarning:self title:@"Delete Note?" subTitle:@"Are you sure you want to delete this note?" closeButtonTitle:@"No" duration:0.0f];
}

- (void)removeImageData:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:filename];
    NSError *error;
    [fileManager removeItemAtPath:filePath error:&error];
}

- (void)saveDictionary {
    NSMutableDictionary *theDictionary = [Singleton sharedSingleton].dictionary;
    NSString *titleText = [theDictionary objectForKey:@"Title"];
    NSString *ocrText = [theDictionary objectForKey:@"OCRText"];
    if (((isredoOCR) || (![textField.text isEqualToString:titleText]) || (![textView.text isEqualToString:ocrText])) && (!isDeleted)) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"LLL-dd-yyyy, hh:mm aa"];
        [formatter setLocale:[NSLocale currentLocale]];
        NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
        [formatter release];
        
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        
        //New code (prevents a crash based upon Fabric results)
        NSMutableDictionary *oldDict = nil;
        if ([Singleton sharedSingleton].infoRow > notesArray.count) {
            //This would be a crash otherwise so lets handle it properly
            NSUInteger foundObjectIndex = -1;
            for (NSMutableDictionary *dict in notesArray) {
                if ([[dict objectForKey:@"Title"] isEqualToString:originalOCRTitle]) {
                    //So either the image or the OCR text is the same so this will have the index
                    foundObjectIndex = [notesArray indexOfObject:dict];
                    return;
                }
            }
            oldDict = [notesArray objectAtIndex:foundObjectIndex];
        } else {
            //Old Code
            oldDict = [notesArray objectAtIndex:[Singleton sharedSingleton].infoRow];
        }
        
        [newDict addEntriesFromDictionary:oldDict];
        [newDict setObject:textView.text forKey:@"OCRText"];
        if (textField.text.length != 0) {
            [newDict setObject:textField.text forKey:@"Title"];
        } else {
            NSString *title = [NSString stringWithFormat:@"Note %i", [Singleton sharedSingleton].infoRow + 1];
            [newDict setObject:title forKey:@"Title"];
        }
        [newDict setObject:stringFromDate forKey:@"Date"];
        [notesArray replaceObjectAtIndex:[Singleton sharedSingleton].infoRow withObject:newDict];
        [[NSUserDefaults standardUserDefaults] setObject:notesArray forKey:@"cellArray"];
        [newDict release];
        [oldDict release];
        [[Singleton sharedSingleton] setReocrDict:newDict];
    }
}


- (IBAction)actualswitchViews:(UIImage*)updatedImage {
    [self saveDictionary];
    backArrow.alpha = .5;
    //When you do addSubview, it already calls cellForRowAtIndexPath
    int kHeightnew = kHeight/*-20*/;
    
    //Determine Y coord (differs between iOS 6 and 7)
    int viewHeight = 0;
    if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"6.99")) {
        viewHeight = 20;
    }
    
    [nlView.view.layer setFrame:CGRectMake(-kWidth, viewHeight, kWidth, kHeightnew)];
    [self.view.superview addSubview:nlView.view];
    [UIView animateWithDuration:0.4
                     animations:^{
                         [nlView.view.layer setFrame:CGRectMake(0, viewHeight, kWidth, kHeightnew)];
                         [self.view.layer setFrame:CGRectMake(kWidth, viewHeight, kWidth, kHeightnew)];
                     }
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview];
                         if (isredoOCR) {
                             isredoOCR = NO;
                             [[Singleton sharedSingleton] setCroppedImage:updatedImage];
                             [nlView edithelperMethod:YES];
                         }
                     }];
}

- (IBAction)share {
    [textField resignFirstResponder];
    [textView resignFirstResponder];
    
    UIImage *imagetoshare = [noteImage imageForState:UIControlStateNormal];
    NSArray * activityItems = @[textView.text,[NSURL URLWithString:@"http://itunes.apple.com/us/app/ocr-pro/id486512712?mt=8"], imagetoshare];
    UIActivityViewController * activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
    
    /*
    //Get path of zip
    ocrapiAppDelegate *appDelegate = (ocrapiAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *path = [appDelegate getZip:theDictionary];
    NSData *zipData = [NSData dataWithContentsOfFile:path];
     */
}

//Save image to photos app
- (IBAction)saveImage {
    UIImageWriteToSavedPhotosAlbum([noteImage imageForState:UIControlStateNormal],
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showWarning:self title:@"Error!" subTitle:[error localizedDescription] closeButtonTitle:@"Dismiss" duration:0.0f];
    } else {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showNotice:@"Image Saved" subTitle:@"" closeButtonTitle:@"Dismiss" duration:1.0];
    }
}
///////////


//Check if word is real word
- (IBAction)spellFixer {
    NSArray *allWords = [textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //Initialize checker and get current language
    UITextChecker *checker = [[UITextChecker alloc] init];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    for (NSString *word in allWords) {
        if (![self isDictionaryWord:word]) { //Word is not spelled right
            NSRange range = [textView.text rangeOfString:word]; //This gets the NSRange of the mis-spelled word
            NSArray *guesses = [checker guessesForWordRange:NSMakeRange(0, [word length]) inString:word language:language];
            if (guesses.count != 0) {
                NSString *firstGuess = [guesses objectAtIndex:0];
                //Now we got the first guess (most probable) so replace misspelled word with this word using NSRange
                NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:firstGuess];
                [textView setText:newString];
                //If this is not called, there are no guesses and there's nothing we can do about it
            }
        }
    }
    [checker release];
}

-(BOOL)isDictionaryWord:(NSString*)word {
    UITextChecker *checker = [[[UITextChecker alloc] init] autorelease];
    NSString *currentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSRange searchRange = NSMakeRange(0, [word length]);
    NSRange misspelledRange = [checker rangeOfMisspelledWordInString:word range:searchRange startingAt:0 wrap:NO language:currentLanguage];
    return misspelledRange.location == NSNotFound;
}
/////////////////

- (IBAction)removeLineBreaks {
    NSString *trimmedString = [textView.text stringByReplacingOccurrencesOfString:@"\r\n" withString:@" "];
    [textView setText:trimmedString];
}

//Move UITextView if text is hidden
-(void)keyboardWasShown:(NSNotification*)aNotification {
    [self moveTextViewForKeyboard:aNotification up:YES];
}

-(void)keyboardWasHidden:(NSNotification*)aNotification {
    [self moveTextViewForKeyboard:aNotification up:NO];
}

- (void) moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
    if ([textView isFirstResponder]) {
        NSDictionary* userInfo = [aNotification userInfo];
        NSTimeInterval animationDuration;
        UIViewAnimationCurve animationCurve;
        CGRect keyboardEndFrame;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        
        [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
        [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
        [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
        
        [UIView animateWithDuration:animationDuration delay:0 options:animationCurve animations:^{
            if (!up) { [textView setContentOffset:CGPointMake(0.0, 0.0)]; }
            
            CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
            CGRect newFrame = textView.frame;
            if (screenHeight == 480) {
                //Move UITextView
                CGFloat yMove = (up ? keyboardFrame.origin.y - newFrame.size.height - 40 : 252);
                newFrame = CGRectMake(newFrame.origin.x, yMove, newFrame.size.width, newFrame.size.height);
                //Move UIImageView behind it
                UIImageView *behindImageView = (UIImageView*)[self.view viewWithTag:60];
                [behindImageView setFrame:CGRectMake(12, newFrame.origin.y, 296, 218)];
            } else {
                newFrame.size.height -= keyboardFrame.size.height * (up?1:-1);
            }
            textView.frame = newFrame;
        } completion:nil];
    }
}
//////////////////////////////////////////////////

- (IBAction)reOCR {
    [textField resignFirstResponder];
    [textView resignFirstResponder];
    
    UIView *editorView = [self.view viewWithTag:812];
    BOOL containShare = [self.view.subviews containsObject:editorView];
    if (!containShare) {
        UIImage *img = [noteImage imageForState:UIControlStateNormal];
        CLImageEditor *imageEditor = [[CLImageEditor alloc] initWithImage:img];
        imageEditor.view.tag = 812;
        imageEditor.delegate = self;
        
        //Now we have to get rid of the tools within CLImageEditor that we don't use
        CLImageToolInfo *tool = [imageEditor.toolInfo subToolInfoWithToolName:@"CLFilterTool" recursive:NO];
        tool.available = NO;
        
        tool = [imageEditor.toolInfo subToolInfoWithToolName:@"CLEffectTool" recursive:NO];
        tool.available = NO;
        
        tool = [imageEditor.toolInfo subToolInfoWithToolName:@"CLStickerTool" recursive:NO];
        tool.available = NO;
        
        tool = [imageEditor.toolInfo subToolInfoWithToolName:@"CLTextTool" recursive:NO];
        tool.available = NO;
        
        tool = [imageEditor.toolInfo subToolInfoWithToolName:@"CLEmoticonTool" recursive:NO];
        tool.available = NO;
        //////////////////////////////////////////////
        [self presentViewController:imageEditor animated:YES completion:^{}];
    }
}

//CLImageEditor Delegate methods
#pragma mark- CLImageEditor delegate
- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)editedImage
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [editor dismissViewControllerAnimated:YES completion:^{
        isredoOCR = YES;
        [self actualswitchViews:editedImage];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    notesArray = [NSMutableArray array];
    [notesArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"cellArray"]];
}

#pragma mark - View lifecycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat topPadding = window.safeAreaInsets.top;
        self.view.center = CGPointMake(self.view.center.x, ([UIScreen mainScreen].bounds.size.height/2.0f) + topPadding / 2.0f);
        
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        [statusBar setBackgroundColor:[UIColor colorWithRed:83.0/255.0f green:148.0/255.0f blue:194.0/255.0f alpha:1.0f]];
        
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    notesArray = [NSMutableArray array];
    [notesArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"cellArray"]];
    
    // Do any additional setup after loading the view from its nib.
    kWidth = [UIScreen mainScreen].bounds.size.width;
    kHeight = [UIScreen mainScreen].bounds.size.height;
    isDeleted = NO;
    
    NSMutableDictionary *theDictionary = [Singleton sharedSingleton].dictionary;
    originalOCRTitle = [theDictionary objectForKey:@"Title"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *ocrimagepath = [theDictionary objectForKey:@"OCRImageName"];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:ocrimagepath];
    NSData *pngData = [NSData dataWithContentsOfFile:filePath];
    UIImage *image = [UIImage imageWithData:pngData];
    [noteImage setImage:image forState:UIControlStateNormal];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
        //Did Change notification for both text fields for auto-save
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldViewChange)
                                                     name:UITextFieldTextDidChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldViewChange)
                                                     name:UITextViewTextDidChangeNotification object:nil];
    });
    
    textView.backgroundColor = [UIColor clearColor];
    backArrow.alpha = 1;
    
    textField.text = [theDictionary objectForKey:@"Title"];
    textView.text = [theDictionary objectForKey:@"OCRText"];
    
    //Call styleString if you want textView lines to be spaced differently
    //[textView styleString];
    
    titleLabel.text = textField.text;
    
    textView.text = [textView.text stringByReplacingOccurrencesOfString:@"ï»¿" withString:@""];
    textView.text = [textView.text stringByReplacingOccurrencesOfString:@"_" withString:@""];
    
    //Fixes weird bug where topbar and navbar don't show on ipad version
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [topBar setFrame:CGRectMake(0, -1, 768, 72)];
        ////
        UIImageView *navBar = (UIImageView*)[self.view viewWithTag:43];
        [navBar setFrame:CGRectMake(0, 70, 768, 100)];
        ////
        UIImageView *backtField = (UIImageView*)[self.view viewWithTag:44];
        [backtField setFrame:CGRectMake(359, 272, 375, 59)];
    }
    
    //Keeps textview scrolled to top on launch
    NSRange r  = {0,0};
    [textView scrollRangeToVisible:r];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillDisappear:(BOOL)animated {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    });
}

@end

//
//  ocrapiViewController.m
//  ocrapi
//
//  Created by Favaro on 29/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ocrapiViewController.h"
#import "OcrApiManager.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation ocrapiViewController

@synthesize textView;
@synthesize cellArray;
@synthesize imgPic;
@synthesize activityIndicator;
@synthesize isSaved;
@synthesize popoverController;
@synthesize accountArray;

- (IBAction)switchViews {
    if ((isSaved == NO) && (textView.text.length != 0)) {
        [self saveOCRNote];
    }
    CGRect frame = self.view.frame;
    frame.origin.x = CGRectGetMaxX(frame);
    notesView.view.frame = frame;
    [self.view.superview addSubview:notesView.view];    
    [UIView animateWithDuration:0.4 
                     animations:^{
                         CGRect frame = self.view.frame;
                         notesView.view.frame = frame;
                         frame.origin.x -= frame.size.width;
                         self.view.frame = frame;
                     }
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview]; 
                     }];
}

//Main View
- (IBAction)photoLibraryiPad {
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType =
        UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = YES;
        
        UIPopoverController *popover = [[UIPopoverController alloc]
                                        initWithContentViewController:imagePicker];
        self.popoverController = popover;
        [popover release];
        popoverController.delegate = self;
        [self.popoverController presentPopoverFromRect:photolibrarybutton.frame inView:self.view
                              permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [imagePicker release];
    }
}

//---called when the user clicks outside the popover view---
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (IBAction)useCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self startMediaBrowserFromViewController:self usingDelegate:self withType:UIImagePickerControllerSourceTypeCamera];
    } else {
        UIAlertView * alrt = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"This device does not have a camera" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alrt show];
        [alrt release];  
    }
}
- (IBAction)usePhotoLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self startMediaBrowserFromViewController:self usingDelegate:self withType:UIImagePickerControllerSourceTypePhotoLibrary];
    } else {
        UIAlertView * alrt = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"This device does not have a camera" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alrt show];
        [alrt release];  
    }
}
- (IBAction)saveOCRNote {
    if (textView.text.length != 0) {
    UIAlertView *savedAlert = [[UIAlertView alloc] initWithTitle:@"OCR Note Saved" message:@"The OCR from the image has been saved!" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [savedAlert show];
    [savedAlert release]; 
    
    isSaved = YES;
    NSString *title;
    if (titletextField.text.length != 0) {
        title = titletextField.text;
    } else {
        title = [NSString stringWithFormat:@"Note: %i", [self.cellArray count]+1];
    }
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MM-dd-yyyy"];
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    
    //Dictionary
    NSDictionary *cellDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    textView.text, @"OCRText", 
                                    title, @"Title", 
                                    stringFromDate, @"Date", nil];
    
    //Add Array then add it to NSUserDefaults
    self.cellArray = [NSMutableArray array];
    [self.cellArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"cellArray"]];
    [self.cellArray addObject:cellDictionary];
    [[NSUserDefaults standardUserDefaults] setObject:self.cellArray forKey:@"cellArray"];
    } else {
        UIAlertView *savedAlert = [[UIAlertView alloc] initWithTitle:@"Note can't be saved" message:@"There is no OCR Text to be saved!" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [savedAlert show];
        [savedAlert release]; 
    }
}

#pragma mark - Post to Http delegate

- (void) ocrApiPostStarted:(id) sender {
    // Show the acitivty indicator
    [self.activityIndicator startAnimating];
}

- (void) ocrApiPostDidFailed:(id) sender withError:(NSError *)error {
    // Stop the activity indicator
    [self.activityIndicator stopAnimating];
    
    // Show a message with the error
    UIAlertView * alrt = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error while processing the image or posting to the service" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alrt show];
    [alrt release];
}

- (void) ocrApiPostDidFinish:(id) sender withData:(NSData *)data {
    
    //Make vibration to alert user that OCR translation is finished
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    // Stop the acitivty indicator
    [self.activityIndicator stopAnimating];
    // Enable the buttons back

    // Get the result in text format
    NSString * txt = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]; 
    if (txt.length != 0) {
        //Do animations
        [textView setText:txt];
        [UIView animateWithDuration:0.6
                         animations:^{
                             if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                                 // The device is an iPad running iPhone 3.2 or later.
                                 // set up the iPad-specific view
                                 [textView setFrame:CGRectMake(0, 752, 768, 272)];
                                 [imgPic setFrame:CGRectMake(159, 119, 450, 606)];
                             }
                             else {
                                 // The device is an iPhone or iPod touch.
                                 // set up the iPhone/iPod Touch view
                                 [textView setFrame:CGRectMake(0, 308, 320, 172)];
                                 [imgPic setFrame:CGRectMake(92, 142, 136, 159)];
                             }
                             [titletextField setAlpha:1];
                         }];
    } else {
        UIAlertView *alrt = [[UIAlertView alloc] initWithTitle:@"No Text in Image!" message:@"There is no text in the image" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alrt show];
        [alrt release];
    }
    [txt release];
}

- (IBAction)savePhoto {
    if ([imgPic imageForState:UIControlStateNormal] != nil) {
        UIActionSheet *saveSheet = [[UIActionSheet alloc] initWithTitle:@"Would you like to save this image?" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"No" 
                                                 destructiveButtonTitle:nil 
                                                      otherButtonTitles:@"Yes", nil];
        [saveSheet showInView:[self view]];
        [saveSheet release];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex]isEqualToString:@"Yes"]) {
        UIImageWriteToSavedPhotosAlbum([imgPic imageForState:UIControlStateNormal], nil, nil, nil);
        UIAlertView *savedAlert = [[UIAlertView alloc] initWithTitle:@"Image Saved!" message:@"The image was saved to your photo album" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [savedAlert show];
        [savedAlert release];
    }  
}

- (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

#pragma mark - Gallery 

// Methods
- (void) startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate withType:(UIImagePickerControllerSourceType)sourceType {
    
    isSaved = NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = sourceType;
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = delegate;
    
    [controller presentModalViewController: mediaUI animated: YES];
}

// Picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [noimageAvailable setHidden:YES];
    UIImage *originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerEditedImage];  
    [self imageWithImage:originalImage scaledToSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        // Set image
    [imgPic setImage:originalImage forState:UIControlStateNormal];
    
    //Post Image 
    NSString *APIKey = [self.accountArray objectAtIndex:(arc4random() % [self.accountArray count])];
    OcrApiManager * mgr = [[[OcrApiManager alloc] init] autorelease];
    mgr.delegate = self;
    [mgr postImage:originalImage withApiKey:APIKey];
    ////////////////////
    
    // Hide picker selector
    if ([[self popoverController] isPopoverVisible])
    {
        [[self popoverController] setDelegate:nil];
        [[self popoverController] dismissPopoverAnimated:YES];
        [self setPopoverController:nil];
    } else {
        [picker dismissModalViewControllerAnimated:YES];
    }
    picker = nil;
}


// Picker has cancelled
-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // Hide picker selector
    [picker dismissModalViewControllerAnimated:YES];
}


#pragma mark - Keyboard delegate

// Hide keyboard
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Memory management

- (void)dealloc
{
    [imgPic release];
    [activityIndicator release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    //UserName
    //myemail (none-10)
    //Email
    //myemail (none-10)@yahoo.com
    //Password
    //appstore
    self.accountArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"KeyArray"];
    
    kWidth = [UIScreen mainScreen].bounds.size.width;
    kHeight = [UIScreen mainScreen].bounds.size.height;
    
    isSaved = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0) {
            /* Create our tinted buttons */
            [navigationBar setLeftBarButtonItem:nil];
            UISegmentedControl *button = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Save", nil]] autorelease];
            button.momentary = YES;
            button.segmentedControlStyle = UISegmentedControlStyleBar;
            button.tintColor = [UIColor colorWithRed:0/255.0 green:200/255.0 blue:0/255.0 alpha:1];
            [button addTarget:self action:@selector(saveOCRNote) forControlEvents:UIControlEventValueChanged];
            UIBarButtonItem *barButton = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
            [navigationBar setLeftBarButtonItem:barButton];
        }
    }
    
    textView.layer.contents = (id)[UIImage imageNamed:@"iPhoneWallpaperPattern.png"].CGImage;
    
    [titletextField setDelegate:self];
    CALayer *imageLayer = [imgPic layer];
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:8.0];
}


- (void)viewDidUnload
{
    [self setImgPic:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end

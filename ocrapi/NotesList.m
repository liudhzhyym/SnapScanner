//
//  NotesList.m
//  ocrapi
//
//  Created by Brad Chessin on 12/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NotesList.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Singleton.h"
#import "ocrapiAppDelegate.h"
#import "ocrapiAppDelegate.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

#import "IPDFCamera.h"
#import "SCLAlertView.h"

#define isiOS8 ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0)

#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define MAXWIDTH (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 209 : 664)

@implementation NotesList

@synthesize CustomTableCell = ivCustomTableCell;
@synthesize labelCellNib=_labelCellNib;;
@synthesize popoverController;
//@synthesize thetableView;
@synthesize languageButton;

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

//Main View

- (IBAction)usePhotoLibrary:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //iPhone photo library code
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            [self startMediaBrowserFromViewController:self usingDelegate:self withType:UIImagePickerControllerSourceTypePhotoLibrary];
        } else {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            [alert showWarning:self title:@"No Photos" subTitle:@"This device does not have any photos" closeButtonTitle:@"Dismiss" duration:0.0f];
        }
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //iPad photo library code
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
        {
            thePicker = [[UIImagePickerController alloc] init];
            thePicker.delegate = self;
            thePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:thePicker];
            self.popoverController = popover;
            
            popoverController.delegate = self;
            [self.popoverController presentPopoverFromRect:photolibrarybutton.frame inView:self.view
                                  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

- (IBAction)lastImageChoose {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    PHAsset *lastAsset = [fetchResult lastObject];
    CGRect screenSize = [[UIScreen mainScreen] bounds];
    [[PHImageManager defaultManager] requestImageForAsset:lastAsset
                                               targetSize:CGSizeMake(screenSize.size.width, screenSize.size.height)
                                              contentMode:PHImageContentModeAspectFill
                                                  options:PHImageRequestOptionsVersionCurrent
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    if (![blackBox isDescendantOfView:self.view]) {
                                                        [[Singleton sharedSingleton] setCroppedImage:result];
                                                        [self edithelperMethod:NO];
                                                    }
                                                });
                                            }];
}

//UIPickerView Stuff
- (IBAction)changeLanguage {
    BOOL isEnabled = NO;
    [tempTextField resignFirstResponder];
    if (![languageButton.titleLabel.text isEqualToString:@"Done"]) {
        for (int i = 0;i<[languageArray count];i++) {
            if ([languageButton.titleLabel.text isEqualToString:[languageArray objectAtIndex:i]]) {
                [pickerView selectRow:i inComponent:0 animated:NO];
            }
        }
        //Not Done button so Show it
        [languageButton setTitle:@"Done" forState:UIControlStateNormal];
        
        //Make pickerView have a bounce effect to match new UI
        languageButton.userInteractionEnabled = NO;
        [UIView animateWithDuration:.25 animations:^{
            pickerView.center = CGPointMake(kWidth/2, kHeight-pickerView.bounds.size.height/2 - 20);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.15 animations:^{
                pickerView.center = CGPointMake(kWidth/2, kHeight-pickerView.bounds.size.height/2);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.15 animations:^{
                    languageButton.userInteractionEnabled = YES;
                    pickerView.transform = CGAffineTransformIdentity;
                }];
            }];
        }];
    } else {
        //Done button so hide it
        isEnabled = YES;
        [pickerView.layer removeAllAnimations];
        languageButton.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3
                         animations:^{
                             pickerView.center = CGPointMake(kWidth/2, kHeight+pickerView.bounds.size.height/2);
                         } completion:^(BOOL finished) {
                             languageButton.userInteractionEnabled = YES;
                         }];
        if (fulllanguageString) {
            [languageButton setTitle:fulllanguageString forState:UIControlStateNormal];
            [[NSUserDefaults standardUserDefaults] setObject:languageAbr forKey:@"theLanguageabr"];
            
        } else {
            NSString *fullLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:[[NSLocale preferredLanguages] objectAtIndex:0]];
            [languageButton setTitle:fullLanguage forState:UIControlStateNormal];
        }
        
    }
    [editButton setEnabled:isEnabled];
    [cameraButton setEnabled:isEnabled];
    [lastImageButton setEnabled:isEnabled];
    [photolibrarybutton setEnabled:isEnabled];
    [thetableView setAllowsSelection:isEnabled];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([[languageArray objectAtIndex:row] isEqualToString:@"Chinese (Simplified)"]) {
        languageAbr = @"zh-CN";
    } else if ([[languageArray objectAtIndex:row] isEqualToString:@"Chinese (Traditional)"]) {
        languageAbr = @"zh-TW";
    } else if ([[languageArray objectAtIndex:row] isEqualToString:@"Hebrew"]) {
        languageAbr = @"iw";
    } else if ([[languageArray objectAtIndex:row] isEqualToString:@"Norwegian"]) {
        languageAbr = @"no";
    } else if ((![[languageArray objectAtIndex:row] isEqualToString:@"Chinese (Simplified)"]) || (![[languageArray objectAtIndex:row] isEqualToString:@"Chinese (Traditional)"])) {
        languageAbr = [NSLocale canonicalLanguageIdentifierFromString:[languageArray objectAtIndex:row]];
    }
    fulllanguageString = [languageArray objectAtIndex:row];
    [[NSUserDefaults standardUserDefaults] setObject:languageAbr forKey:@"theLanguageabr"];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [languageArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [languageArray objectAtIndex:row];
}

//---called when the user clicks outside the popover view---
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (IBAction)useCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self startMediaBrowserFromViewController:self usingDelegate:self withType:UIImagePickerControllerSourceTypeCamera];
    } else {
        SCLAlertView *alert = [[SCLAlertView alloc] init];
        [alert showWarning:self title:@"No Camera" subTitle:@"This device does not have a camera" closeButtonTitle:@"Dismiss" duration:0.0f];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error  {
    
}

- (IBAction)infoAlert {
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert addButton:@"Email Developer" actionBlock:^(void) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
            mailCont.mailComposeDelegate = self;
            [mailCont setSubject:@"SnapScanner Inquiry"];
            [mailCont setToRecipients:[NSArray arrayWithObject:@"ibradapps@yahoo.com"]];
            [self presentViewController:mailCont animated:YES completion:nil];
        } else {
            SCLAlertView *alertInside = [[SCLAlertView alloc] init];
            [alertInside showWarning:self title:@"Error" subTitle:@"Can't send E-Mail, check your settings and try again" closeButtonTitle:@"Dismiss" duration:0.0f];
        }
    }];
    [alert showInfo:self title:@"Info" subTitle:@"1. You can rename the title of your notes by clicking on the title in each box or in the detail view. \n 2. To delete a note use the edit button and select the rows you want to delete. \n 3. To get the converted text just tap on the row of the note and it will lead you to another view which will tell you your note. \n 4. The Quick Pic button chooses the last image in your that you took on the device and uses it for scanning. \n\n Graphic Design by: \n Charlie Nichols \n charlie.nichols4@gmail.com" closeButtonTitle:@"Dismiss" duration:0.0f];
}

- (IBAction)mdeleteNotes {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"multipleDeleteAlert"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"multipleDeleteAlert"];
        UIAlertView *noTextAlert = [[UIAlertView alloc] initWithTitle:@"Multiple Deletion"
                                                              message:@"Tap on any row you would like deleted. Each selected row will have a checkmark on the right side. When finished, click done to delete the selected rows."
                                                             delegate:self
                                                    cancelButtonTitle:@"Dismiss"
                                                    otherButtonTitles:nil];
        [noTextAlert show];
    }
    
    NSString *addedSuffix = @"";
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2.0) {
        addedSuffix = @"@2x";
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        addedSuffix = @"@2x~ipad";
    }
    NSString *imageName = [NSString stringWithFormat:@"Edit%@.png", addedSuffix];
    if (!isEditing) {
        //Turn into edit mode
        NSString *pressedName = [NSString stringWithFormat:@"Edit_pressed%@.png", addedSuffix];
        [editButton setImage:[UIImage imageNamed:pressedName] forState:UIControlStateNormal];
        isEditing = YES;
    } else {
        //Turn back into normal mode + delete any checked rows
        [editButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        isEditing = NO;
        
        //Code to delete rows
        NSMutableIndexSet *mutableIndexSet = [[NSMutableIndexSet alloc] init];
        NSMutableArray *cellIndicesToBeDeleted = [[NSMutableArray alloc] init];
        for (int i = (int)[thetableView numberOfRowsInSection:0]-1; i >= 0; i--) {
            NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:0];
            if ([[thetableView cellForRowAtIndexPath:p] accessoryType] == UITableViewCellAccessoryCheckmark) {
                //We have to delete data from documents directory
                NSDictionary *dict = [notesArray objectAtIndex:i];
                NSString *pathToDelete = [dict objectForKey:@"OCRImageName"];
                [self removeImageData:pathToDelete];
                
                [cellIndicesToBeDeleted addObject:p];
                [mutableIndexSet addIndex:p.row];
            }
        }
        
        [notesArray removeObjectsAtIndexes:mutableIndexSet];
        [[NSUserDefaults standardUserDefaults] setObject:notesArray forKey:@"cellArray"];
        
        [thetableView beginUpdates];
        [thetableView deleteRowsAtIndexPaths:cellIndicesToBeDeleted withRowAnimation:UITableViewRowAnimationLeft];
        [thetableView endUpdates];
    }
}

- (IBAction)cancelOCR {
    NSURLConnection *connection = [Singleton sharedSingleton].ocrConnection;
    [connection cancel];
    connection = nil; // this is the proper way - release and nil out the property
    
    [blackBox removeFromSuperview];
    
    //Make buttons enabled in back
    [editButton setEnabled:YES];
    [cameraButton setEnabled:YES];
    [lastImageButton setEnabled:YES];
    [photolibrarybutton setEnabled:YES];
    [languageButton setEnabled:YES];
    [thetableView setAllowsSelection:YES];
}

#pragma mark - Post to Http delegate

- (void) ocrApiPostStarted:(id) sender {
    isEditing = NO;
    ocrapiAppDelegate *appDelegate = (ocrapiAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate playButtonClick];
    
    [self.view addSubview:blackBox];
    blackBox.center = self.view.center;
    buttonCancel.layer.cornerRadius = 15;
    blackBox.layer.cornerRadius = 15;
    
    //Do pop in effect for black box
    [blackBox setTransform:CGAffineTransformMakeScale(0.1, 0.1)];
    [UIView animateWithDuration:0.25 animations:^{
        blackBox.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.125 animations:^{
            blackBox.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.125 animations:^{
                blackBox.transform = CGAffineTransformIdentity;
            }];
        }];
    }];
    ///////////////////
    
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"ThumbImage"];
    [imageView setImage:[UIImage imageWithData:data]];
    
    //Make buttons disabled in back
    [editButton setEnabled:NO];
    [cameraButton setEnabled:NO];
    [lastImageButton setEnabled:NO];
    [photolibrarybutton setEnabled:NO];
    [languageButton setEnabled:NO];
    [thetableView setAllowsSelection:NO];
}

- (void) ocrApiPostDidFailed:(id) sender withError:(NSError *)error {
    
    //Make buttons enabled in back
    [editButton setEnabled:YES];
    [cameraButton setEnabled:YES];
    [lastImageButton setEnabled:YES];
    [photolibrarybutton setEnabled:YES];
    [languageButton setEnabled:YES];
    [thetableView setAllowsSelection:YES];
    
    [blackBox removeFromSuperview];
    
    if ([notesArray count] != 0) {
        [viewfortableView setHidden:NO];
        [thetableView setHidden:NO];
    }
    
    // Show a message with the error
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert showWarning:self title:@"No Text" subTitle:@"There was no text found in the image." closeButtonTitle:@"Dismiss" duration:0.0f];
}

- (void) ocrApiPostDidFinish:(id)sender withText:(NSString*)txt {
    [[Singleton sharedSingleton] setCroppedImage:nil];
    [[Singleton sharedSingleton] setOcrConnection:nil];
    
    //Both need updated dates/images so do that code here
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"LLL-dd-yyyy, hh:mm aa"];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString *stringDate = [formatter stringFromDate:[NSDate date]];
    //Images are updated from reocr images since they are done in edithelpermethod
    NSString *imageDataName = [[NSUserDefaults standardUserDefaults] objectForKey:@"ImageDataName"];
    NSData *tbImage = [[NSUserDefaults standardUserDefaults] objectForKey:@"ThumbImage"];
    //The only thing that is kept for a "Re-OCR is the title so we can just do below
    NSString *titleString = @"";
    if (isreOCR) {
        NSMutableDictionary *rocrDict = [Singleton sharedSingleton].reocrDict;
        titleString = [rocrDict objectForKey:@"Title"];
    } else {
        titleString = [NSString stringWithFormat:@"Note %i", (int)[notesArray count]+1];
    }
    //Create the new dictionary with updated values
    NSMutableDictionary *cellDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           txt, @"OCRText",
                                           imageDataName, @"OCRImageName",
                                           titleString, @"Title",
                                           stringDate, @"Date",
                                           tbImage, @"ThumbImage",
                                           nil];
    //Determine again (mandatory) in order to replace ocr or add as new ocr
    if (isreOCR) {
        [notesArray replaceObjectAtIndex:[Singleton sharedSingleton].infoRow withObject:cellDictionary];
    } else {
        [notesArray addObject:cellDictionary];
    }
    [[NSUserDefaults standardUserDefaults] setObject:notesArray forKey:@"cellArray"];
    [thetableView reloadData];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ThumbImage"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ImageDataName"];
    
    //Make buttons enabled in back
    [editButton setEnabled:YES];
    [cameraButton setEnabled:YES];
    [lastImageButton setEnabled:YES];
    [photolibrarybutton setEnabled:YES];
    [languageButton setEnabled:YES];
    [thetableView setAllowsSelection:YES];
    
    [blackBox removeFromSuperview];
    
    if ([notesArray count] != 0) {
        [viewfortableView setHidden:NO];
        [thetableView setHidden:NO];
    }
}

#pragma mark - Gallery

// Methods
- (void) startMediaBrowserFromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate withType:(UIImagePickerControllerSourceType)sourceType {
    if ((isiOS8) && (sourceType == UIImagePickerControllerSourceTypeCamera))  {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if(status == AVAuthorizationStatusAuthorized) {
            camController = [[IPDFCamera alloc] initWithNibName:@"IPDFViewController" bundle:nil];
            camController.cameraDelegate = self;
        
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [controller presentViewController:camController animated:YES completion:^{}];
            } else {
                [self createPopOver:camController];
            }
        } else {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            [alert showWarning:self title:@"No Camera Access" subTitle:@"Go to the settings applications and allow access for ScapScanner to use the camera." closeButtonTitle:@"Dismiss" duration:0.0f];
        }
    } else {
        thePicker = [[UIImagePickerController alloc] init];
        thePicker.sourceType = sourceType;
        thePicker.delegate = delegate;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [controller presentViewController:thePicker animated:YES completion:^{}];
        } else {
            [self createPopOver:thePicker];
        }
    }
}

- (void)IPDFdidCaptureImage:(UIImage *)image {
    [camController dismissViewControllerAnimated:YES completion:^{}];
    [self gotPicture:image];
}

- (void)createPopOver:(UIViewController*)controller {
    UIPopoverController *popover = nil;
    popover = [[UIPopoverController alloc] initWithContentViewController:controller];
    self.popoverController = popover;
    popoverController.delegate = self;
    [self.popoverController presentPopoverFromRect:cameraButton.frame inView:self.view
                          permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)edithelperMethod:(BOOL)redoocr {
    isreOCR = redoocr;
    //Full Size Image
    UIImage *editedImage = [Singleton sharedSingleton].croppedImage;
    
    NSString *myUniqueName = [NSString stringWithFormat:@"%@-%lu", @"OCRImage", (unsigned long)([[NSDate date] timeIntervalSince1970]*10.0)];
    NSData *pngData = UIImagePNGRepresentation(editedImage);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    NSString *filePath = [documentsPath stringByAppendingPathComponent:myUniqueName]; //Add the file name
    [pngData writeToFile:filePath atomically:YES]; //Write the file
    [[NSUserDefaults standardUserDefaults] setObject:myUniqueName forKey:@"ImageDataName"];
    
    //Thumbnail Image
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize fullSize = CGSizeMake(imageView.frame.size.width * scale, imageView.frame.size.height * scale);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *originalthumbImage = [self imageWithImage:editedImage scaledToSize:fullSize];
        [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(originalthumbImage) forKey:@"ThumbImage"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self ocrApiPostStarted:nil];
        });
        
        FIRVision *vision = [FIRVision vision];
        FIRVisionTextRecognizer *textRecognizer = [vision onDeviceTextRecognizer];
        FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:editedImage];
        [textRecognizer processImage:image
                          completion:^(FIRVisionText *_Nullable result,
                                       NSError *_Nullable error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  if (error != nil || result == nil) {
                                      [self ocrApiPostDidFailed:nil withError:error];
                                      return;
                                  }
                                  
                                  // Recognized text
                                  [self ocrApiPostDidFinish:nil withText:result.text];
                              });
                          }];
    });
    
    // Hide picker selector
    [self dismissPopover];
    
    thePicker = nil;
}

// Picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *originalImage = (UIImage*)[info objectForKey:UIImagePickerControllerOriginalImage];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *newImage = [self imageWithImage:originalImage scaledToSize:screenSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [picker dismissViewControllerAnimated:NO completion:^{}];
            [self gotPicture:newImage];
        });
    });
}

- (void)gotPicture:(UIImage *)image {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    CLImageEditor *imageEditor = [[CLImageEditor alloc] initWithImage:image];
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
    
    if (![self dismissPopover]) {
        [thePicker dismissViewControllerAnimated:NO completion:nil];
    }
    
    thePicker = nil;
    
    [self presentViewController:imageEditor animated:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? NO : YES) completion:^{}];
}

//////////////////////////////////
//CLImageEditor Delegate methods
#pragma mark- CLImageEditor delegate
- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)editedImage
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[Singleton sharedSingleton] setCroppedImage:editedImage];
    [self edithelperMethod:NO];
    [editor dismissViewControllerAnimated:YES completion:nil];
}
//////////////////////////////////

- (BOOL)dismissPopover {
    if ([[self popoverController] isPopoverVisible]) {
        [[self popoverController] setDelegate:nil];
        [[self popoverController] dismissPopoverAnimated:YES];
        [self setPopoverController:nil];
        return YES;
    } else {
        return NO;
    }
}

// Picker has cancelled
-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [thePicker dismissViewControllerAnimated:YES completion:nil];
}
//////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([notesArray count] == 0) {
        [viewfortableView setHidden:YES];
        [thetableView setHidden:YES];
    }
    return [notesArray count];
}

- (id)labelCellNib {
    if (!_labelCellNib) {
        Class cls = NSClassFromString(@"UINib");
        if ([cls respondsToSelector:@selector(nibWithNibName:bundle:)]) {
            _labelCellNib = [cls nibWithNibName:@"CustomCell" bundle:[NSBundle mainBundle]];
        }
    }
    return _labelCellNib;
}

- (void)backgroundShouldReturn:(CustomCell*)cell {
    NSIndexPath *indexPath = [thetableView indexPathForCell:cell];
    UITextField *topField = (UITextField*)[cell viewWithTag:2];
    NSMutableDictionary *oldDictionary = [notesArray objectAtIndex:indexPath.row];
    
    //Done button on keyboard or click of cell
    CGFloat newWidth = 0;
    NSString *topFieldText = @"";
    if (topField.text.length == 0) {
        topFieldText = [NSString stringWithFormat:@"Note %i", (int)(indexPath.row) + 1];
        [topField setPlaceholder:topFieldText];
    } else {
        [topField setPlaceholder:@""];
        topFieldText = topField.text;
    }
    newWidth = [topField.text sizeWithAttributes:@{NSFontAttributeName: topField.font}].width;
    //Adjust UITextField width to size of text with max width
    if (newWidth <= MAXWIDTH) {
        topField.frame = CGRectMake(topField.frame.origin.x, topField.frame.origin.y, newWidth + 3, topField.frame.size.height);
    }
    
    //Dictionary
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    [newDict addEntriesFromDictionary:oldDictionary];
    [newDict setObject:topFieldText forKey:@"Title"];
    [notesArray replaceObjectAtIndex:indexPath.row withObject:newDict];
    [[NSUserDefaults standardUserDefaults] setObject:notesArray forKey:@"cellArray"];
}

-(BOOL)textFieldShouldReturn:(UITextField *)thetextField {
    if (thetextField.placeholder.length >= 1) {
        thetextField.text = thetextField.placeholder;
    }
    [thetextField removeTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    tempTextField = nil;
    [thetextField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)thetextField {
    //Do this if check to make any possible placeholder text regular text
    if (tempTextField.placeholder.length >= 1) {
        tempTextField.text = tempTextField.placeholder;
    }
    UIView *cell = thetextField;
    while (cell != nil && ![cell isKindOfClass:[CustomCell class]]) {
        cell = [cell superview];
    }
    tempTextField = (UITextField*)[cell viewWithTag:2];
    [thetextField addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    return YES;
}

- (void)textFieldDidChange {
    UIView *view = tempTextField;
    while (view != nil && ![view isKindOfClass:[CustomCell class]]) {
        view = [view superview];
    }
    [self performSelector:@selector(backgroundShouldReturn:) withObject:view];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomCell *cell = (CustomCell *)[aTableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        if ([self labelCellNib]) {
            [[self labelCellNib] instantiateWithOwner:self options:nil];
        } else {
            [[NSBundle mainBundle] loadNibNamed:@"CustomCell" owner:self options:nil];
        }
        cell = [self CustomTableCell];
        [self setCustomTableCell:nil];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSMutableDictionary *dictionary = [notesArray objectAtIndex:indexPath.row];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.previewPicture.image = [UIImage imageWithData:[dictionary objectForKey:@"ThumbImage"]];
    
    cell.titleLabel.text = [dictionary objectForKey:@"Title"];
    cell.titleLabel.delegate = self;
    //Adjust UITextField width to size of text with max width
    
    CGFloat newWidth = [cell.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: cell.titleLabel.font}].width;
    if (newWidth <= MAXWIDTH) {
        cell.titleLabel.frame = CGRectMake(cell.titleLabel.frame.origin.x, cell.titleLabel.frame.origin.y, newWidth + 3, cell.titleLabel.frame.size.height);
    }
    cell.dateLabel.text = [dictionary objectForKey:@"Date"];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 94;
}

- (void)backgroundDidSelectRow:(NSIndexPath*)indexPath {
    NSMutableDictionary *dictionary = [notesArray objectAtIndex:indexPath.row];
    [[Singleton sharedSingleton] setDictionary:dictionary];
    [[Singleton sharedSingleton] setInfoRow:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!isEditing) {
        NSMutableDictionary *dictionary = [notesArray objectAtIndex:indexPath.row];
        [[Singleton sharedSingleton] setDictionary:dictionary];
        [[Singleton sharedSingleton] setInfoRow:indexPath.row];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [view3.view.layer setFrame:CGRectMake(kWidth, self.view.frame.origin.y, kWidth, kHeight)];
        [self.view.superview addSubview:view3.view];
        [UIView animateWithDuration:0.4
                         animations:^{
                             [view3.view.layer setFrame:CGRectMake(0, self.view.frame.origin.y, kWidth, kHeight)];
                             [self.view.layer setFrame:CGRectMake(-kWidth, self.view.frame.origin.y, kWidth, kHeight)];
                         }
                         completion:^(BOOL finished){
                             [self.view removeFromSuperview];
                         }];
    } else {
        CustomCell *cell = (CustomCell*)[thetableView cellForRowAtIndexPath:indexPath];
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //We have to delete data from documents directory (for single row deletion)
    NSInteger rowToDelete = 0;
    for (NSDictionary *dict in notesArray) {
        NSDictionary *currentDict = [Singleton sharedSingleton].dictionary;
        if ([[dict objectForKey:@"Title"] isEqualToString:[currentDict objectForKey:@"Title"]] == YES) {
            rowToDelete = [notesArray indexOfObject:dict];
        }
    }
    
    NSDictionary *dict = [notesArray objectAtIndex:rowToDelete];
    NSString *pathToDelete = [dict objectForKey:@"OCRImageName"];
    [self removeImageData:pathToDelete];
    
    [notesArray removeObjectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:notesArray forKey:@"cellArray"];
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:[NSMutableArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
    [tableView endUpdates];
    
}

- (void)removeImageData:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:filename];
    NSError *error;
    [fileManager removeItemAtPath:filePath error:&error];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (void)keyboardNotification:(NSNotification*)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIView *cell = tempTextField;
    while (cell != nil && ![cell isKindOfClass:[CustomCell class]]) {
        cell = [cell superview];
    }
    CGRect textFieldRect = [tempTextField convertRect:tempTextField.frame toView:self.view];
    if (textFieldRect.origin.y + textFieldRect.size.height >= [UIScreen mainScreen].bounds.size.height - keyboardSize.height) {
        NSDictionary *info = [notification userInfo];
        NSNumber *number = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        double duration = [number doubleValue];
        [UIView animateWithDuration:duration animations:^{
            thetableView.contentInset =  UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
        }];
        NSIndexPath *pathOfTheCell = [thetableView indexPathForCell:(CustomCell*)cell];
        [thetableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pathOfTheCell.row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    
}

- (void)keyboardhideNotification:(NSNotification*)notification {
    NSDictionary *info = [notification userInfo];
    NSNumber *number = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double duration = [number doubleValue];
    [UIView animateWithDuration:duration animations:^{
        thetableView.contentInset =  UIEdgeInsetsMake(0, 0, 0, 0);
    }];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    notesArray = [NSMutableArray array];
    [notesArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"cellArray"]];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    kWidth = [UIScreen mainScreen].bounds.size.width;
    kHeight = [UIScreen mainScreen].bounds.size.height;
    languageArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"LanguageArray"];
    
    NSString *languageText = [[NSUserDefaults standardUserDefaults] objectForKey:@"LanguageText"];
    [languageButton setTitle:languageText forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardhideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setObject:languageButton.titleLabel.text forKey:@"LanguageText"];
    isEditing = NO;
    isreOCR = NO;
}

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

    //Make language button two lines for longer languges
    languageButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    languageButton.titleLabel.numberOfLines = 2;
    languageButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [imageView setFrame:CGRectMake(58, 40, 85, 108)];
    } else {
        [imageView setFrame:CGRectMake(87, 65, 127, 174)];
    }
}

@end

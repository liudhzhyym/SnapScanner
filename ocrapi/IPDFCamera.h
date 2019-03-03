//
//  IPDFCamera.h
//  SnapScanner
//
//  Created by iBrad on 4/19/15.
//
//

#import <UIKit/UIKit.h>

///Protocol Definition
@protocol IPDFCameraSessionDelegate <NSObject>

- (void)IPDFdidCaptureImage:(UIImage *)image;

@end

@interface IPDFCamera : UIViewController

//Delegate Property
@property (nonatomic, weak) id <IPDFCameraSessionDelegate> cameraDelegate;

@end

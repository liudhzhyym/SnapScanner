//  Created by Brad Chessin on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomCell : UITableViewCell <UITextFieldDelegate> {
	
    UIImageView *backgroundImage;
	UILabel *ivdateLabel;
	UITextField *ivtitleLabel;
	UIImageView *ivpreviewPicture;
    UIActivityIndicatorView *ivactivityIndicator;
    
}

@property (nonatomic, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, retain) IBOutlet UITextField *titleLabel;
@property (nonatomic, retain) IBOutlet UIImageView *previewPicture;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundImage;

@end

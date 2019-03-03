//  Created by Brad Chessin on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomCell.h"


@implementation CustomCell

@synthesize titleLabel = ivtitleLabel;
@synthesize dateLabel = ivdateLabel;
@synthesize previewPicture = ivpreviewPicture;
@synthesize backgroundImage = ivbackgroundImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        ivpreviewPicture.alpha = .6;
        ivtitleLabel.alpha = .6;
        ivdateLabel.alpha = .6;
    } else {
        ivpreviewPicture.alpha = 1;
        ivtitleLabel.alpha = 1;
        ivdateLabel.alpha = 1;
    }
}

- (void)dealloc {
	[ivdateLabel release], ivdateLabel = nil;
    [ivtitleLabel release], ivtitleLabel = nil;
    [ivpreviewPicture release], ivpreviewPicture = nil;
    [ivbackgroundImage release], ivbackgroundImage = nil;
    [super dealloc];
}

@end

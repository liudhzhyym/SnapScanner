//
//  DarkenUIButton.m
//  OCRPro2.0
//
//  Created by iBrad on 7/21/13.
//
//

#import "DarkenUIButton.h"

@implementation DarkenUIButton

- (id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        // Initialization code
        [self addTarget:self action: @selector(toucheddownInside:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action: @selector(touchedupInside:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action: @selector(touchedupInside:) forControlEvents:UIControlEventTouchDragExit];
    }
    return self;
}

- (void)toucheddownInside:(id)sender {
	UIButton *touchedButton = (UIButton*)sender;
    [touchedButton setAlpha:.55];
}

- (void)touchedupInside:(id)sender {
	UIButton *touchedButton = (UIButton*)sender;
    [touchedButton setAlpha:1];
}

@end

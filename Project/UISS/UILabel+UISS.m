//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import "UILabel+UISS.h"

@implementation UILabel (UISS)

- (void)setTextAttributes:(NSDictionary *)textAttributes;
{
    UIFont *font = [textAttributes objectForKey:NSFontAttributeName];
    if (font) {
        self.font = font;
    }
    UIColor *textColor = [textAttributes objectForKey:NSForegroundColorAttributeName];
    if (textColor) {
        self.textColor = textColor;
    }
}

@end

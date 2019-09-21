//
//  ImageCVCell.m
//  CollageMagic
//
//  Created by RX on 8/9/19.
//  Copyright © 2019 RX. All rights reserved.
//

#import "ImageCVCell.h"

@implementation ImageCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.photoView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.photoView.layer.borderWidth = 1.0;
    self.photoView.layer.cornerRadius = 3.0;
    self.photoView.layer.masksToBounds = true;
}

@end

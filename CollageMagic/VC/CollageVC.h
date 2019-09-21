//
//  CollageVC.h
//  CollageMagic
//
//  Created by RX on 8/9/19.
//  Copyright © 2019 RX. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CollageVC : UIViewController

@property (strong, nonatomic) NSMutableArray *selectedTemplates;
@property (strong, nonatomic) NSString *collageName;

-(void)setCollagePhotos:(NSArray *)photos;

@end

NS_ASSUME_NONNULL_END

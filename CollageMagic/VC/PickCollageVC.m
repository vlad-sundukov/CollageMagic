//
//  PickCollageVC.m
//  CollageMagic
//
//  Created by RX on 8/8/19.
//  Copyright © 2019 RX. All rights reserved.
//

#import "PickCollageVC.h"
@import iCarousel;
@import RITLPhotos;
#import <QuartzCore/QuartzCore.h>
#import "CollageVC.h"

@interface PickCollageVC () < UITextFieldDelegate, iCarouselDataSource, iCarouselDelegate, RITLPhotosViewControllerDelegate >

@property (weak, nonatomic) IBOutlet UITextField *txtFieldCollageName;
@property (weak, nonatomic) IBOutlet iCarousel *collageCarousel;

@property (nonatomic, strong) NSMutableArray *collages;
@property (nonatomic, strong) NSMutableArray *selectedTempArray;

@end

@implementation PickCollageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUIElements];
    [self loadTemplates];
}


- (void)setupUIElements {
    
    self.txtFieldCollageName.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.txtFieldCollageName.layer.borderWidth = 1.0;
    self.txtFieldCollageName.layer.cornerRadius = 5.0;
    self.txtFieldCollageName.layer.masksToBounds = true;
    
    self.collageCarousel.type = iCarouselTypeCoverFlow2;

}

- (void)loadTemplates {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"collage_templates" ofType:@"txt"];
    
    //création d'un string avec le contenu du JSON
    NSString *myJSON = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    NSAssert(myJSON, @"File collage_templates.txt couldn't be read!");
    
    NSData *data = [myJSON dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *dict =[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    self.collages = [[NSMutableArray alloc] initWithCapacity:4];
    
    for (NSDictionary *element in [[dict objectForKey:@"collage_templates"] objectForKey:@"templates"]) {
        [self.collages addObject:element];
    }
    [self.collageCarousel reloadData];
}

- (void)goToCollageVC:(NSArray<UIImage *> *)images {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CollageVC *vc = [storyboard instantiateViewControllerWithIdentifier:@"CollageVC"];
    vc.selectedTemplates = self.selectedTempArray;
    vc.collageName = self.txtFieldCollageName.text;
    [vc setCollagePhotos:images];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.txtFieldCollageName resignFirstResponder];
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.txtFieldCollageName resignFirstResponder];
    return true;
}


#pragma mark iCarouselDataSource, iCarouselDelegate

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    return [self.collages count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UIView *result = view;

    if (!result) {
        result = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                               0.0,
                                                               self.collageCarousel.frame.size.height,
                                                               self.collageCarousel.frame.size.height)];
    }
    
    result.backgroundColor = [UIColor clearColor];
    result.layer.borderWidth = 2.0f;
    result.layer.borderColor = [UIColor whiteColor].CGColor;
    result.clearsContextBeforeDrawing = YES;
    [result.layer setSublayers:nil];
    
    NSDictionary *dict = [self.collages objectAtIndex: index];
    NSArray *templ_array = [dict objectForKey:@"small_template"];
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    for (NSDictionary *d in templ_array) {
        [path moveToPoint:CGPointMake( [[d objectForKey:@"start_x"] floatValue], [[d objectForKey:@"start_y"] floatValue])];
        [path addLineToPoint:CGPointMake( [[d objectForKey:@"end_x"] floatValue], [[d objectForKey:@"end_y"] floatValue])];
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    shapeLayer.strokeColor = [[UIColor whiteColor] CGColor];
    shapeLayer.lineWidth = 2.0;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    [result.layer addSublayer:shapeLayer];
    
    return result;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    const CGFloat carouselSpacingCoef = 1.1;
    return option == iCarouselOptionSpacing ? value * carouselSpacingCoef : value;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    NSDictionary *dict = [self.collages objectAtIndex: index];
    self.selectedTempArray = [dict objectForKey:@"scrolls"];
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel {
    NSDictionary *dict = [self.collages objectAtIndex: carousel.currentItemIndex];
    self.selectedTempArray = [dict objectForKey:@"scrolls"];
}

    
#pragma mark RITLPhotosViewControllerDelegate

- (void)photosViewController:(UIViewController *)viewController images:(NSArray<UIImage *> *)images infos:(NSArray<NSDictionary *> *)infos {
    [self goToCollageVC:images];
}

    
- (void)showAlertView:(NSString *)message {
    UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@""
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelButton = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", comment: "OK")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Handle no, thanks button
                                   }];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)actionCollage:(id)sender {
    
    NSString *collageName = self.txtFieldCollageName.text;
    
    if (!collageName || [collageName isEqualToString:@""]) {
        [self showAlertView:NSLocalizedString(@"Please enter your collage name", comment: "Please enter your collage name")];
    } else {
        RITLPhotosViewController *photoController = RITLPhotosViewController.photosViewController;
        photoController.configuration.maxCount = self.selectedTempArray.count;
        photoController.configuration.containVideo = NO;
        photoController.photo_delegate = self;
        [self presentViewController:photoController animated:YES completion:^{}];
    }
}

@end

//
//  CollageVC.m
//  CollageMagic
//
//  Created by RX on 8/9/19.
//  Copyright © 2019 RX. All rights reserved.
//

#import "CollageVC.h"
#import "Collage.h"
#import "ImageCVCell.h"
@import CLImageEditor;
@import RITLPhotos;

@interface CollageVC () < UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CLImageEditorDelegate, RITLPhotosViewControllerDelegate >

@property (weak, nonatomic) IBOutlet UICollectionView *selectedPhotoCV;
@property (weak, nonatomic) IBOutlet UIView *collageFrame;
@property (weak, nonatomic) IBOutlet UIView *introView;

@property (strong, nonatomic) NSMutableArray *selectedPhotos;

@property (strong, nonatomic) Collage *collage;

@property BOOL isFreeForm;
@property NSInteger editingPhotoIndex;
@property (weak, nonatomic) UIImageView *movingImage;
@property (strong, nonatomic) UIImageView *movingCell;
@property (strong, nonatomic) UIColor *currentColor;
@property (strong, nonatomic) UIImageView *zoomedImageView;

@end

@implementation CollageVC

#pragma mark Variables

NSInteger photoIndex;
NSInteger selectedPhotoCount;
NSInteger borderWidth;
float borderConer;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isFreeForm = YES;
    self.editingPhotoIndex = -1;
    borderWidth = 3;
    borderConer = 0;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [self.selectedPhotoCV setCollectionViewLayout:flowLayout];
    //add Long Press Recognizer
    UILongPressGestureRecognizer *lpgr= [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.3; //seconds
    lpgr.delegate = self;
    [self.selectedPhotoCV addGestureRecognizer: lpgr];
    
    [self.collageFrame addSubview:self.movingImage];
    
    self.currentColor = [UIColor whiteColor];
    
    self.collageFrame.backgroundColor = [UIColor clearColor];
    self.collageFrame.layer.borderColor = [UIColor whiteColor].CGColor;
    self.collageFrame.layer.borderWidth = 1.0f;
    
    if (self.selectedTemplates.count == 1) {
        self.isFreeForm = YES;
        [self deleteScrolls];
        [self reesteblishImageViews];
        self.collageFrame.layer.borderWidth = borderWidth;
        self.collageFrame.layer.cornerRadius = 0.0f;
    } else {
        self.isFreeForm=NO;
        [self deleteScrolls];
        [self deleteUIImageView];
        [self addScrolls];
        self.collageFrame.layer.borderWidth = 0.0f;
        self.collageFrame.layer.cornerRadius = 0.0f;
    }
    
    self.collage = [Collage sharedInstance];
    self.collage.collagePhotos = [[NSMutableArray alloc] initWithCapacity:3];
    self.collage.selectedPhotos = [[NSMutableArray alloc] initWithCapacity:1];
    for (UIImage *img in self.selectedPhotos) {
        self.movingImage.image = img;
        [self.collage.collagePhotos addObject:img];
        NSDictionary *photoDictionary = @{@"info": [NSNull null], @"smallImage": img};
        [self.collage.selectedPhotos addObject:photoDictionary];
    }
    [self.selectedPhotoCV reloadData];
    selectedPhotoCount = [self.collage.selectedPhotos count];
    
    [self showIntroView];
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
    for (NSInteger i = selectedPhotoCount; i < [self.collage.selectedPhotos count]; i++) {
        [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [self.selectedPhotoCV insertItemsAtIndexPaths:arrayWithIndexPaths];
    selectedPhotoCount =[self.collage.selectedPhotos count];
}

- (void)showIntroView {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"FirstLaunch"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FirstLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.introView.hidden = NO;        
    } else {
        self.introView.hidden = YES;
    }
}
    
-(void)setCollagePhotos:(NSArray *)photos {
    self.selectedPhotos = [[NSMutableArray alloc] init];
    [self.selectedPhotos addObjectsFromArray:photos];
}

-(void)chooseFromLibrary:(UITapGestureRecognizer *) gesture{

}


#pragma mark Gesture Recognizer Selectors

-(void) handleLongPress:(UILongPressGestureRecognizer *)longRecognizer{
    //позиция в collectionView
    CGPoint locationPointInCollection = [longRecognizer locationInView:self.selectedPhotoCV];
    //позиция на экране
    CGPoint locationPointInView = [longRecognizer locationInView:self.view];
    
    if (longRecognizer.state == UIGestureRecognizerStateBegan) {
        
        NSIndexPath *indexPathOfMovingCell = [self.selectedPhotoCV indexPathForItemAtPoint:locationPointInCollection];
        photoIndex = indexPathOfMovingCell.row;
        
        NSDictionary *photoDict = [self.collage.selectedPhotos objectAtIndex:indexPathOfMovingCell.row];
        UIImage *image = [[UIImage alloc] init];
        id i = [photoDict objectForKey:@"smallImage"];
        if ([i isKindOfClass:[NSData class]]) {
            image = [UIImage imageWithData:(NSData *) i];
        } else {
            image = (UIImage *) i;
        }
        CGRect frame = CGRectMake(locationPointInView.x, locationPointInView.y, 150.0f, 150.0f);
        self.movingCell = [[UIImageView alloc] initWithFrame:frame];
        self.movingCell.image = image;
        [self.movingCell setCenter:locationPointInView];
        self.movingCell.layer.borderWidth = 5.0f;
        self.movingCell.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.view addSubview:self.movingCell];
        
    }
    
    if (longRecognizer.state == UIGestureRecognizerStateChanged) {
        [self.movingCell setCenter:locationPointInView];
    }
    
    if (longRecognizer.state == UIGestureRecognizerStateEnded) {
        CGRect frameRelativeToParentCollageFrame = [self.collageFrame convertRect:self.collageFrame.bounds
                                                                       toView:self.view];
        if (CGRectContainsPoint( frameRelativeToParentCollageFrame, self.movingCell.center)){
            if (self.isFreeForm){
                CGPoint originInCollageView = [self.collageFrame convertPoint:self.movingCell.center fromView:self.view];
                float width = (self.collageFrame.bounds.size.width - 5)/2;
                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
                [self holdInContainer:imgView withIndex:photoIndex];
                [self tuneImageView:imgView withCenterPont: originInCollageView];
                [self.collageFrame addSubview:imgView];
                [self.collageFrame bringSubviewToFront:imgView];
            } else{
                for (id i in self.collageFrame.subviews){
                    if( [i isKindOfClass:[UIScrollView class]]){
                        UIScrollView *tmpScroll = (UIScrollView *)i;
                        CGRect frameRelativeToParent= [tmpScroll convertRect: tmpScroll.bounds
                                                                      toView:self.view];
                        if (CGRectContainsPoint( frameRelativeToParent, self.movingCell.center)){
                            for (id y in tmpScroll.subviews){
                                if( [y isKindOfClass:[UIImageView class]]){
                                    UIImageView *imgView = y;
                                    if (imgView.tag!=0){
                                        [self holdInContainer:imgView withIndex: photoIndex];
                                        tmpScroll.contentSize = imgView.bounds.size;
                                        [self.movingCell removeFromSuperview];
                                        [tmpScroll setNeedsLayout];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        else{
            [self.movingCell removeFromSuperview];
        }
    }
}

-(void)bringSubviewToFront:(UITapGestureRecognizer *) gesture{
    CGPoint locationPointInView = [gesture locationInView:self.collageFrame];
    for (UIView *i in self.collageFrame.subviews){
        if([i isKindOfClass:[UIImageView class]]){
            UIImageView *img = (UIImageView*)i;
            CGRect frameRelativeToParent = [img convertRect:img.bounds
                                                     toView:self.collageFrame];
            if (CGRectContainsPoint( frameRelativeToParent , locationPointInView)){
                self.movingImage = (UIImageView*)i;
                [self.collageFrame bringSubviewToFront:self.movingImage];
            }
        }
    }
}

-(void) moveImageInCollage: (UIPanGestureRecognizer *) gesture{
    CGPoint locationPointInView = [gesture locationInView: self.collageFrame];
    CGPoint locationPointInSuperView = [gesture locationInView:self.view];
    if (gesture.state ==  UIGestureRecognizerStateBegan){
        for (UIView *i in self.collageFrame.subviews){
            if([i isKindOfClass:[UIImageView class]]){
                UIImageView *img = (UIImageView*)i;
                CGRect frameRelativeToParent = [img convertRect:img.bounds
                                                         toView:self.collageFrame];
                if (CGRectContainsPoint( frameRelativeToParent , locationPointInView)){
                    self.movingImage = img;
                    self.movingImage.tag = [self.collage.collagePhotos indexOfObject: img.image];
                    [self.collageFrame bringSubviewToFront:self.movingImage];
                }
            }
        }
    }
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect frameRelativeToParent = [self.movingImage convertRect:self.movingImage.bounds
                                                          toView:self.collageFrame];
        if (CGRectContainsPoint( frameRelativeToParent , locationPointInView)){
            self.movingImage.center =locationPointInView;
        }
    }
    if(gesture.state == UIGestureRecognizerStateEnded){
        CGRect frameRelativeToParent = [self.collageFrame convertRect:self.collageFrame.bounds
                                                           toView:self.view];
        if (! CGRectContainsPoint( frameRelativeToParent , locationPointInSuperView)){
            [self.collage.collagePhotos removeObjectAtIndex:self.movingImage.tag];
            [self.movingImage removeFromSuperview];
        }
    }
}

- (void)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer {
    UIScrollView *scroll = (UIScrollView *) recognizer.view;
    for (id y in scroll.subviews){
        if( [y isKindOfClass:[UIImageView class]]){
            UIImageView *imgView = y;
            if (imgView.tag!=0){
                self.zoomedImageView = imgView;
            }
        }
    }
    CGPoint pointInView = [recognizer locationInView:self.zoomedImageView];
    
    CGFloat newZoomScale = scroll.zoomScale * 1.5f;
    newZoomScale = MIN(newZoomScale, scroll.maximumZoomScale);
    
    CGSize scrollViewSize = scroll.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    // 4
    [scroll zoomToRect:rectToZoomTo animated:YES];
}

- (void)scrollViewTwoFingerTapped:(UITapGestureRecognizer*)recognizer {
    UIScrollView *scroll = (UIScrollView *) recognizer.view;
    // Zoom out slightly, capping at the minimum zoom scale specified by the scroll view
    CGFloat newZoomScale = scroll.zoomScale / 1.5f;
    newZoomScale = MAX(newZoomScale, scroll.minimumZoomScale);
    [scroll setZoomScale:newZoomScale animated:YES];
}


#pragma mark - ScrollView delegates

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return  self.zoomedImageView;
}


#pragma mark UICollectionView - sources

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.collage.selectedPhotos count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCVCell *cell = (ImageCVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCVCell" forIndexPath:indexPath];
    
    NSDictionary *photoDict = [self.collage.selectedPhotos objectAtIndex:indexPath.row];
    id i = [photoDict objectForKey:@"smallImage"];
    if ([i isKindOfClass:[NSData class]]) {
        cell.photoView.image = [UIImage imageWithData:(NSData *) i];
    } else {
        cell.photoView.image = (UIImage *) i;
    }
    
    return cell;

}


#pragma mark UICollectionView - delegates

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.editingPhotoIndex = indexPath.row;
    UIImage *image = self.collage.collagePhotos[indexPath.row];
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image delegate:self];
    [self presentViewController:editor animated:YES completion:nil];
}

#pragma mark UICollectionView - layouts

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.selectedPhotoCV.frame.size.height, self.selectedPhotoCV.frame.size.height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 5, 0, 5);
}


#pragma mark- CLImageEditor delegate

- (void)imageEditor:(CLImageEditor *)editor didFinishEditingWithImage:(UIImage *)image
{
    self.movingImage.image = image;
    [self.collage.collagePhotos replaceObjectAtIndex:self.editingPhotoIndex withObject:image];
    NSDictionary *photoDictionary = @{@"info": [NSNull null], @"smallImage": image};
    [self.collage.selectedPhotos replaceObjectAtIndex:self.editingPhotoIndex withObject:photoDictionary];
    
    [editor dismissViewControllerAnimated:YES completion:nil];
    [self.selectedPhotoCV reloadData];
    self.editingPhotoIndex = -1;
}


#pragma mark RITLPhotosViewControllerDelegate

- (void)photosViewController:(UIViewController *)viewController images:(NSArray<UIImage *> *)images infos:(NSArray<NSDictionary *> *)infos {
    
    self.selectedPhotos = [[NSMutableArray alloc] init];
    [self.selectedPhotos addObjectsFromArray:images];
    
    self.collage.collagePhotos = [[NSMutableArray alloc] initWithCapacity:3];
    self.collage.selectedPhotos = [[NSMutableArray alloc] initWithCapacity:1];
    for (UIImage *img in self.selectedPhotos) {
        self.movingImage.image = img;
        [self.collage.collagePhotos addObject:img];
        NSDictionary *photoDictionary = @{@"info": [NSNull null], @"smallImage": img};
        [self.collage.selectedPhotos addObject:photoDictionary];
    }
    [self.selectedPhotoCV reloadData];
    selectedPhotoCount = [self.collage.selectedPhotos count];
}


#pragma mark Utilities

-(void)addScrolls {
    
    int i =0;
    for (NSDictionary *dic in self.selectedTemplates) {
        float x = [[dic objectForKey:@"x"] floatValue];
        float y = [[dic objectForKey:@"y"] floatValue];
        float width = [[dic objectForKey:@"width"] floatValue];
        float height = [[dic objectForKey:@"height"] floatValue];
        CGRect frame = CGRectMake(x, y, width, height);
        
        UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:frame];
        scroll.backgroundColor = [UIColor clearColor];
        [self.collageFrame addSubview:scroll];
        [self tuneScroll:scroll withContentSize:CGSizeMake(width, height) withScrollIndex:i];
        i+=1;
    }
    
}

-(void) deleteScrolls{
    for (id i in self.collageFrame.subviews){
        if( [i isKindOfClass:[UIScrollView class]]){
            [i removeFromSuperview];
        }
    }
}

-(void)reesteblishImageViews{
    float x = 75.0f;
    float y = 75.0f;
    float offset = self.collageFrame.bounds.size.width/ [self.collage.collagePhotos count];
    for (UIImage *img in self.collage.collagePhotos){
        float width = (self.collageFrame.bounds.size.width - 5)/2;
        UIImageView *newImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        float s = 1.0f;
        if (img.size.height> img.size.width) {
            s = img.size.height/img.size.width;
            CGRect newRect = CGRectMake(newImageView.frame.origin.x, newImageView.frame.origin.y, newImageView.frame.size.width, newImageView.frame.size.height*s);
            newImageView.frame = newRect;
        } else{
            s = img.size.width/img.size.height;
            CGRect newRect = CGRectMake(newImageView.frame.origin.x, newImageView.frame.origin.y, newImageView.frame.size.width*s, newImageView.frame.size.height);
            newImageView.frame = newRect;
        }
        newImageView.image = img;
        [self tuneImageView:newImageView withCenterPont:CGPointMake(x, y)];
        [self.collageFrame addSubview:newImageView];
        [self.collageFrame bringSubviewToFront:newImageView];
        x += offset;
        y += offset;
    }
}

-(void) deleteUIImageView{
    for (id i in self.collageFrame.subviews){
        if( [i isKindOfClass:[UIImageView class]]){
            [i removeFromSuperview];
        }
    }
}

-(void)tuneScroll: (UIScrollView *)scroll withContentSize: (CGSize) size withScrollIndex: (NSInteger) index
{
    float biggestSide = (size.height>size.width)? size.height : size.width;
    scroll.contentSize = CGSizeMake(biggestSide, biggestSide);
    CGRect frame = (CGRect){.origin=CGPointMake(0.0f, 0.0f), scroll.contentSize};
    UIImageView *imView = [[UIImageView alloc] initWithFrame: frame];
    //UIScrollView by default contains 2 UIImageViews as subviews for scroll indicators.
    //so we need tag for mark ours
    imView.tag=101;
    //in case wrong array index
    @try {
        float s = 1.0f;
        UIImage *img = [self.collage.collagePhotos objectAtIndex:index];
        NSLog(@"OLD SIZE w=%f, h=%f", imView.frame.size.width, imView.frame.size.height);
        if (img.size.height> img.size.width) {
            s = img.size.height/img.size.width;
            CGRect newRect = CGRectMake(imView.frame.origin.x, imView.frame.origin.y, imView.frame.size.width, imView.frame.size.height*s);
            imView.frame = newRect;
        } else{
            s = img.size.width/img.size.height;
            CGRect newRect = CGRectMake(imView.frame.origin.x, imView.frame.origin.y, imView.frame.size.width*s, imView.frame.size.height);
            imView.frame = newRect;
        }
        NSLog(@"NEW SIZE w=%f, h=%f", imView.frame.size.width, imView.frame.size.height);
        scroll.contentSize = imView.frame.size;
        imView.image = img;
        
    }
    @catch (NSException *exception) {
        //do nothing
    }
    
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [scroll addGestureRecognizer:doubleTapRecognizer];
    
    UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTwoFingerTapped:)];
    twoFingerTapRecognizer.numberOfTapsRequired = 1;
    twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    [scroll addGestureRecognizer:twoFingerTapRecognizer];
    
    scroll.delegate = self;
    //[scroll setScrollEnabled:YES];
    //scroll.clipsToBounds = YES;
    scroll.layer.borderWidth = borderWidth;
    scroll.layer.borderColor = self.currentColor.CGColor;
    CGFloat scaleWidth = scroll.frame.size.width / scroll.contentSize.width;
    CGFloat scaleHeight = scroll.frame.size.height / scroll.contentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    scroll.minimumZoomScale = 1.0f;
    scroll.zoomScale = minScale;
    scroll.maximumZoomScale = 2.0f;
    [scroll addSubview:imView];
}

-(void) tuneImageView: (UIImageView *)imageView withCenterPont: (CGPoint) centerPont{
    
    imageView.center = centerPont;
    [imageView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImageInCollage:)];
    pan.delegate = self;
    [imageView addGestureRecognizer:pan];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bringSubviewToFront:)];
    tap.delegate = self;
    [imageView addGestureRecognizer: tap];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseFromLibrary:)];
    doubleTap.numberOfTapsRequired = 2;
    [imageView addGestureRecognizer:doubleTap];
    imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    imageView.layer.borderWidth = 5.0f;
}

-(void) holdInContainer: (UIImageView *) container withIndex: (NSInteger) i{
    container.alpha = 0.0;
    container.image = self.movingCell.image;
    
    //download big imgage's version
    NSDictionary *photoDict = self.collage.selectedPhotos[i];
    id photo = [photoDict objectForKey:@"info"];
    if (photo != [NSNull null]){
        //animate disappearance of moving cell
        CGPoint centerPoint = self.movingCell.center;
        [UIView animateWithDuration: 0.5f
                         animations:^{CGRect frame = self.movingCell.frame;
                             frame.size.width -= frame.size.width - 1.0f;
                             frame.size.height -= frame.size.height -  1.0f;
                             self.movingCell.frame = frame;
                             self.movingCell.center = centerPoint;}
                         completion:^(BOOL finished){[self.movingCell removeFromSuperview]; }];
    } else{
        UIImage *img =[[UIImage alloc] init];
        id i = [photoDict objectForKey:@"smallImage"];
        if ([i isKindOfClass:[NSData class]]) {
            img = [UIImage imageWithData:(NSData *) i];
        } else {
            img = (UIImage *) i;
        }
        float s = 1.0f;
        if (img.size.height> img.size.width) {
            s = img.size.height/img.size.width;
            CGRect newRect = CGRectMake(container.frame.origin.x, container.frame.origin.y, container.frame.size.width, container.frame.size.height*s);
            container.frame = newRect;
        } else{
            s = img.size.width/img.size.height;
            CGRect newRect = CGRectMake(container.frame.origin.x, container.frame.origin.y, container.frame.size.width*s, container.frame.size.height);
            container.frame = newRect;
        }
        container.image = img;
        CGPoint centerPoint = self.movingCell.center;
        [self.collage.collagePhotos addObject:img];
        [UIView animateWithDuration: 0.5f
                         animations:^{ container.alpha = 1.0f;
                             CGRect frame = self.movingCell.frame;
                             frame.size.width -= frame.size.width - 1.0f;
                             frame.size.height -= frame.size.height -  1.0f;
                             self.movingCell.frame = frame;
                             self.movingCell.center = centerPoint;}
                         completion:^(BOOL finished){[self.movingCell removeFromSuperview]; }];
    }
}

-(UIImage *) makeImage{
    UIGraphicsBeginImageContextWithOptions(_collageFrame.bounds.size, NO, 0.0);
    [_collageFrame.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)actionBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)actionShare:(id)sender {
    NSMutableArray *sharingItems = [NSMutableArray new];
    [sharingItems addObject:[self makeImage]];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)actionGallery:(id)sender {
    RITLPhotosViewController *photoController = RITLPhotosViewController.photosViewController;
    photoController.configuration.maxCount = self.selectedTemplates.count;
    photoController.configuration.containVideo = NO;
    photoController.photo_delegate = self;
    [self presentViewController:photoController animated:YES completion:^{}];
}

- (IBAction)actionHideIntro:(id)sender {
    self.introView.hidden = YES;
}

@end

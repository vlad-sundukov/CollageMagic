//
//  Collage.m
//  CollageMagic
//
//  Created by RX on 8/9/19.
//  Copyright © 2019 RX. All rights reserved.
//

#import "Collage.h"

@implementation Collage

static Collage *_sharedInstance = nil;

+ (Collage *)sharedInstance
{
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[Collage alloc] init];
        if (_sharedInstance){
            _sharedInstance.collagePhotos = [[NSMutableArray alloc] initWithCapacity:3];
            _sharedInstance.selectedPhotos = [[NSMutableArray alloc] initWithCapacity:1];
        }
    });
    return _sharedInstance;
}

@end

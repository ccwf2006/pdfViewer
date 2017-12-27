//
//  PDFContentTiledLayer.m
//  test
//
//  Created by gslicai on 16/11/21.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import "PDFContentTiledLayer.h"

@implementation PDFContentTiledLayer

#define LEVELS_OF_DETAIL 16

#pragma mark - ReaderContentTile class methods

+ (CFTimeInterval)fadeDuration
{
    return 0.001; // iOS bug (flickering tiles) workaround
}

#pragma mark - ReaderContentTile instance methods

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.levelsOfDetail = 1;
        
        self.levelsOfDetailBias = 4;
        
        UIScreen *mainScreen = [UIScreen mainScreen];
        
        CGFloat screenScale = [mainScreen scale];
        
        CGRect screenBounds = [mainScreen bounds];
        
        CGFloat w_pixels = (screenBounds.size.width * screenScale);
        
        CGFloat h_pixels = (screenBounds.size.height * screenScale);
        
        CGFloat max = ((w_pixels < h_pixels) ? h_pixels : w_pixels);
        
        CGFloat sizeOfTiles = ((max < 512.0f) ? 512.0f : 1024.0f);
        
        self.tileSize = CGSizeMake(sizeOfTiles, sizeOfTiles);
//                self.tileSize = CGSizeMake(64 , 64);

    }
    
    return self;
}

@end

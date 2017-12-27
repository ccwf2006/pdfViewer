//
//  PDFContentViewController.h
//  test
//
//  Created by gslicai on 16/11/21.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

#define PDFContentDefaultBackground [UIColor whiteColor]
#define PDFPageDefaultShadowColor [UIColor grawColor]
@interface PDFContentViewController : BaseViewController
- (void)showPdfPage:(CGPDFPageRef)pdfPage;
- (void)resumeScale:(BOOL)animated;
- (void)aspectWidthScale:(BOOL)animated;
- (CGFloat)getCurrentScale;
@property (nonatomic,assign) NSInteger pageNumber;
@property (nonatomic,strong) UIColor* contentBackground;
@end

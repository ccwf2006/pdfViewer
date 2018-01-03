//
//  PDFContentViewController.m
//  test
//
//  Created by gslicai on 16/11/21.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import "PDFContentViewController.h"
#import "PDFContentContainerView.h"
#import "PDFContentTiledLayer.h"

#define PDFContentDefaultPDFBox kCGPDFMediaBox

@interface PDFContentViewController ()<UIScrollViewDelegate,CALayerDelegate> {
    CGPDFPageRef _pdfPage;
}
//缩放滚动
@property (nonatomic,strong) PDFContentContainerView* pdfContentContainerView;
//pdf 显示
@property (nonatomic,strong) UIView* pdfContentView;
@property (nonatomic,strong) PDFContentTiledLayer* pdfContentLayer;
@end

@implementation PDFContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)createUI{
    self.view.backgroundColor = color(0xFFF3F3F3);
    self.pdfContentContainerView = [[PDFContentContainerView alloc]init];
    [self.view addSubview:self.pdfContentContainerView];
    self.pdfContentContainerView.maximumZoomScale = 10;
    self.pdfContentContainerView.minimumZoomScale = 1;
    
    self.pdfContentContainerView.delegate = self;
    self.automaticallyAdjustsScrollViewInsets = NO;
#pragma MakeConstraints
    self.pdfContentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.pdfContentContainerView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.pdfContentContainerView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.pdfContentContainerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.pdfContentContainerView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    
    self.pdfContentView = [[UIView alloc]init];
    [self.pdfContentContainerView addSubview:self.pdfContentView];
    self.pdfContentLayer = [[PDFContentTiledLayer alloc]init];
    self.pdfContentLayer.delegate = self;
    [self.pdfContentView.layer addSublayer:self.pdfContentLayer];
    
    self.contentBackground = PDFContentDefaultBackground;
}

- (void)viewDidLayoutSubviews{
    [self adjustPdfContentFrame];
    [self centerScrollViewContent];
    [self drawThumb];
    [super viewDidLayoutSubviews];
}

- (void)showPdfPage:(CGPDFPageRef)pdfPage{
    if (_pdfPage != nil) {
        CGPDFPageRelease(_pdfPage);
        _pdfPage = nil;
    }
    if (pdfPage != nil) {
        _pdfPage = pdfPage;
        CGPDFPageRetain(_pdfPage);
    }
}

//调整 pdfContentView 将 PDF 缩放到 1x
- (void)adjustPdfContentFrame{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGRect maxContentRect = self.pdfContentContainerView.bounds;
    if (_pdfPage != nil) {
        CGRect pdfPageOriginalPageRect = CGPDFPageGetBoxRect(_pdfPage, PDFContentDefaultPDFBox);
        CGSize adjustPageSize = maxContentRect.size;
        double contentRate = maxContentRect.size.width/(maxContentRect.size.height > 0?maxContentRect.size.height:screenSize.height);
        double pdfOriginalRate = pdfPageOriginalPageRect.size.width/(pdfPageOriginalPageRect.size.height > 0? pdfPageOriginalPageRect.size.height:screenSize.height);
        //判断宽高比
        //pdf 原始宽度大于显示区域宽度,需要将宽度缩放到显示区域宽度,并且相应的缩放高度
        if (pdfOriginalRate > contentRate) {
            double scaleRate = pdfPageOriginalPageRect.size.width/maxContentRect.size.width;
            double scaleWidth = maxContentRect.size.width;
            double scaleHeight = pdfPageOriginalPageRect.size.height/(scaleRate > 0?scaleRate:1);
            adjustPageSize = CGSizeMake(scaleWidth, scaleHeight);
        }else{
            double scaleRate = pdfPageOriginalPageRect.size.height/maxContentRect.size.height;
            double scaleWidth = pdfPageOriginalPageRect.size.width/(scaleRate > 0?scaleRate:1);
            double scaleHeight = maxContentRect.size.height;
            adjustPageSize = CGSizeMake(scaleWidth, scaleHeight);
        }
        
        self.pdfContentView.frame = CGRectMake(0, 0, adjustPageSize.width, adjustPageSize.height);
        self.pdfContentContainerView.contentSize = self.pdfContentView.bounds.size;
        if (!CGRectEqualToRect(self.pdfContentLayer.bounds, self.pdfContentView.layer.bounds)) {
            self.pdfContentLayer.frame = self.pdfContentView.layer.bounds;
            [self drawThumb];
            [self.pdfContentLayer setNeedsDisplay];
        }
    }else{
        self.pdfContentView.frame = CGRectZero;
        self.pdfContentLayer.frame = self.pdfContentView.layer.bounds;
        self.pdfContentContainerView.contentSize = self.pdfContentView.bounds.size;
    }
}

//保证 pdf 在 ScrollView 中间位置
- (void)centerScrollViewContent
{
    CGFloat iw = 0.0f; CGFloat ih = 0.0f; // Content width and height insets
    
    CGSize boundsSize = self.pdfContentContainerView.bounds.size;
    CGSize contentSize = self.pdfContentContainerView.contentSize; // Sizes
    
    if (contentSize.width < boundsSize.width) iw = ((boundsSize.width - contentSize.width) * 0.5f);
    
    if (contentSize.height < boundsSize.height) ih = ((boundsSize.height - contentSize.height) * 0.5f);
    
    UIEdgeInsets insets = UIEdgeInsetsMake(ih, iw, ih, iw); // Create (possibly updated) content insets
    
    if (UIEdgeInsetsEqualToEdgeInsets(self.pdfContentContainerView.contentInset, insets) == false){
        self.pdfContentContainerView.contentInset = insets;
    }
}

- (void)resumeScale:(BOOL)animated{
//    self.pdfContentContainerView.zoomScale = 1;
    [self.pdfContentContainerView setZoomScale:1 animated:animated];
    
    [self centerScrollViewContent];
    
//    if (animated == NO) {
//        [self centerScrollViewContent];
//    }
}

- (void)aspectWidthScale:(BOOL)animated{
    double aspectScale = self.pdfContentContainerView.contentSize.width/self.view.bounds.size.width;
    if (aspectScale >0 && aspectScale < 1) {
        [self.pdfContentContainerView setZoomScale:(1/aspectScale) animated:animated];
        [self centerScrollViewContent];
    }
}

- (CGFloat)getCurrentScale{
    return self.pdfContentContainerView.zoomScale;
}

#pragma UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    //NSLog(@"%@",scrollView);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    NSLog(@"scrollViewDidEndZooming %@   %@   %lf",scrollView,view,scale);
    [self centerScrollViewContent];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.pdfContentView;
}

#pragma CALayerDelegate
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context{
        PDFContentViewController* strongSelf = self;
        CGPDFPageRetain(_pdfPage);
        double screenScale = [UIScreen mainScreen].scale;
        CGSize pdfPageOriginalPageSize = CGPDFPageGetBoxRect(strongSelf->_pdfPage, PDFContentDefaultPDFBox).size;
        CGSize imageSize = CGSizeMake(layer.bounds.size.width, layer.bounds.size.height);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextFillRect(context,CGContextGetClipBoundingBox(context));
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0, layer.bounds.size.height);
        CGContextScaleCTM(context, 1, -1);
        
        CGContextScaleCTM(context, imageSize.width/(pdfPageOriginalPageSize.width > 0?pdfPageOriginalPageSize.width:imageSize.width), imageSize.height/(pdfPageOriginalPageSize.height > 0?pdfPageOriginalPageSize.height:imageSize.height));
        //    CGContextScaleCTM(context, 1/screenScale, 1/screenScale);
        CGContextDrawPDFPage(context, strongSelf->_pdfPage);
        CGContextRestoreGState(context);
        CGPDFPageRelease(_pdfPage);
}

- (void)drawThumb{
    double screenScale = [UIScreen mainScreen].scale;
    
    CGSize pdfPageOriginalPageSize = CGPDFPageGetBoxRect(_pdfPage, PDFContentDefaultPDFBox).size;
    CGSize imageSize = CGSizeMake(self.pdfContentView.bounds.size.width, self.pdfContentView.bounds.size.height);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.contentBackground.CGColor);
    CGContextSetStrokeColorWithColor(context, self.contentBackground.CGColor);
    CGContextFillRect(context,CGRectMake(0, 0, imageSize.width, imageSize.height));
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, imageSize.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextScaleCTM(context, imageSize.width/(pdfPageOriginalPageSize.width > 0?pdfPageOriginalPageSize.width:imageSize.width), imageSize.height/(pdfPageOriginalPageSize.height > 0?pdfPageOriginalPageSize.height:imageSize.height));
    CGContextDrawPDFPage(context, _pdfPage);
    CGContextRestoreGState(context);
    UIImage* thumbImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.pdfContentView.layer.contents = (__bridge id _Nullable)(thumbImg.CGImage);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return NO;
}

- (void)dealloc{
    self.pdfContentLayer.delegate = nil;
    self.pdfContentLayer.contents = nil;
    self.pdfContentView.layer.contents = nil;
    if (_pdfPage != nil) {
        CGPDFPageRelease(_pdfPage);
        _pdfPage = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

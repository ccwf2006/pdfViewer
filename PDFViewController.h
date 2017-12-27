//
//  PDFViewController.h
//  rice-ios
//
//  Created by gslicai on 16/11/18.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import "BaseViewController.h"
@class PDFViewController;
@protocol PDFViewControllerDelegate<NSObject>

/**
 停止阅读

 @param viewController
 @return YES 关闭 ViewController NO 不关闭 ViewController
 */
- (BOOL)didFinishRead:(PDFViewController*)viewController;

@end

@interface PDFViewController : BaseViewController

/**
 显示 pdf 文件一定要在 ViewController 出现之后再显示

 @param pdfPath  pdf 文件位置
 */
- (void)startReadPDFFile:(NSString*)pdfPath;
@property (nonatomic,weak) id<PDFViewControllerDelegate>delegate;
@end

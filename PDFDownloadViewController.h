//
//  PDVDownloadViewController.h
//  rice-ios
//
//  Created by gslicai on 16/11/25.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import "BaseViewController.h"

@interface PDFDownloadViewController : BaseViewController
+ (instancetype)newInstanceWithURL:(NSString*)url;
@property (nonatomic,copy) NSString* fileTitle;
//- (void)downloadAndOpen:(NSString*)downloadURL;

@end

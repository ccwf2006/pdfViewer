//
//  PDFProgressView.h
//  rice-ios
//
//  Created by gslicai on 16/11/25.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDFProgressView : UIView
@property (weak, nonatomic) IBOutlet UILabel *progressNum;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

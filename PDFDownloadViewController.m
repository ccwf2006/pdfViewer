//
//  PDVDownloadViewController.m
//  rice-ios
//
//  Created by gslicai on 16/11/25.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import "PDFDownloadViewController.h"
#import "PDFViewController.h"
#import "HostProvider.h"
#import "AFNetworking.h"
#import "PopupDialog.h"
#import "PDFProgressView.h"
#import "CGTool.h"

#define RICEDEFAULTPDFFILENAME @"rictTempPDFFile.pdf"
#define DEFAULT_HUD_VIEW_WIDTH 186
#define DEFAULT_HUD_VIEW_HEIGHT 60
@interface PDFDownloadViewController ()<PopupDialogDelegate,PDFViewControllerDelegate>
@property (nonatomic,strong) PopupDialog* networkFailedDialog;

@property (nonatomic,copy) NSString* currentPDFFileURL;

@property (nonatomic,assign) BOOL cancleDownload;
@property (nonatomic,strong) PDFViewController* pdfViewController;
@property (nonatomic,strong) UINavigationController* pdfNavigationController;

@property (nonatomic,strong) PDFProgressView* progressHudView;
@property (nonatomic,assign) BOOL isFinishRead;//修复从 pdf 展示页面返回时再次加载 pdf 的 bug
@end

@implementation PDFDownloadViewController
+ (instancetype)newInstanceWithURL:(NSString*)url{
    PDFDownloadViewController* instance = [PDFDownloadViewController newInstance];
    NSURL* fullURL = [NSURL URLWithString:url];
    if (fullURL == nil || fullURL.scheme == nil) {
        fullURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[HostProvider globalHost],url]];
    }
    instance.currentPDFFileURL = fullURL.absoluteString;
    return instance;
}

+ (instancetype)newInstanceWithParams:(NSDictionary *)params{
    PDFDownloadViewController* instance = [PDFDownloadViewController newInstance];
    if (params[@"title"]) {
        instance.fileTitle = params[@"title"];
    }
    if (params[@"pdf_url"]) {
        NSString* url = params[@"pdf_url"];
        url = [url stringByRemovingPercentEncoding];
        url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL* fullURL = [NSURL URLWithString:url];
        if (fullURL == nil || fullURL.scheme == nil) {
            fullURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[HostProvider globalHost],url]];
        }
        instance.currentPDFFileURL = fullURL.absoluteString;
    }
    return instance;
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.automaticallyAdjustsScrollViewInsets = NO;
    if(self.navigationController){
        [self setTitleBarBackgroundGradient:@[color(0xFFF8F8F8), color(0xFFF8F8F8)]];
        [self setTitleBarSplitLineColor:color(0xFFE7E7E7)];
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];

    
    self.view.backgroundColor = color(0xFFF3F3F3);
    
    self.cancleDownload = NO;
    if (self.fileTitle != nil) {
        self.navigationItem.title = self.fileTitle;
    }

}



- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.isFinishRead != YES && self.currentPDFFileURL != nil) {
        [self downloadAndOpen:self.currentPDFFileURL];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (self.pdfViewController && self.pdfViewController.parentViewController == nil) {
        [self.pdfViewController dismiss:NO];
    }
}

- (void)dealloc{
    NSLog(@"download dealloc");
}

#pragma download file
- (void)downloadAndOpen:(NSString*)downloadURL{
    self.currentPDFFileURL = downloadURL;
    if (downloadURL != nil && [NSURL URLWithString:downloadURL] != nil) {
        NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadURL]];
        AFHTTPSessionManager* manager = [AFHTTPSessionManager manager];
        [self showDownloadProgress:0];
        [self removePDFFile];
        __weak typeof(self) weakSelf = self;
        NSURLSessionDownloadTask* downloadTask = [manager downloadTaskWithRequest:urlRequest progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                return [NSURL fileURLWithPath:[strongSelf getDefaultPDFTempFilePath]];
            }
            return [NSURL fileURLWithPath:@""];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            //下载完成
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (strongSelf && error == nil && filePath != nil) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [strongSelf showDownloadProgress:1];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (strongSelf.view.window) {
                            [strongSelf dismissDownloadProgress];
                            [strongSelf downloadSuccess];
                        }
                    });
                });
            }else if(strongSelf && error.code != NSURLErrorCancelled && strongSelf.cancleDownload != YES){//下载失败
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (strongSelf && strongSelf.view.window) {
                        [strongSelf dismissDownloadProgress];
                        strongSelf.networkFailedDialog = [[PopupDialog alloc]initWithMessage:@"加载文件失败" buttonTitles:@[@"重新加载",@"返回"]];
                        strongSelf.networkFailedDialog.delegate = self;
                        [strongSelf.networkFailedDialog show];
                    }
                });
            }
        }];
        [manager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            //更新下载进度
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    double downloadProgress = (double)totalBytesWritten/totalBytesExpectedToWrite;
                    [strongSelf showDownloadProgress:downloadProgress];
                });
            }
        }];
        [downloadTask resume];
    }
}

- (void)showDownloadProgress:(double)progress{
    CGSize screenSize = [UIApplication sharedApplication].keyWindow.bounds.size;
    if(!self.progressHudView){
        self.progressHudView = [[[NSBundle mainBundle]loadNibNamed:@"PDFProgressView" owner:[[PDFProgressView alloc]init] options:nil] firstObject];
        self.progressHudView.frame = CGRectMake((screenSize.width - DEFAULT_HUD_VIEW_WIDTH) / 2,
                                                                (screenSize.height - DEFAULT_HUD_VIEW_HEIGHT) / 2,
                                                                DEFAULT_HUD_VIEW_WIDTH, DEFAULT_HUD_VIEW_HEIGHT);
        
        self.progressHudView.backgroundColor = [UIColor clearColor];
        self.progressHudView.center = self.view.center;
        [self.view addSubview:self.progressHudView];
        
        
        
        self.progressHudView.progressView.trackImage = [[UIImage imageNamed:@"icon_progressbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 8, 3, 8) resizingMode:UIImageResizingModeStretch];
    }
    self.progressHudView.frame = CGRectMake((screenSize.width - DEFAULT_HUD_VIEW_WIDTH) / 2,
                                            (screenSize.height - DEFAULT_HUD_VIEW_HEIGHT) / 2,
                                            DEFAULT_HUD_VIEW_WIDTH, DEFAULT_HUD_VIEW_HEIGHT);
    
    if (progress <= 1 && progress >= 0) {
        CGSize imageSize = CGSizeMake(self.progressHudView.progressView.bounds.size.width * [UIScreen mainScreen].scale, 8 * [UIScreen mainScreen].scale);
        imageSize = CGSizeMake(imageSize.width * progress > 0?imageSize.width * progress:1, imageSize.height);
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextBeginPath(context);
        CGContextAddRoundRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height), imageSize.height/2);
        CGContextClip(context);
        CGContextBeginPath(context);
        CGContextDrawGradientOnRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height), @[color(0xFFEDD0B0),color(0xFFB57E40)]);
        UIImage* foregroundImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
//        self.progressHudView.progressView.progressImage = [foregroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(4, 16, 4, 16) resizingMode:UIImageResizingModeStretch];
        self.progressHudView.progressView.progressImage = foregroundImage;
        self.progressHudView.hidden = NO;
        self.progressHudView.progressNum.text = [NSString stringWithFormat:@"%ld%%",(long int)(progress*100)];
        self.progressHudView.progressView.progress = progress;
    }
    [self.view bringSubviewToFront:self.progressHudView];
}

- (void)dismissDownloadProgress{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressHudView.hidden = YES;
    });
}

- (void)downloadSuccess{
    self.pdfViewController = [PDFViewController newInstance];
    self.pdfViewController.delegate = self;
    self.isFinishRead = NO;
//        [self dismissViewControllerAnimated:NO completion:nil];
//        self.pdfNavigationController = [[UINavigationController alloc]initWithRootViewController:self.pdfViewController];
    if (self.fileTitle != nil) {
        self.pdfViewController.navigationItem.title = self.fileTitle;
    }
    [self startViewController:self.pdfViewController animated:NO];
    [self.pdfViewController startReadPDFFile:[self getDefaultPDFTempFilePath]];

}


#pragma PopupDialog
- (void) popupDialog:(PopupDialog *) popupDialog didClickAtPosition:(int) position{
    if (popupDialog == self.networkFailedDialog) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (position) {
                case 0:{
                    //修复连续失败的 bug
                    [self showDownloadProgress:0];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self downloadAndOpen:self.currentPDFFileURL];
                    });
                }
                    break;
                case 1:{
                    [self dismiss:YES];
                }
                default:
                    break;
            }
            [popupDialog dismiss];
        });
    }
}

- (NSString*)getDefaultPDFTempFilePath{
    NSString* filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    filePath = [NSString stringWithFormat:@"%@/%@",filePath,RICEDEFAULTPDFFILENAME];
    return filePath;
}

- (void)removePDFFile{
    NSString* filePath = [self getDefaultPDFTempFilePath];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)dismiss:(BOOL)animated{
    self.cancleDownload = YES;
    [super dismiss:animated];
}

- (BOOL)didFinishRead:(PDFViewController*)viewController{
    [self removePDFFile];
    self.isFinishRead = YES;
    if (self.navigationController != nil && [self.navigationController.viewControllers containsObject:self]) {
        NSInteger selfIndex = [self.navigationController.viewControllers indexOfObject:self];
        if (selfIndex > 0) {
            [self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:selfIndex] animated:NO];
            [self dismiss:YES];
            return NO;
        }
    }
    return YES;
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

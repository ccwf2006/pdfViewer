//
//  PDFViewController.m
//  rice-ios
//
//  Created by gslicai on 16/11/18.
//  Copyright © 2016年 gslicai. All rights reserved.
//

#import "PDFViewController.h"
#import "PDFContentViewController.h"

@interface PDFViewController ()<UIPageViewControllerDataSource, UIPageViewControllerDelegate,UIGestureRecognizerDelegate>{
    CGPDFDocumentRef _pdfDocument;
    size_t _totalPageNum;
    size_t _currentPageNum;
    size_t _tmpPageNum;
    CGPDFPageRef _currentPage;
}
@property (nonatomic,strong) UIPageViewController* pdfReaderViewController;
@property (nonatomic,assign) BOOL pageViewAnimating;
@property (nonatomic,strong) PDFContentViewController* pdfCurrentViewController;

@property (nonatomic,strong) PDFContentViewController* pdfPreviousViewController;
@property (nonatomic,strong) PDFContentViewController* pdfNextViewController;

@property (nonatomic,strong) UITapGestureRecognizer* resumeZoomGesture;

@property (nonatomic,copy) NSString* pdfFilePath;
@end

@implementation PDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self createUI];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(self.navigationController){
        [self setTitleBarBackgroundGradient:@[color(0xFFF8F8F8), color(0xFFF8F8F8)]];
        [self setTitleBarSplitLineColor:color(0xFFE7E7E7)];
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [UINavigationController attemptRotationToDeviceOrientation];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden{
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait) {
        return YES;
    }
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (void)createUI{
    self.automaticallyAdjustsScrollViewInsets = NO;
    if(self.navigationController){
        [self setTitleBarBackgroundGradient:@[color(0xFFF8F8F8), color(0xFFF8F8F8)]];
        [self setTitleBarSplitLineColor:color(0xFFE7E7E7)];
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
//    self.navigationItem.title = @"PDF";
    
    
    self.pdfReaderViewController = [[UIPageViewController alloc]initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    [self addChildViewController:self.pdfReaderViewController];
    [self.view addSubview:self.pdfReaderViewController.view];
    //[self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.pdfReaderViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.pdfReaderViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).mas_offset(64);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    
    self.pdfReaderViewController.delegate = self;
    self.pdfReaderViewController.dataSource = self;
    self.pageViewAnimating = NO;
    self.view.backgroundColor = color(0xFFF3F3F3);
    UIViewController* emptyViewController = [[UIViewController alloc]init];
    emptyViewController.view.backgroundColor = color(0xFFF3F3F3);
    [self.pdfReaderViewController setViewControllers:@[emptyViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
//    if (self.navigationController) {
//        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:self.backButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(leftBarButtonClick:)];
//    }
    
    self.resumeZoomGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(resumeZoomByGesture:)];
    [self.resumeZoomGesture setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:self.resumeZoomGesture];
    self.resumeZoomGesture.delegate = self;
    for (UIGestureRecognizer* gesture in self.pdfReaderViewController.gestureRecognizers) {
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            [gesture requireGestureRecognizerToFail:self.resumeZoomGesture];
        }
    }
    
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    //以后尝试用 topLayoutGuide 解决
    
    if (size.width > size.height && ([[UIDevice currentDevice].model isEqualToString:@"iPhone"] || [[UIDevice currentDevice].model isEqualToString:@"iPod touch"])) {
        [self.pdfReaderViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
            if (size.height == 414) {
                make.top.equalTo(self.view.mas_top).mas_offset(44);

            }else{
                make.top.equalTo(self.view.mas_top).mas_offset(32);

            }
        }];
    }else{
        [self.pdfReaderViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_top).mas_offset(64);
        }];
    }
    
    if (size.width > size.height && ([[UIDevice currentDevice].model isEqualToString:@"iPhone"] || [[UIDevice currentDevice].model isEqualToString:@"iPod touch"])) {//横屏
        if (size.height == 414) {
            self.titleBarBackground.frame = CGRectMake(0, 0, size.width, 44);
            
        }else{
            self.titleBarBackground.frame = CGRectMake(0, 0, size.width, 32);
            
        }
    }else{//竖屏
        self.titleBarBackground.frame = CGRectMake(0, 0, size.width, 64);
    }
    for (UIViewController* vc in self.pdfReaderViewController.viewControllers) {
        if ([vc isKindOfClass:[PDFContentViewController class]]) {
            PDFContentViewController* tmpvc = (PDFContentViewController*)vc;
            [tmpvc resumeScale:NO];
        }
    }
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    //NSLog(@"%lf %lf %lf %lf",self.view.bounds.origin.x,self.view.bounds.origin.y,self.view.bounds.size.width,self.view.bounds.size.height);
}

- (void)leftBarButtonClick:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishRead:)]) {
        BOOL res = [self.delegate didFinishRead:self];
        if (res) {
            [self dismiss:YES];
        }
    }else{
        [self dismiss:YES];
    }
}

- (void)startReadPDFFile:(NSString*)pdfPath{
    self.pdfFilePath = pdfPath;
    if (self.pdfReaderViewController != nil) {
        [self openPDFFile:pdfPath];
        _currentPageNum = 1;
        [self switchToPage:_currentPageNum animated:NO];
    }else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self openPDFFile:self.pdfFilePath];
            _currentPageNum = 1;
            [self switchToPage:_currentPageNum animated:NO];
        });
    }
}

#pragma UIPageViewControllerDataSource UIPageViewControllerDelegate
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    if (self.pdfPreviousViewController != nil) {
        PDFContentViewController* tmpPage = self.pdfPreviousViewController;
        return tmpPage;
    }
    return nil;
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    if (self.pdfNextViewController != nil) {
        PDFContentViewController* tmpPage = self.pdfNextViewController;
        return tmpPage;
    }
    return nil;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers{
    self.pageViewAnimating = YES;
    for (UIViewController* vc in pageViewController.viewControllers) {
        if ([vc isKindOfClass:[PDFContentViewController class]]) {
            PDFContentViewController* tmpvc = (PDFContentViewController*)vc;
            [tmpvc resumeScale:NO];
        }
    }
    if (pendingViewControllers.count > 0) {
        PDFContentViewController* currentPage = (PDFContentViewController*)[pendingViewControllers lastObject];
        _currentPageNum = currentPage.pageNumber;
        [self preparePageBuffer];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed{
    self.pageViewAnimating = NO;
    //    NSLog(@"%@",previousViewControllers);
    
    if (finished == YES && completed == NO) {
        if (previousViewControllers.count > 0) {
            PDFContentViewController* currentPage = (PDFContentViewController*)[previousViewControllers lastObject];
            _currentPageNum = currentPage.pageNumber;
            [currentPage resumeScale:NO];
            [self preparePageBuffer];
        }
        self.pageViewAnimating = NO;
    }
}

#pragma 操作 PDF 相关
//直接切换页面
- (void)switchToPage:(NSInteger)pageNumber animated:(BOOL)animated{
    self.pdfCurrentViewController = [self showPage:pageNumber];
    if (self.pdfCurrentViewController != nil) {
        _currentPageNum = pageNumber;
        [self.pdfReaderViewController setViewControllers:@[self.pdfCurrentViewController] direction:UIPageViewControllerNavigationDirectionForward animated:animated completion:nil];
    }
    [self preparePageBuffer];
}

- (void)preparePageBuffer{
    self.pdfPreviousViewController = [self preparePreviousPage:_currentPageNum];
    self.pdfNextViewController = [self prepareNextPage:_currentPageNum];
}

- (PDFContentViewController* _Nullable)prepareNextPage:(NSInteger)currentPage{
    if (_totalPageNum > 0 && (currentPage + 1) <= _totalPageNum && (currentPage + 1) > 0) {
        return [self showPage:(currentPage +1)];
    }else{
        return nil;
    }
}

- (PDFContentViewController* _Nullable)preparePreviousPage:(NSInteger)currentPage{
    if (_totalPageNum > 0 && (currentPage - 1) <= _totalPageNum && (currentPage - 1) > 0) {
        return [self showPage:(currentPage -1)];
    }else{
        return nil;
    }
}


- (void)resumeZoomByGesture:(UITapGestureRecognizer*)pSender{
    for (UIViewController* vc in self.pdfReaderViewController.viewControllers) {
        if ([vc isKindOfClass:[PDFContentViewController class]]) {
            PDFContentViewController* tmpvc = (PDFContentViewController*)vc;
            CGFloat currentScale = [tmpvc getCurrentScale];
            if (currentScale > 1) {
                [tmpvc resumeScale:YES];

            }else{
                [tmpvc aspectWidthScale:YES];
            }
            
        }
    }
}

#pragma 打开 PDF 相关
- (BOOL)openPDFFile:(NSString*)filePath{
    if (_pdfDocument != nil) {
        CGPDFDocumentRelease(_pdfDocument);
        _pdfDocument = nil;
    }
    NSURL* pdfURL = [NSURL fileURLWithPath:filePath];
    CFStringRef cfpdfURLStr = CFStringCreateWithCString(CFAllocatorGetDefault(), pdfURL.path.UTF8String, kCFStringEncodingUTF8);
    CFURLRef cfpdfURL = CFURLCreateWithFileSystemPath(CFAllocatorGetDefault(), cfpdfURLStr, kCFURLPOSIXPathStyle, NO);
    
    _pdfDocument = CGPDFDocumentCreateWithURL(cfpdfURL);
    CFRelease(cfpdfURL);
    CFRelease(cfpdfURLStr);
    if (_pdfDocument == nil) {
        return NO;
    }
    
    _totalPageNum = CGPDFDocumentGetNumberOfPages(_pdfDocument);
    
    return YES;
}

- (PDFContentViewController* _Nullable)showPage:(size_t)pageNum{
    if (_totalPageNum > 0 && pageNum <= _totalPageNum && pageNum > 0) {
//        if (_currentPage != nil) {
//            CGPDFPageRelease(_currentPage);
//            _currentPage = nil;
//        }
        _currentPage = CGPDFDocumentGetPage(_pdfDocument, pageNum);
        PDFContentViewController* pdfContentViewController = [[PDFContentViewController alloc]init];
        [pdfContentViewController showPdfPage:_currentPage];
        pdfContentViewController.pageNumber = pageNum;
        return pdfContentViewController;
    }else{
        return nil;
    }
}

#pragma GestureDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == self.resumeZoomGesture && self.pageViewAnimating == NO) {
        return YES;
    }
    return NO;
}

- (void)dealloc{
    //释放 PDFDocument 的时候,似乎也会释放 PDFPage
    //确定了,使用CGPDFDocumentRelease释放 PDFDocument 时候,会将最后获取的 PDFPage 一起释放
    //好奇怪的设计 https://stackoverflow.com/questions/46903182/cgcontextdrawpdfpage-memory-leak-app-crash
    if (_pdfDocument != nil) {
        CGPDFDocumentRelease(_pdfDocument);
        _pdfDocument = nil;
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

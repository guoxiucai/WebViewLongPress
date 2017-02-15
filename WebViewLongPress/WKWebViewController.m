//
//  WKWebViewController.m
//  WebViewLongPress
//
//  Created by guoqingwei on 2017/2/15.
//  Copyright © 2017年 cvte. All rights reserved.
//

#import "WKWebViewController.h"
#import "FSActionSheet.h"

#define iOS7_OR_EARLY ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)

static const NSTimeInterval KLongGestureInterval = 0.6f;

typedef NS_ENUM(NSInteger, WKSelectItem) {
    WKSelectItemSaveImage,
    WKSelectItemQRExtract
};

@interface WKWebViewController () <WKNavigationDelegate, UIGestureRecognizerDelegate,FSActionSheetDelegate>

@property (nonatomic, strong) NSString *qrCodeString;

@property (nonatomic, strong) UIImage *saveimage;

@end

@implementation WKWebViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"WKWebView";
    
    NSString *urlString = @"mp.weixin.qq.com/s?__biz=MzI2ODAzODAzMw==&mid=2650057120&idx=2&sn=c875f7d03ea3823e8dcb3dc4d0cff51d&scene=0#wechat_redirect";
    
//    NSString *urlString = @"https://ad.seewo.com/?p=126";
    
    self.url = [self autoFillURL:[NSURL URLWithString:urlString]];
    
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.url]];
}

- (WKWebView *)webView
{
    if (_webView == nil) {
        
        // this js script help to disable callouts in WKWebView.
        NSString *source = @"var style = document.createElement('style'); \
                            style.type = 'text/css'; \
                            style.innerText = '*:not(input):not(textarea) { -webkit-user-select: none; -webkit-touch-callout: none; }'; \
                            var head = document.getElementsByTagName('head')[0];\
                            head.appendChild(style);";
        
        WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        // Create the user content controller and add the script to it
        WKUserContentController *userContentController = [WKUserContentController new];
        [userContentController addUserScript:script];
        
        // Create the configuration with the user content controller
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.userContentController = userContentController;
        
        
        //begin
        //I don't know why? When I add this code snip, it works fine! Otherwise, it works bad.
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        [self.view addSubview:view];
        // end
        
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _webView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.contentMode = UIViewContentModeRedraw;
        _webView.navigationDelegate = self;
        _webView.allowsBackForwardNavigationGestures = YES;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = KLongGestureInterval;
        longPress.allowableMovement = 20.f;
        longPress.delegate = self;
        [_webView addGestureRecognizer:longPress];
    }
    return _webView;
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"start load");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"fail load");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"fali navigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"finish load");
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - FSActionSheetDelegate

- (void)FSActionSheet:(FSActionSheet *)actionSheet selectedIndex:(NSInteger)selectedIndex
{
    switch (selectedIndex) {
        case WKSelectItemSaveImage:
        {
            UIImageWriteToSavedPhotosAlbum(self.saveimage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
            break;
        case WKSelectItemQRExtract:
        {
            NSURL *qrUrl = [NSURL URLWithString:self.qrCodeString];
            //open with safari
            if ([[UIApplication sharedApplication] canOpenURL:qrUrl]) {
                [[UIApplication sharedApplication] openURL:qrUrl];
            }
            // open in inner webview
            //[self.webView loadRequest:[NSURLRequest requestWithURL:qrUrl]];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Save image callback

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *message = @"Succeed";
    
    if (error) {
        message = @"Fail";
    }
    NSLog(@"save result :%@", message);
}

#pragma mark - Private methods

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [sender locationInView:self.webView];
    // get image url where pressed.
    NSString *imgJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    
    [self.webView evaluateJavaScript:imgJS completionHandler:^(id _Nullable imageUrl, NSError * _Nullable error) {
        
        if (imageUrl) {
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
            
            UIImage *image = [UIImage imageWithData:data];
            if (!image) {
                NSLog(@"read fail");
                return;
            }
            self.saveimage = image;
            
            FSActionSheet *actionSheet = nil;
            
            if ([self isAvailableQRcodeIn:image]) {
                
                actionSheet = [[FSActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                            highlightedButtonTitle:nil
                                                 otherButtonTitles:@[@"Save Image", @"Extract QR code"]];
                
            } else {
                
                actionSheet = [[FSActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                            highlightedButtonTitle:nil
                                                 otherButtonTitles:@[@"Save Image"]];
            }
            [actionSheet show];
        }
    }];
}

- (BOOL)isAvailableQRcodeIn:(UIImage *)img
{
    if (iOS7_OR_EARLY) {
        return NO;
    }
    
    //Extract QR code by screenshot
    //UIImage *image = [self snapshot:self.view];
    
    UIImage *image = [self imageByInsetEdge:UIEdgeInsetsMake(-20, -20, -20, -20) withColor:[UIColor lightGrayColor] withImage:img];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{}];
    
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    
    if (features.count >= 1) {
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        
        self.qrCodeString = [feature.messageString copy];
        
        NSLog(@"QR result :%@", self.qrCodeString);
        
        return YES;
    } else {
        NSLog(@"No QR");
        return NO;
    }
}

// you can also implement by UIView category
- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, view.window.screen.scale);
    
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

// you can also implement by UIImage category
- (UIImage *)imageByInsetEdge:(UIEdgeInsets)insets withColor:(UIColor *)color withImage:(UIImage *)image
{
    CGSize size = image.size;
    size.width -= insets.left + insets.right;
    size.height -= insets.top + insets.bottom;
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }
    CGRect rect = CGRectMake(-insets.left, -insets.top, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (color) {
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CGPathAddRect(path, NULL, rect);
        CGContextAddPath(context, path);
        CGContextEOFillPath(context);
        CGPathRelease(path);
    }
    [image drawInRect:rect];
    UIImage *insetEdgedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return insetEdgedImage;
}

- (NSURL *)autoFillURL:(NSURL *)url
{
    //If no URL scheme was supplied, defer back to HTTP.
    if (url.scheme.length == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
    }
    
    return url;
}

@end

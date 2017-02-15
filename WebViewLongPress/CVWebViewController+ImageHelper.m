//
//  CVWebViewController+ImageHelper.m
//  WebViewLongPress
//
//  Created by guoqingwei on 16/6/14.
//  Copyright © 2016年 cvte. All rights reserved.
//

#import "CVWebViewController+ImageHelper.h"
#import "SwizzeMethod.h"
#import "RNCachingURLProtocol.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, SelectItem) {
    SelectItemSaveImage,
    SelectItemQRExtract
};

#define iOS7_OR_EARLY ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)

//injected javascript
static NSString *const kTouchJavaScriptString =
        @"document.ontouchstart=function(event){\
            x=event.targetTouches[0].clientX;\
            y=event.targetTouches[0].clientY;\
            document.location=\"myweb:touch:start:\"+x+\":\"+y;};\
        document.ontouchmove=function(event){\
            x=event.targetTouches[0].clientX;\
            y=event.targetTouches[0].clientY;\
            document.location=\"myweb:touch:move:\"+x+\":\"+y;};\
        document.ontouchcancel=function(event){\
            document.location=\"myweb:touch:cancel\";};\
            document.ontouchend=function(event){\
            document.location=\"myweb:touch:end\";};";

static NSString *const kImageJS               = @"keyForImageJS";
static NSString *const kImage                 = @"keyForImage";
static NSString *const kImageQRString         = @"keyForQR";

static const NSTimeInterval KLongGestureInterval = 0.8f;


@implementation CVWebViewController (ImageHelper)

+(void)load
{
    [super load];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self hookWebView];
    });
}

+ (void)hookWebView
{
    SwizzlingMethod([self class], @selector(webViewDidStartLoad:), @selector(sl_webViewDidStartLoad:));
    SwizzlingMethod([self class], @selector(webView:shouldStartLoadWithRequest:navigationType:), @selector(sl_webView:shouldStartLoadWithRequest:navigationType:));
    SwizzlingMethod([self class], @selector(webViewDidFinishLoad:), @selector(sl_webViewDidFinishLoad:));
}

#pragma mark - seter and getter

- (void)setImageJS:(NSString *)imageJS
{
    objc_setAssociatedObject(self, &kImageJS, imageJS, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)imageJS
{
    return objc_getAssociatedObject(self, &kImageJS);
}

- (void)setQrCodeString:(NSString *)qrCodeString
{
    objc_setAssociatedObject(self, &kImageQRString, qrCodeString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)qrCodeString
{
    return objc_getAssociatedObject(self, &kImageQRString);
}

- (void)setImage:(UIImage *)image
{
    objc_setAssociatedObject(self, &kImage, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)image
{
    return objc_getAssociatedObject(self, &kImage);
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

#pragma mark - FSActionSheetDelegate

- (void)FSActionSheet:(FSActionSheet *)actionSheet selectedIndex:(NSInteger)selectedIndex
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='text';"];
    
    switch (selectedIndex) {
        case SelectItemSaveImage:
        {
            UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
            break;
        case SelectItemQRExtract:
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

#pragma mark - swizing

- (BOOL)sl_webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *requestString = [[request URL] absoluteString];
    
    NSArray *components = [requestString componentsSeparatedByString:@":"];
    
    if ([components count] > 1 && [(NSString *)[components objectAtIndex:0] isEqualToString:@"myweb"]) {
        
        if([(NSString *)[components objectAtIndex:1] isEqualToString:@"touch"]) {
            
            if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"start"]) {
                
                NSLog(@"touch start!");
                
                float pointX = [[components objectAtIndex:3] floatValue];
                float pointY = [[components objectAtIndex:4] floatValue];
                
                NSLog(@"touch point (%f, %f)", pointX, pointY);
                
                NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", pointX, pointY];
                
                NSString * tagName = [self.webView stringByEvaluatingJavaScriptFromString:js];
                
                self.imageJS = nil;
                if ([tagName isEqualToString:@"IMG"]) {
                    
                    self.imageJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", pointX, pointY];
                    
                }
                
            } else {
                
                if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"move"]) {
                    NSLog(@"you are move");
                } else {
                    if ([(NSString *)[components objectAtIndex:2] isEqualToString:@"end"]) {
                        NSLog(@"touch end");
                    }
                }
            }
        }
        
        if (self.imageJS) {
            NSLog(@"touching image");
        }
        
        return NO;
    }
    
    return [self sl_webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)sl_webViewDidStartLoad:(UIWebView *)webView
{
    //Add long press gresture for web view
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = KLongGestureInterval;
    longPress.delegate = self;
    [self.webView addGestureRecognizer:longPress];
    
    [self sl_webViewDidStartLoad:webView];
}

- (void)sl_webViewDidFinishLoad:(UIWebView *)webView
{
    //cache manager
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    
    //inject js
    [webView stringByEvaluatingJavaScriptFromString:kTouchJavaScriptString];
    
    [self sl_webViewDidFinishLoad:webView];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    if ([self isTouchingImage]) {
        if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            otherGestureRecognizer.enabled = NO;
            otherGestureRecognizer.enabled = YES;
        }
        
        return YES;
    }
    
    return NO;
}

#pragma mark - private Method
- (BOOL)isTouchingImage
{
    if (self.imageJS) {
        return YES;
    }
    return NO;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    NSString *imageUrl = [self.webView stringByEvaluatingJavaScriptFromString:self.imageJS];
    
    if (imageUrl) {
        
        NSData *data = nil;
        NSString *fileName = [RNCachingURLProtocol cachePathForURLString:imageUrl];
        
        RNCachedData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
        
        if (cache) {
            NSLog(@"read from cache");
            data = cache.data;
        } else{
            NSLog(@"read from url");
            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        }
        
        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
            NSLog(@"read fail");
            return;
        }
        self.image = image;
        
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

@end

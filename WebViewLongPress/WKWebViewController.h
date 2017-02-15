//
//  WKWebViewController.h
//  WebViewLongPress
//
//  Created by guoqingwei on 2017/2/15.
//  Copyright © 2017年 cvte. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface WKWebViewController : UIViewController

@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) WKWebView *webView;

@end

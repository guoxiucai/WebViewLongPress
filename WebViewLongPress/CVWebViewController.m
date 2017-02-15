//
//  CVWebViewController.m
//  WebViewLongPress
//
//  Created by guoqingwei on 16/6/14.
//  Copyright © 2016年 cvte. All rights reserved.
//

#import "CVWebViewController.h"

@implementation CVWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"UIWebView";
    
    NSString *urlString = @"mp.weixin.qq.com/s?__biz=MzI2ODAzODAzMw==&mid=2650057120&idx=2&sn=c875f7d03ea3823e8dcb3dc4d0cff51d&scene=0#wechat_redirect";

    self.url = [self autoFillURL:[NSURL URLWithString:urlString]];
    
    [self.view addSubview:self.webView];

    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.url]];
}

- (UIWebView *)webView
{
    if (_webView == nil) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.delegate = self;
    }
    return _webView;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"start load");
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"finish load");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"load fail");
}

#pragma mark - private methods

- (NSURL *)autoFillURL:(NSURL *)url
{
    //If no URL scheme was supplied, defer back to HTTP.
    if (url.scheme.length == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
    }
    
    return url;
}


@end

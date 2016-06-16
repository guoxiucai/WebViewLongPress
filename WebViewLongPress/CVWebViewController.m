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
    
//    NSString *urlString = @"mp.weixin.qq.com/s?__biz=MzI2ODAzODAzMw==&mid=2650057120&idx=2&sn=c875f7d03ea3823e8dcb3dc4d0cff51d&scene=0#wechat_redirect";
    
    
    NSString *urlString = @"http://mp.weixin.qq.com/s?__biz=MjM5OTM0MzIwMQ==&mid=2652545580&idx=3&sn=afdb93c3fe9ed184f31c4c3d1c5be2c7&scene=0#wechat_redirect";
    
    self.url = [self cleanURL:[NSURL URLWithString:urlString]];
    
    self.webView.delegate = self;
    
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.url]];
}


#pragma mark - private methods
- (NSURL *)cleanURL:(NSURL *)url
{
    //If no URL scheme was supplied, defer back to HTTP.
    if (url.scheme.length == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [url absoluteString]]];
    }
    
    return url;
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

@end

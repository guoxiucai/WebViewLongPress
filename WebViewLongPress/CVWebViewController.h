//
//  CVWebViewController.h
//  WebViewLongPress
//
//  Created by guoqingwei on 16/6/14.
//  Copyright © 2016年 cvte. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CVWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *url;

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

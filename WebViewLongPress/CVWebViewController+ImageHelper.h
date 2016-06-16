//
//  CVWebViewController+ImageHelper.h
//  WebViewLongPress
//
//  Created by guoqingwei on 16/6/14.
//  Copyright © 2016年 cvte. All rights reserved.
//

#import "CVWebViewController.h"
#import "FSActionSheet.h"

@interface CVWebViewController (ImageHelper)<UIWebViewDelegate, UIGestureRecognizerDelegate, FSActionSheetDelegate>

/**
 * get image's url from this javascript
 */
@property (nonatomic, strong) NSString *imageJS;

/**
 * image's qr code string, if have
 * or nil
 */
@property (nonatomic, strong) NSString *qrCodeString;

/**
 * image
 */
@property (strong, nonatomic) UIImage *image;

@end

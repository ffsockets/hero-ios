//
//  MEImageView.m
//  on2me
//
//  Created by atman on 14/12/18.
//  Copyright (c) 2014年 GPLIU. All rights reserved.
//

#import "HeroImageView.h"
#import "UILazyImageView.h"
#import "DACircularProgressView.h"

@interface HeroImageView ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, NSURLConnectionDataDelegate,UIScrollViewDelegate>

@end

@implementation HeroImageView {
    UILabel *emptyLabel;
    UIImage *selectedImage;
    NSString *savePath;
    UIActionSheet *actionSheet;
    NSString *uploadUrl;
    NSData *pngData;
    NSMutableURLRequest *request;
    NSMutableData *_responseData;
    UIView *shadowView;
    DACircularProgressView *progressView;
    NSString *sessionId;
    NSString *uploadName;
    id readyObject;
    id deleteObject;
    BOOL showBig;
    UIImageView *bigImageView;
    UIButton *deleteBtn;
    BOOL allowsEditing;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        allowsEditing = NO;
    }
    return self;
}

-(void)on:(NSDictionary *)json
{
    [super on:json];
    if (json[@"allowsEditing"]) {
        allowsEditing = [json[@"allowsEditing"] boolValue];
    }
    if (json[@"base64image"]) {
        NSString *imageStr = json[@"base64image"];
        NSRange range = [imageStr rangeOfString:@"^data:image/\\w+;base64," options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            self.image = [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:[imageStr substringFromIndex:range.length] options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        } else{
            [UILazyImageView registerForName:imageStr block:^(NSData *data) {
                if (data.length > 400) {
                    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                    NSRange range = [str rangeOfString:@"^data:image/\\w+;base64," options:NSRegularExpressionSearch];
                    if (range.location != NSNotFound) {
                        self.image = [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:[str substringFromIndex:range.length] options:NSDataBase64DecodingIgnoreUnknownCharacters]];
                    } else{
                        self.image = [UIImage imageWithData:data];
                    }
                }
            }];
        }
    }
    if (json[@"image"]) {
        NSString *imageStr = json[@"image"];
        if ([imageStr hasPrefix:@"http"]) {
            NSString *animation = json[@"animation"];
            int scale = [[UIScreen mainScreen]scale];
            [UILazyImageView registerForName:imageStr block:^(NSData *data) {
                self.alpha = 0.0f;
                self.image = [UIImage imageWithData:data scale:scale];
                [UIView animateWithDuration:animation?0.2:0.0 animations:^{
                    self.alpha = 1.0f;
                }];
            }];
        } else{
            self.image = [UIImage imageNamed:imageStr];
        }
    }
    if (json[@"JSESSIONID"]) {
        //        sessionId = json[@"JSESSIONID"];
        //        NSDictionary *cookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:
        //                                          @"JSESSIONID", NSHTTPCookieName,
        //                                          sessionId, NSHTTPCookieValue,
        //                                          @"www-dev.dianrong.com", NSHTTPCookieDomain,
        //                                          @"/", NSHTTPCookiePath,
        //                                          nil];
        //        NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:cookieProperties];
        //        DLog(@"cookie: %@", cookie);
        //        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
    if (json[@"uploadName"]) {
        uploadName = json[@"uploadName"];
    }
    if (json[@"localImageReady"]) {
        readyObject = json[@"localImageReady"];
    }
    if (json[@"localImageDelete"]) {
        deleteObject = json[@"localImageDelete"];
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        if (!deleteBtn) {
            deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            deleteBtn.frame = CGRectMake(self.frame.size.width-20, 0, 20, 20);
            [deleteBtn setTitle:@"X" forState:UIControlStateNormal];
            [deleteBtn setTitleColor:[UIColor whiteColor]  forState:UIControlStateNormal];
            deleteBtn.backgroundColor = [UIColor grayColor];
            deleteBtn.clipsToBounds = YES;
            deleteBtn.layer.cornerRadius = deleteBtn.bounds.size.width/2;
            [self addSubview:deleteBtn];
            [deleteBtn addTarget:self action:@selector(onDelete:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    if (json[@"showBig"]) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTap:)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tap];
    }
    if (json[@"localImage"]) {
        NSString *localImage = json[@"localImage"];
        uploadUrl = json[@"uploadUrl"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *findPath = nil;
        if ([localImage hasPrefix:@"/"]) {
            findPath = localImage;
        } else {
            NSArray *paths = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSURL *documentsURL = [paths firstObject];
            if (documentsURL) {
                findPath = [documentsURL.path stringByAppendingPathComponent:localImage];
            }
        }

        // 存在本地目录
        if ([fileManager fileExistsAtPath:findPath]) {
            self.image = [UIImage imageWithContentsOfFile:findPath];
            [self localImageReady:YES];
        } else {
            savePath = findPath;
            self.image = nil;
            emptyLabel = [[UILabel alloc] initWithFrame:self.bounds];
            emptyLabel.userInteractionEnabled = YES;
            emptyLabel.font = [UIFont systemFontOfSize:72];
            emptyLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            emptyLabel.minimumScaleFactor = 12 / emptyLabel.font.pointSize;
            emptyLabel.adjustsFontSizeToFitWidth = YES;
            emptyLabel.textColor = UIColorFromRGB(0x444444);
            emptyLabel.textAlignment = NSTextAlignmentCenter;
            emptyLabel.text = @"﹢";
            [self addSubview:emptyLabel];
            CAShapeLayer *dashedborder = [CAShapeLayer layer];
            dashedborder.strokeColor = UIColorFromRGB(0x999999).CGColor;
            dashedborder.fillColor = nil;
            dashedborder.lineDashPattern = @[@4, @2];
            dashedborder.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
            dashedborder.frame = self.bounds;
            [emptyLabel.layer addSublayer:dashedborder];
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAdderTapped:)];
            self.userInteractionEnabled = YES;
            [emptyLabel addGestureRecognizer:tapGesture];
            [self localImageReady:NO];
        }
    }
    if (json[@"getImage"]) {
        self.image = nil;
        uploadUrl = json[@"uploadUrl"];

        [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self removeGestureRecognizer:obj];
        }];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAdderTapped:)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tapGesture];
    }
    if (json[@"getImageData"]) {
        float qulity = [json[@"getImageData"] floatValue];
        NSData *datas = UIImageJPEGRepresentation(self.image, qulity);
        NSDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:json];
        [dict setValue:datas forKey:@"value"];
        [self.controller on:dict];
    }
}

- (void)onAdderTapped:(id)sender {
    if (!actionSheet) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照", @"从相册选择", nil];
    }
    [KEY_WINDOW endEditing:YES];
    [actionSheet showInView:ROOT_VIEW];
}
-(void)onTap:(id)sender{
    CGRect rect = [self.superview convertRect:self.frame toView:KEY_WINDOW];
    UIScrollView *backgroundView = [[UIScrollView alloc]initWithFrame:rect];
    backgroundView.scrollEnabled = YES;
    backgroundView.maximumZoomScale = 2.0f;
    backgroundView.minimumZoomScale = 0.2f;
    backgroundView.bouncesZoom = false;
    backgroundView.delegate = self;
    backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    backgroundView.tag = 8989778;
    backgroundView.alpha = 0.1f;
    bigImageView = [[UIImageView alloc]initWithFrame:backgroundView.bounds];
    bigImageView.image = self.image;
    bigImageView.contentMode = UIViewContentModeScaleAspectFit;
    [backgroundView addSubview:bigImageView];
    UITapGestureRecognizer *doneTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTapDone:)];
    doneTap.delaysTouchesBegan = true;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTapDouble:)];
    doubleTap.numberOfTapsRequired = 2;
    [doneTap requireGestureRecognizerToFail:doubleTap];
    [backgroundView addGestureRecognizer:doneTap];
    [backgroundView addGestureRecognizer:doubleTap];
    [KEY_WINDOW addSubview:backgroundView];
    [UIView animateWithDuration:0.3 animations:^{
        backgroundView.alpha = 1.0f;
        backgroundView.frame= [UIScreen mainScreen].bounds;
        bigImageView.frame= [UIScreen mainScreen].bounds;
    }];
}
-(void)onTapDone:(id)sender{
    UIView *view = [KEY_WINDOW viewWithTag:8989778];
    [UIView animateWithDuration:0.2 animations:^{
        view.alpha= 0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}
-(void)onTapDouble:(UITapGestureRecognizer*)sender{
    [((UIScrollView*)sender.view) setZoomScale:1.5f animated:YES];
}
-(void)onDelete:(id)sender{
    if (deleteObject) {
        [self.controller on:deleteObject];
    }
}
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return bigImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    bigImageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (scale < .5f) {
        [self onTapDone:nil];
    }
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (0 == buttonIndex) {
        UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        imagePickerVC.delegate = self;
        imagePickerVC.allowsEditing = allowsEditing;
        [self.controller presentViewController:imagePickerVC animated:YES completion:nil];
    } else if (1 == buttonIndex) {
        UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        imagePickerVC.delegate = self;
        imagePickerVC.allowsEditing = allowsEditing;
        [self.controller presentViewController:imagePickerVC animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (allowsEditing) {
        selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    }

    pngData = UIImageJPEGRepresentation(selectedImage, 0.3);
    if (uploadUrl) {
        [self uploadImage];
    } else {
        [UIImageJPEGRepresentation(selectedImage, 0.3) writeToFile:savePath atomically:YES];
        emptyLabel.text = nil;
        emptyLabel.hidden = YES;
        [self onShadowViewTapped];
        self.image = selectedImage;
        [self localImageReady:YES];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadImage {
    [self initPB];
    if( [self setParams]){
        //Creates and returns an initialized URL connection and begins to load the data for the URL request.
        if([NSURLConnection connectionWithRequest:request delegate:self]){
        };
    }
}

#pragma mark - NSURLConnection Upload Image

-(void) initPB{
    shadowView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    shadowView.backgroundColor = [UIColor blackColor];
    shadowView.alpha = 0.3;
    [ROOT_VIEW addSubview:shadowView];

    progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width)/2, ([UIScreen mainScreen].bounds.size.height)/2, 40.0f, 40.0f)];
    progressView.roundedCorners = YES;
    progressView.trackTintColor = [UIColor clearColor];
    [ROOT_VIEW addSubview:progressView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
}

-(BOOL) setParams{
    if(pngData != nil){
        request = [NSMutableURLRequest new];
        request.timeoutInterval = 20.0;
        [request setURL:[NSURL URLWithString:uploadUrl]];
        [request setHTTPMethod:@"POST"];

        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

        NSMutableData *body = [NSMutableData data];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.jpg\"\r\n", uploadName, uploadName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:pngData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        [request setHTTPBody:body];
        [request addValue:[NSString stringWithFormat:@"%@", [NSNumber numberWithInteger:[body length]]] forHTTPHeaderField:@"Content-Length"];

        return TRUE;

    } else{
        return FALSE;
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    CGFloat percentage = totalBytesWritten * 1.0 / totalBytesExpectedToWrite;
    [progressView setProgress:percentage animated:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (_responseData) {
        NSError *err;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableContainers error:&err];
        if (json) {
            if ([@"success" isEqualToString:json[@"result"]]) {
                DLog(@"upload success: %@", json);
                [UIImageJPEGRepresentation(selectedImage, 0.3) writeToFile:savePath atomically:YES];
                emptyLabel.text = nil;
                emptyLabel.hidden = YES;
                [self onShadowViewTapped];
                self.image = selectedImage;
                [self localImageReady:YES];
            } else {
                if (json[@"errors"]) {
                    [self.controller on:@{@"name":@"toast",@"text":json[@"errors"][0]}];
                }
                [self onShadowViewTapped];
                [self localImageReady:NO];
            }
        } else {
            NSString *responseText = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
            DLog(@"server error: %@", responseText);
            [self.controller on:@{@"name":@"toast",@"text":@"SERVER ERROR"}];
            [self onShadowViewTapped];
            [self localImageReady:NO];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    [self onShadowViewTapped];
    [self localImageReady:NO];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
    DLog(@"didFailWithError %@", error);
    [self.controller on:@{@"name":@"toast",@"text":@"NETWORK ERROR"}];
}

- (void)onShadowViewTapped {
    [UIView animateWithDuration:0.8 animations:^{
        shadowView.alpha = 0.0;
    } completion:^(BOOL finished) {
        shadowView.hidden = YES;
        progressView.hidden = YES;
    }];
}

- (void)localImageReady:(BOOL)ok {
    if (deleteBtn) {
        deleteBtn.hidden = !ok;
    }
    if (readyObject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:readyObject];
            [dict setObject:@(ok) forKey:@"value"];
            [self.controller on:dict];
        });
    }
}

@end

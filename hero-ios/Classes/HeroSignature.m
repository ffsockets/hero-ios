//
//  HeroSignature.m
//  hero-ios
//
//  Created by Liu Guoping on 2018/10/26.
//

#import "HeroSignature.h"
#import "HeroAccount.h"
#import "HeroWallet.h"
#import "HeroColdWallet/NSData+HexString.h"
#import "HeroColdWallet/NSString+Hex.h"
#import "HeroColdWallet/HeroWalletListViewController.h"


Transaction *testTransaction;

@interface HeroSignView : UIView

@property (nonatomic, copy) void (^done)(NSDictionary *sig);

- (instancetype)initWithTransaction:(Transaction *)tran;
- (void)show;

@end

@interface HeroSignature ()

@end

@implementation HeroSignature {

}

-(void)on:(NSDictionary *)json{
    [super on:json];
    self.hidden = true;
    [[HeroWallet sharedInstance] loadAccounts];
    __weak HeroSignature *weakSelf = self;
    if (json[@"accounts"]) {
        NSArray *accs = [HeroWallet sharedInstance].accounts;
        NSMutableDictionary *result = [@{@"value": @[@""]} mutableCopy];
        NSMutableArray *addresses = [NSMutableArray array];
        [accs enumerateObjectsUsingBlock:^(HeroAccount *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [addresses addObject:obj.address];
        }];
        result[@"value"] = accs;
        
        if (json[@"isNpc"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
                NSString *js = [NSString stringWithFormat:@"window['%@callback'](%@)",[self class],[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                [self.controller.webview stringByEvaluatingJavaScriptFromString:js];
            });
        }else{
            [self.controller on:result];
        }
    }
    
    
    void (^signResult)(NSDictionary *sig) = ^(NSDictionary *sig) {
        NSDictionary *result;
        if (sig) {
            result = @{@"value": sig};
        } else {
            result = @{@"value": @"error"};
        }
        if (json[@"isNpc"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
                NSString *js = [NSString stringWithFormat:@"window['%@callback'](%@)",[weakSelf class],[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
                [weakSelf.controller.webview stringByEvaluatingJavaScriptFromString:js];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"签名成功" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                [alert show];
            });
        } else {
            [weakSelf.controller on:result];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"签名成功" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        }
    };
    
    if (json[@"message"]) {
        if ([[HeroWallet sharedInstance] defaultAccount]) {
            // message sign
            [self signMessage:json[@"message"] then:signResult];
        }else{
            //
            [[HeroWallet sharedInstance] importAccountThen:^{
                [weakSelf signMessage:json[@"message"] then:signResult];
            }];
        }
    }
    
    if (json[@"transaction"]) {
        Transaction *tran = [Transaction transactionWithJSON:json[@"transaction"]];
        
        if ([[HeroWallet sharedInstance] defaultAccount]) {
            [self signTx:tran then:signResult];
        } else {
            [[HeroWallet sharedInstance] importAccountThen:^{
                [weakSelf signTx:tran then:signResult];
            }];
        }
    }
    
    if (json[@"wallet"]) {
        HeroWalletListViewController *list = [[HeroWalletListViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
        list.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemCancel) target:list action:@selector(exitWallet)];
        [APP.keyWindow.rootViewController presentViewController:nav animated:YES completion:nil];
    }
}

- (void)signMessage:(NSString *)message then:(void(^)(NSDictionary *sig))done {
    [[[HeroWallet sharedInstance] defaultAccount] validatePasswordThen:^{
        done([[[HeroWallet sharedInstance] defaultAccount] sign:message]);
    }];
}

- (void)signTx:(Transaction *)tx then:(void(^)(NSDictionary *sig))done {
    HeroSignView *signView = [[HeroSignView alloc] initWithTransaction:tx];
    [signView show];
    signView.done = done;
}

@end


@implementation HeroSignView {
    Transaction *_tran;
    BOOL isFinger;
    UITextField *_passwordTextField;
}

- (instancetype)initWithTransaction:(Transaction *)tran {
    if (self = [super init]) {
        isFinger = NO;
        _tran = tran;
        
        [self setupUI];
    }
    return self;
}

- (void)show {
    [APP.keyWindow.rootViewController.view addSubview:self];
    self.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
}

- (void)setupUI {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exit)];
    UIView *top = [UIView new];
    top.backgroundColor = [UIColor clearColor];
    top.frame = CGRectMake(0, 0, SCREEN_W, 600);
    [top addGestureRecognizer:tap];
    top.backgroundColor = UIColorFromRGBA(0x605f5f, 0.7);
    [self addSubview:top];
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_H-600, SCREEN_W, SCREEN_H)];
    contentView.backgroundColor = [UIColor whiteColor];
    [self addSubview:contentView];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = @"签名";
    [contentView addSubview:titleLabel];
    titleLabel.textColor = UIColorFromRGB(0x333333);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:17];
    titleLabel.center = CGPointMake(SCREEN_W/2, 20);
    
    UIView *line = [UIView new];
    line.backgroundColor = UIColorFromRGB(0xdfdfdf);
    [contentView addSubview:line];
    line.frame = CGRectMake(30, 50, SCREEN_W - 2*30, 1);
    
    UILabel *fromLabel = [self keyLabel:@"from: "];
    [contentView addSubview:fromLabel];
    fromLabel.frame = CGRectMake(30, 71, 56, 20);
    
    UILabel *toLabel = [self keyLabel:@"to: "];
    [contentView addSubview:toLabel];
    toLabel.frame = CGRectMake(30, 99, 39, 20);
    
    UILabel *valueLabel = [self keyLabel:@"value: "];
    [contentView addSubview:valueLabel];
    valueLabel.frame = CGRectMake(30, 129, 56, 20);
    
    UILabel *nonceLabel = [self keyLabel:@"nonce: "];
    [contentView addSubview:nonceLabel];
    nonceLabel.frame = CGRectMake(30, 159, 56, 20);
    
    UILabel *gasLimitLabel = [self keyLabel:@"gasLimit: "];
    [contentView addSubview:gasLimitLabel];
    gasLimitLabel.frame = CGRectMake(30, 189, 80, 20);
    
    UILabel *gasLabel = [self keyLabel:@"gasPrice:"];
    [contentView addSubview:gasLabel];
    gasLabel.frame = CGRectMake(30, 219, 80, 20);
    
    UILabel *inputLabel = [self keyLabel:@"input data: "];
    [contentView addSubview:inputLabel];
    inputLabel.frame = CGRectMake(30, 249, 80, 20);
    
    UILabel *fromValue = [self valueLabel:[[HeroWallet sharedInstance] defaultAccount].address];
    [contentView addSubview:fromValue];
    fromValue.frame = CGRectMake(105, 71, SCREEN_W-101-30, 20);
    
    UILabel *toValue = [self valueLabel:_tran.toAddress.checksumAddress];
    [contentView addSubview:toValue];
    toValue.frame = CGRectMake(105, 99, SCREEN_W-101-30, 20);
    
    UILabel *valueValue = [self valueLabel:@(_tran.value.integerValue).stringValue];
    [contentView addSubview:valueValue];
    valueValue.frame = CGRectMake(105, 129, SCREEN_W-101-30, 20);
    
    UILabel *nonceValue = [self valueLabel:@(_tran.nonce).stringValue];
    [contentView addSubview:nonceValue];
    nonceValue.frame = CGRectMake(105, 159, SCREEN_W-101-30, 20);
    
    UILabel *gasLimitValue = [self valueLabel:@(_tran.gasLimit.integerValue).stringValue];
    [contentView addSubview:gasLimitValue];
    gasLimitValue.frame = CGRectMake(105, 189, SCREEN_W-101-30, 20);
    
    UILabel *gasPriceValue = [self valueLabel:@(_tran.gasPrice.integerValue).stringValue];
    [contentView addSubview:gasPriceValue];
    gasPriceValue.frame = CGRectMake(105, 219, SCREEN_W-101-30, 20);
    
    UITextView *inputTextView = [[UITextView alloc] init];
    inputTextView.text = [_tran.data hexString];
    [contentView addSubview:inputTextView];
    inputTextView.layer.borderColor = UIColorFromRGB(0x979797).CGColor;
    inputTextView.layer.borderWidth = 1;
    inputTextView.textColor = UIColorFromRGB(0xff6666);
    inputTextView.backgroundColor = UIColorFromRGB(0xfff0f0f0);
    inputTextView.font = [UIFont systemFontOfSize:14];
    inputTextView.frame = CGRectMake(40, 280, SCREEN_W-80, 110);
    
    if (isFinger) {
        
    } else {
        UILabel *confirmLabel = [UILabel new];
        confirmLabel.text = @"密钥认证";
        confirmLabel.font = [UIFont systemFontOfSize:14];
        [contentView addSubview:confirmLabel];
        confirmLabel.frame = CGRectMake(41, 413, 58, 17);
        
        UITextField *passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(41, 452, SCREEN_W-2*41, 35)];
        passwordTextField.borderStyle = UITextBorderStyleNone;
        passwordTextField.layer.borderColor = UIColorFromRGB(0xafafaf).CGColor;
        passwordTextField.layer.borderWidth = 1;
        passwordTextField.placeholder = @"输入密码";
        passwordTextField.secureTextEntry = YES;
        [contentView addSubview:passwordTextField];
        _passwordTextField = passwordTextField;
        
        UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [contentView addSubview:confirmButton];
        [confirmButton setTitle:@"确认" forState:UIControlStateNormal];
        [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        confirmButton.backgroundColor = self.tintColor;
        confirmButton.frame =  CGRectMake(41, 509, SCREEN_W-2*41, 35);
        [confirmButton addTarget:self action:@selector(sign) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (UILabel *)keyLabel:(NSString *)key {
    UILabel *l = [UILabel new];
    l.text = key;
    l.font = [UIFont systemFontOfSize:16];
    l.textColor = UIColorFromRGB(0x333333);
    
    return l;
}

- (UILabel *)valueLabel:(NSString *)value {
    UILabel *l = [UILabel new];
    l.text = value;
    l.font = [UIFont systemFontOfSize:16];
    l.textColor = UIColorFromRGB(0x999999);
    l.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    return l;
}

- (void)exit {
    [self removeFromSuperview];
}

- (void)sign {
    if ([_passwordTextField.text isEqualToString:[[HeroWallet sharedInstance] defaultAccount].password]) {
        if (self.done) {
            self.done([[[HeroWallet sharedInstance] defaultAccount] signTx:_tran]);
            [self removeFromSuperview];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"密码不正确" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
        [alert show];
    }
}

@end

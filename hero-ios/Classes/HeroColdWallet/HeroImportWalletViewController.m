//
//  HeroImportWalletViewController.m
//  hero-ios
//
//  Created by 李潇 on 2018/11/16.
//

#import "HeroImportWalletViewController.h"
#import "UIView+Hero.h"
#import "UIImage+color.h"
#import "UITextView+Placeholder.h"
#import "HeroWallet.h"
#import "UIAlertView+blockDelegate.h"

@interface HeroImportWalletViewController ()

@property (nonatomic, copy) void (^importThen)(void);

@property (nonatomic) UIButton *topKeystoreBtn;
@property (nonatomic) UIButton *topPrivateBtn;
@property (nonatomic) UIView *line;

@property (nonatomic) UIButton *currentButton;

@property (nonatomic) UIView *contentKeystore;
@property (nonatomic) UIView *contentPrivate;
@property (nonatomic) UIView *contentView;

@property (nonatomic) UITextView *keystoreTextView;
@property (nonatomic) UITextField *keystorePwdTextField;

@property (nonatomic) UITextView *privateTextView;
@property (nonatomic) UITextField *privatePwdTextField;
@property (nonatomic) UITextField *privateRepeatTextField;

@end

@implementation HeroImportWalletViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"导入钱包";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *top = [UIView new];
    [self.view addSubview:top];
    top.backgroundColor = [UIColor whiteColor];
    top.frame = CGRectMake(0, 64 + (isIPhoneXSeries() ? 24 : 0), SCREEN_W, 60);
    
    _topKeystoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_topKeystoreBtn setTitle:@"Keystore" forState:UIControlStateNormal];
    [_topKeystoreBtn setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateNormal];
    [_topKeystoreBtn setTitleColor:UIColorFromRGB(0x39adf9) forState:UIControlStateSelected];
    [top addSubview:_topKeystoreBtn];
    _topKeystoreBtn.frame = CGRectMake(0, 0, SCREEN_W/2, 60);
    [_topKeystoreBtn addTarget:self action:@selector(selectKeystore) forControlEvents:UIControlEventTouchUpInside];
    
    _topPrivateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_topPrivateBtn setTitle:@"私钥" forState:UIControlStateNormal];
    [_topPrivateBtn setTitleColor:UIColorFromRGB(0x666666) forState:UIControlStateNormal];
    [_topPrivateBtn setTitleColor:UIColorFromRGB(0x39adf9) forState:UIControlStateSelected];
    [top addSubview:_topPrivateBtn];
    _topPrivateBtn.frame = CGRectMake(SCREEN_W/2, 0, SCREEN_W/2, 60);
    [_topPrivateBtn addTarget:self action:@selector(selectPrivate) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *shortLine = [UIView new];
    shortLine.backgroundColor = UIColorFromRGB(0x9d9d9d);
    [top addSubview:shortLine];
    shortLine.frame = CGRectMake(0, 59, SCREEN_W, 1);
    
    _line = [UIView new];
    _line.backgroundColor = UIColorFromRGB(0x39adf9);
    [top addSubview:_line];
    _line.frame = CGRectMake(0, 57, SCREEN_W/2, 3);
    
    _contentView = [UIView new];
    [self.view addSubview:_contentView];
    _contentView.frame = CGRectMake(0, 124 + (isIPhoneXSeries() ? 24 : 0), SCREEN_W, SCREEN_H-124);
    _contentView.backgroundColor = [UIColor whiteColor];
    
    [self setupKeystoreView];
    [self setupPrivateView];
}

- (void)setupKeystoreView {
    _contentKeystore = [UIView new];
    [self.contentView addSubview:_contentKeystore];
    _contentKeystore.frame = self.contentView.bounds;
    UILabel *keystoreIntro = [UILabel new];
    keystoreIntro.text = @"直接复制粘贴以太坊官方钱包 keystore 文件内容至输入框。或者通过生产 keystore 内容的二维码，扫描录入。";
    keystoreIntro.textColor = UIColorFromRGB(0x999999);
    keystoreIntro.font = [UIFont systemFontOfSize:16];
    keystoreIntro.numberOfLines = 0;
    [_contentKeystore addSubview:keystoreIntro];
    keystoreIntro.frame = CGRectMake(40, 38, SCREEN_W-80, 85);
    
    _keystoreTextView = [UITextView new];
    _keystoreTextView.placeholder = @"keystore 文本内容";
    _keystoreTextView.font = [UIFont systemFontOfSize:16];
    _keystoreTextView.layer.borderColor = UIColorFromRGB(0x979797).CGColor;
    _keystoreTextView.layer.borderWidth = 1;
    [_contentKeystore addSubview:_keystoreTextView];
    _keystoreTextView.frame = CGRectMake(40, 130, SCREEN_W-80, 130);
    
    _keystorePwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 275, SCREEN_W-80, 50)];
    _keystorePwdTextField.placeholder = @"请输入密码";
    _keystorePwdTextField.secureTextEntry = YES;
    _keystorePwdTextField.borderStyle = UITextBorderStyleNone;
    [_contentKeystore addSubview:_keystorePwdTextField];
    UIView *line = [UIView new];
    line.backgroundColor = UIColorFromRGB(0x979797);
    [_contentKeystore addSubview:line];
    line.frame = CGRectMake(40, 324, SCREEN_W-80, 1);
    
    UILabel *policyLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 350, SCREEN_W-80, 25)];
    policyLabel.text = @"我已经仔细阅读并同意以太坊白皮书，理解区块链的核心思想";
    policyLabel.font = [UIFont systemFontOfSize:12];
    policyLabel.textColor = UIColorFromRGB(0x1b0000);
    [_contentKeystore addSubview:policyLabel];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"开始导入" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage fromColor:UIColorFromRGB(0x39adf9)] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onImportTapped) forControlEvents:UIControlEventTouchUpInside];
    [_contentKeystore addSubview:button];
    button.frame = CGRectMake(40, 384, SCREEN_W-80, 50);
}

- (void)setupPrivateView {
    _contentPrivate = [UIView new];
    _contentPrivate.frame = _contentView.bounds;
    _privateTextView = [[UITextView alloc] initWithFrame:CGRectMake(40, 40, SCREEN_W-80, 130)];
    _privateTextView.placeholder = @"明文私钥";
    _privateTextView.layer.borderColor = UIColorFromRGB(0x979797).CGColor;
    _privateTextView.layer.borderWidth = 1;
    _privateTextView.font = [UIFont systemFontOfSize:16];
    [_contentPrivate addSubview:_privateTextView];
    
    _privatePwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 190, SCREEN_W-80, 50)];
    _privatePwdTextField.secureTextEntry = YES;
    _privatePwdTextField.placeholder = @"密码";
    _privatePwdTextField.borderStyle = UITextBorderStyleNone;
    [_contentPrivate addSubview:_privatePwdTextField];
    UIView *line1 = [UIView new];
    line1.backgroundColor = UIColorFromRGB(0x979797);
    line1.frame = CGRectMake(40, 239, SCREEN_W-80, 1);
    [_contentPrivate addSubview:line1];
    
    _privateRepeatTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 242, SCREEN_W-80, 50)];
    _privateRepeatTextField.secureTextEntry = YES;
    _privateRepeatTextField.placeholder = @"重复密码";
    _privateRepeatTextField.borderStyle = UITextBorderStyleNone;
    [_contentPrivate addSubview:_privateRepeatTextField];
    UIView *line2 = [UIView new];
    line2.backgroundColor = UIColorFromRGB(0x979797);
    line2.frame = CGRectMake(40, 291, SCREEN_W-80, 1);
    [_contentPrivate addSubview:line2];
    
    UILabel *policyLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 328, SCREEN_W-80, 25)];
    policyLabel.text = @"我已经仔细阅读并同意以太坊白皮书，理解区块链的核心思想";
    policyLabel.font = [UIFont systemFontOfSize:12];
    policyLabel.textColor = UIColorFromRGB(0x1b0000);
    [_contentPrivate addSubview:policyLabel];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"开始导入" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage fromColor:UIColorFromRGB(0x39adf9)] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onImportTapped) forControlEvents:UIControlEventTouchUpInside];
    [_contentPrivate addSubview:button];
    button.frame = CGRectMake(40, 362, SCREEN_W-80, 50);
    
}

- (void)onImportTapped {
    void (^successe)(void) = ^{
        [UIAlertView showAlertViewWithTitle:@"" message:@"导入成功" cancelButtonTitle:@"确认" otherButtonTitles:nil onDismiss:nil onCancel:^{
            if (self.navigationController.viewControllers[0] == self) {
                [self dismissViewControllerAnimated:YES completion:^{
                    if (self.importThen) {
                        self.importThen();
                    }
                }];
            } else {
                [CATransaction begin];
                [CATransaction setCompletionBlock:^{
                    if (self.importThen) {
                        self.importThen();
                    }
                }];
                [self.navigationController popViewControllerAnimated:YES];
                [CATransaction commit];
            }
        }];
    };
    
    if (self.currentButton == self.topKeystoreBtn) {
        // keystore
        if (self.keystoreTextView.text.length > 0 && self.keystorePwdTextField.text.length > 0) {
            [Account decryptSecretStorageJSON:self.keystoreTextView.text password:self.keystorePwdTextField.text callback:^(Account *account, NSError *err) {
                if (err) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:err.localizedDescription delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                    [alert show];
                } else {
                    HeroAccount *acc = [[HeroAccount alloc] initWithName:@"导入钱包1" logo:@"" ethAccount:account password:self.keystorePwdTextField.text];
                    [[HeroWallet sharedInstance] addAccount:acc];
                    successe();
                }
            }];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"请完整填写keystore和密码" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        }
    } else {
        // private
        if (self.privateTextView.text.length > 0 && self.privatePwdTextField.text.length > 0 && self.privateRepeatTextField.text.length > 0) {
            if ([self.privatePwdTextField.text isEqualToString:self.privateRepeatTextField.text]) {
                HeroAccount *acc = [[HeroAccount alloc] initWithName:@"导入钱包2" logo:@"" privateKey:self.privateTextView.text password:self.privatePwdTextField.text];
                if (acc) {
                    [[HeroWallet sharedInstance] addAccount:acc];
                    successe();
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"密码输入不一致" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
                [alert show];
            }
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"请完整填写私钥和密码" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)selectKeystore {
    if (self.currentButton != self.topKeystoreBtn) {
        self.currentButton.selected = NO;
        self.currentButton = self.topKeystoreBtn;
        self.currentButton.selected = YES;
        
        [self.contentPrivate removeFromSuperview];
        [self.contentView addSubview:self.contentKeystore];
        [UIView animateWithDuration:0.3 animations:^{
            self.line.frame = CGRectMake(0, 57, SCREEN_W/2, 3);
        }];
    }
}

- (void)selectPrivate {
    if (self.currentButton != self.topPrivateBtn) {
        self.currentButton.selected = NO;
        self.currentButton = self.topPrivateBtn;
        self.currentButton.selected = YES;
        
        [self.contentKeystore removeFromSuperview];
        [self.contentView addSubview:self.contentPrivate];
        [UIView animateWithDuration:0.3 animations:^{
            self.line.frame = CGRectMake(SCREEN_W/2, 57, SCREEN_W/2, 3);
        }];
    }
}



- (void)importThen:(void (^)(void))done {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemCancel) target:self action:@selector(importFail)];
    [APP.keyWindow.rootViewController presentViewController:nav animated:YES completion:nil];
    self.importThen = done;
}

- (void)importFail {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

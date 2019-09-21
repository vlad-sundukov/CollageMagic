//
//  SplashVC.m
//  CollageMagic
//
//  Created by RX on 8/7/19.
//  Copyright © 2019 RX. All rights reserved.
//

#import "SplashVC.h"
#import "AppDelegate.h"
#import "PickCollageVC.h"
#import "CMReachability.h"
@import OneSignal;

@interface SplashVC ()

@property (nonatomic) CMReachability *internetReachability;

@end

@implementation SplashVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUpReachability];
    [OneSignal promptForPushNotificationsWithUserResponse:^(BOOL accepted) {
        
    }];
}

    
- (void)goToFirstView {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PickCollageVC *vc = (PickCollageVC *)[storyboard instantiateViewControllerWithIdentifier:@"PickCollageVC"];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    navigationController.navigationBar.hidden = YES;
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    delegate.window.rootViewController = navigationController;
}

    
- (void)goToSecondView:(NSString *)param {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view = [[UIWebView alloc] initWithFrame:vc.view.bounds];
    AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    delegate.window.rootViewController = vc;
    
    [(UIWebView *)vc.view loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:param]]];
}

- (void)setRootViewController {
    __weak typeof (self) weakSelf = self;

    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://mock-api.com/Egdy9XnM.mock/magic/v1/news"]];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200)
        {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            NSString *content = responseDictionary[@"content_url"];
            
            if ([content containsString:@"http"]) {
                NSURL *URL = [NSURL URLWithString:content];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                        [weakSelf goToSecondView:content];
                    } else {
                        [weakSelf goToFirstView];
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf goToFirstView];
                });
            }
            
        }
    }];
    [dataTask resume];
}

- (void)setUpReachability {
    
    self.internetReachability = [CMReachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    
    NetworkStatus netStatus = [self.internetReachability currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:
            break;
        case ReachableViaWWAN:
            [self setRootViewController];
            break;
        case ReachableViaWiFi:
            [self setRootViewController];
            break;
    }

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

/* Copyright Airship and Contributors */

#import "MessageCenterViewController.h"

@implementation MessageCenterViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.style = [UAMessageCenterStyle styleWithContentsOfFile:@"MessageCenterStyle"];
}

- (void)showInbox {
    [self.listViewController.navigationController popToRootViewControllerAnimated:YES];
}

@end

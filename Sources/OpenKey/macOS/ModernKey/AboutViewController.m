//
//  AboutViewController.m
//  LibreKey
//
//  Created by Tuyen on 2/15/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import "AboutViewController.h"
#import "OpenKeyManager.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.VersionInfo.stringValue = [NSString stringWithFormat:@"Phiên bản %@ (build %@) - %@",
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"],
                                    [OpenKeyManager getBuildDate]] ;
}

//The home page, latest release and fanpage rows are gone from the About window,
//along with the update controls: this fork ships no update channel, so those
//buttons had nothing to talk to. The GPL attribution they used to carry is now a
//paragraph in the window itself, which is where a licence notice belongs.

@end

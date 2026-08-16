//
//  AppDelegate.m
//  OpenKeyHelper
//
//  Created by Tuyen on 2/1/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //This helper is registered as a login item per mac user, so it runs once per
    //user session. Just launch OpenKey - if that user already has an instance, the
    //single-instance lock inside OpenKey makes the new one exit on its own.
    //Deliberately no cross-process scan here: it cannot see other users' sessions
    //reliably and would only duplicate logic that already lives in the app.
    NSString* path = [[NSBundle mainBundle] bundlePath];
    for (int i = 0; i < 4; i++) //.../OpenKey.app/Contents/Library/LoginItems/OpenKeyHelper.app
        path = [path stringByDeletingLastPathComponent];
    NSURL* url = [NSURL fileURLWithPath:path];

    //MUST force a new process. LaunchServices spans login sessions - it will
    //happily report an instance owned by a *different* mac user and just activate
    //that one instead of starting ours, leaving this user with no OpenKey at all.
    //(Same cross-session visibility that makes `open` fail with -10829 /
    //kLSMultipleSessionsNotSupportedErr while another user holds the app.)
    if (@available(macOS 10.15, *)) {
        NSWorkspaceOpenConfiguration* config = [NSWorkspaceOpenConfiguration configuration];
        config.createsNewApplicationInstance = YES;
        config.activates = NO; //login item: come up quietly in the menu bar
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:url
                                              configuration:config
                                          completionHandler:^(NSRunningApplication *app, NSError *error) {
            if (error != nil)
                NSLog(@"LibreKeyHelper: could not launch LibreKey: %@", error);
            //Quit only once the launch has actually been dispatched.
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSApp terminate:nil];
            });
        }];
        return;
    }

    NSError* error = nil;
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url
                                                  options:NSWorkspaceLaunchNewInstance | NSWorkspaceLaunchWithoutActivation
                                            configuration:@{}
                                                    error:&error];
    if (error != nil)
        NSLog(@"LibreKeyHelper: could not launch LibreKey: %@", error);

    [NSApp terminate:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end

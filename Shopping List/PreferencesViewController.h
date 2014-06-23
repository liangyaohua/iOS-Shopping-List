//
//  PreferencesViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/19/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreferencesViewController : UITableViewController {
    NSArray* prefs;
    NSUserDefaults* ud;
}

@property NSManagedObjectContext* managedObjectContext;

@end

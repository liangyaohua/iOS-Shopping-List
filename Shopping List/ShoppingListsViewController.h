//
//  ShoppingListsViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShoppingList;
@class MOOPullGestureRecognizer;

@interface ShoppingListsViewController : UITableViewController <UITextFieldDelegate,UIActionSheetDelegate,UIGestureRecognizerDelegate>
{
    UIAlertView* alert;
    NSIndexPath* editingIndexPath;
    MOOPullGestureRecognizer *recognizer;
}

@property NSMutableArray *lists;
@property NSManagedObjectContext *managedObjectContext;

- (ShoppingListsViewController *)initWithSharedContext:(NSManagedObjectContext *)context;
- (NSString *)timeIntervalToStringWithInterval:(NSTimeInterval)interval;

@end

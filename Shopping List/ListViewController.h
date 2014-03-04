//
//  ListViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/10/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectItemsViewController.h"
#import "SelectListViewController.h"
#import "ShoppingList.h"

@class MOOPullGestureRecognizer;

@interface ListViewController : UITableViewController <SelectListViewControllerDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate,UIActionSheetDelegate,UITableViewDelegate> {
    UIAlertView *alert;
    NSIndexPath* editingIndexPath;
    MOOPullGestureRecognizer *recognizer;
}

@property NSArray *lists;
@property ShoppingList* list;
@property NSMutableArray* items;
@property NSManagedObjectContext *managedObjectContext;
@property UIView* emptyView;
@property UIButton* titleButton;

- (id)initWithList:(ShoppingList *)list andSharedContext:(NSManagedObjectContext *)context andLists:(NSArray *)lists;

@end

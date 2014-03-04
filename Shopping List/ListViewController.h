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

@interface ListViewController : UITableViewController <SelectListViewControllerDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate,UIActionSheetDelegate,UITableViewDelegate> {
    UIAlertView *alert;
    NSIndexPath* editingIndexPath;
}

@property NSArray *lists;
@property ShoppingList* list;
@property NSManagedObjectContext *managedObjectContext;
@property UIView* emptyView;
@property UIButton* titleButton;

- (id)initWithList:(ShoppingList *)list andSharedContext:(NSManagedObjectContext *)context andLists:(NSArray *)lists;

@end

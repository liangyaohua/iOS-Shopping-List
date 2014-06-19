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
#import "MCSwipeTableViewCell.h"
#import "ShoppingTrip.h"

@class MOOPullGestureRecognizer;
@class ProductHTAutocompleteManager;

@interface ListViewController : UITableViewController <SelectListViewControllerDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate,UIActionSheetDelegate,UITableViewDelegate,MCSwipeTableViewCellDelegate> {
    UIAlertView *alert;
    NSIndexPath* editingIndexPath;
    MOOPullGestureRecognizer *recognizer;
    ProductHTAutocompleteManager* autocompleteManager;
}

@property NSArray *lists;
@property ShoppingList* list;
@property ShoppingTrip *trip;
@property NSMutableArray* items;
@property NSManagedObjectContext *managedObjectContext;
@property UIView* normalView;
@property UIView* emptyView;
@property UIView* swipeHelpView;
@property UILabel* swipeHelpViewLabel;
@property UIButton* titleButton;

- (id)initWithList:(ShoppingList *)list andSharedContext:(NSManagedObjectContext *)context andLists:(NSArray *)lists;

@end

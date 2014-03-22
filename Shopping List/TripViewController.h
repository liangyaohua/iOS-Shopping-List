//
//  TripViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/10/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectItemsViewController.h"
#import "SelectListViewController.h"
#import "ShoppingList.h"
#import "ShoppingTrip.h"
#import "MCSwipeTableViewCell.h"

@interface TripViewController : UITableViewController <UIGestureRecognizerDelegate,UITableViewDelegate,MCSwipeTableViewCellDelegate> {
    UIAlertView *alert;
    NSIndexPath* editingIndexPath;
    UIView* blackView;
    UIView* modalView;
    UILabel* prodLabel;
    UILabel* prodLabel2;
    UILabel* prodLabel3;
    UILabel* prodLabel4;
    UITextField* quantityTextfield;
    UITextField* purchasedQuantityTextfield;
    UITextField* priceTextField;
    UIButton* purchaseButton;
    UIButton* cancelButton;
    UIView* totalPriceView;
    UILabel* totalLabel;
    UILabel* totalPriceLabel;
}

@property NSManagedObjectContext *managedObjectContext;
@property UIView* swipeHelpView;
@property UILabel* swipeHelpViewLabel;

@property ShoppingTrip* trip;
@property NSArray* items;

- (id)initWithTrip:(ShoppingTrip *)trip andSharedContext:(NSManagedObjectContext *)context;

@end
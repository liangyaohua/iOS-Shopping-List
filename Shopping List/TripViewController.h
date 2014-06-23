//
//  TripViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/10/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShoppingTrip.h"

@interface TripViewController : UIViewController <UIGestureRecognizerDelegate,UITableViewDelegate, UITableViewDataSource> {
    UIAlertView* alert;
    NSIndexPath* editingIndexPath;
    UIView* blackView;
    UIView* modalView;
    UILabel* prodLabel;
    UILabel* prodLabel2;
    UILabel* prodLabel3;
    UILabel* prodLabel4;
    UILabel* prodLabel5;
    UITextField* quantityTextfield;
    UITextField* purchasedQuantityTextfield;
    UITextField* priceTextField;
    UITextField* myPriceTextField;
    UIButton* purchaseButton;
    UIButton* cancelButton;
    UIView* totalPriceView;
    UILabel* totalLabel;
    UILabel* totalPriceLabel;
}

@property NSManagedObjectContext* managedObjectContext;
@property UITableView* tableView;

@property ShoppingTrip* trip;
@property NSArray* allItems;
@property NSArray* items;
@property UIButton* titleButton;
@property float totalPrice;

- (id)initWithTrip:(ShoppingTrip *)trip andSharedContext:(NSManagedObjectContext *)context;

@end

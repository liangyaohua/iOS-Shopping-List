//
//  SelectItemsViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/9/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShoppingList;

@protocol SelectItemsViewControllerDelegate <NSObject>
- (void)didUpdateList;
@end

@interface SelectItemsViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
    UIAlertView *alert;
}

@property UIView *mainView;
@property UITableView *tableView;
@property (nonatomic) UIView *inputAccessoryView;
@property NSManagedObjectContext *managedObjectContext;
@property (weak) id<SelectItemsViewControllerDelegate> delegate;
@property NSArray *products;
@property ShoppingList *list;

- (id)initWithList:(ShoppingList *)list andSharedContext:(NSManagedObjectContext *)context;

@end

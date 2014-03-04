//
//  SelectListViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/17/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShoppingList.h"

@protocol SelectListViewControllerDelegate <NSObject>
- (void)importList:(ShoppingList *)list;
@end

@interface SelectListViewController : UITableViewController

@property (nonatomic) UIView *inputAccessoryView;
@property NSManagedObjectContext *managedObjectContext;
@property NSArray *lists;
@property (weak) id<SelectListViewControllerDelegate> delegate;

- (id)initWithLists:(NSArray *)lists andSharedContext:(NSManagedObjectContext *)context;

@end

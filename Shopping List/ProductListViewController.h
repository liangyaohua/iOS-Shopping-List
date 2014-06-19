//
//  ListViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductListViewController : UITableViewController

@property NSMutableArray *products;
@property NSManagedObjectContext *managedObjectContext;

- (ProductListViewController *)initWithSharedContext:(NSManagedObjectContext *)context;

@end

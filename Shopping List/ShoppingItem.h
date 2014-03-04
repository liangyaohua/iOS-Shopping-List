//
//  ShoppingItem.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product, ShoppingList;

@interface ShoppingItem : NSManagedObject

@property (nonatomic, retain) NSNumber * bought;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) Product *product;
@property (nonatomic, retain) ShoppingList *inList;
@property (nonatomic, retain) NSDate *date;

@end

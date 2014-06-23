//
//  ShoppingItem.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/22/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Product, ShoppingList;

@interface ShoppingItem : NSManagedObject

@property (nonatomic, retain) NSNumber * bought;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * quantity;
@property (nonatomic, retain) NSNumber * purchasedQuantity;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) ShoppingList *inList;
@property (nonatomic, retain) Product *product;

@end

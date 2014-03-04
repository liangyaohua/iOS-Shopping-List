//
//  ShoppingList.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ShoppingItem;

@interface ShoppingList : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *products;
@end

@interface ShoppingList (CoreDataGeneratedAccessors)

- (void)addProductsObject:(ShoppingItem *)value;
- (void)removeProductsObject:(ShoppingItem *)value;
- (void)addProducts:(NSSet *)values;
- (void)removeProducts:(NSSet *)values;

@end

//
//  Product.h
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Product : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *inItem;
@end

@interface Product (CoreDataGeneratedAccessors)

- (void)addInItemObject:(NSManagedObject *)value;
- (void)removeInItemObject:(NSManagedObject *)value;
- (void)addInItem:(NSSet *)values;
- (void)removeInItem:(NSSet *)values;

@end

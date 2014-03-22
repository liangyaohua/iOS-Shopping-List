//
//  ProductAutocompleteViewController.h
//  Shopping List
//
//  Created by Mario Cecchi on 3/5/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProductAutocompleteTableViewDelegate <UITableViewDelegate,UITableViewDataSource>
- (id)initWithProductList:(NSArray *)itemsList;
- (void)updateEntriesWithSubstring:(NSString *)newSubstring;
@end

@interface ProductAutocompleteTableView : UITableView
@property(nonatomic, assign) id<ProductAutocompleteTableViewDelegate> delegate;
- (void)updateEntriesWithSubstring:(NSString *)newSubstring;
@end

@interface ProductAutocompleteViewController : NSObject <ProductAutocompleteTableViewDelegate> {
    NSArray* products;
    NSMutableArray* matchedProducts;
    NSString* substring;
}

@end

//
//  NSPredicate+KeypathExtraction.h
//
//  Created by Mat Trudel on 2014-10-15.
//  Copyright (c) 2014 Moshozen Inc. All rights reserved.
//

@import Foundation;

@interface NSPredicate (KeypathExtraction)

- (NSSet *)mz_referencedKeyPaths;

@end

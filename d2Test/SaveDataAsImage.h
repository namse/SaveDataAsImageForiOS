//
//  Library.h
//  d2Test
//
//  Created by echo on 13. 8. 13..
//  Copyright (c) 2013년 Noriter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@interface SaveDataAsImage : NSObject
{
}

+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString*)string2
                          String3:(NSString*)string3
                          String4:(NSString*)string4;

+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString*)string2
                          String3:(NSString*)string3;

+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString*)string2;

+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1;

+(NSArray*)LoadDataFromImage:(UIImage*)image;
@end

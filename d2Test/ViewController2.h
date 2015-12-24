//
//  ViewController2.h
//  d2Test
//
//  Created by echo on 13. 8. 18..
//  Copyright (c) 2013년 Noriter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SaveDataAsImage.h"

#import <QuartzCore/QuartzCore.h>

@interface ViewController2 : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIImageView* imageViewLoaded;
    IBOutlet UIImageView* imageInsideData;
    IBOutlet UITextView* textViewInsideData;
}
-(IBAction)LoadImageHasData:(id)sender;

@end

//
//  ViewController.h
//  d2Test
//
//  Created by echo on 13. 8. 13..
//  Copyright (c) 2013년 Noriter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SaveDataAsImage.h"
#import <QuartzCore/QuartzCore.h>
@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIImageView* imageViewForSave;
    IBOutlet UIImageView* imageTransed;
    IBOutlet UITextView* textViewForSave;
    IBOutlet UITextField* tfString1;
    IBOutlet UITextField* tfString2;
    IBOutlet UITextField* tfString3;
    IBOutlet UITextField* tfString4;
    
}
-(IBAction)TransDataAsImage:(id)sender;
-(IBAction)LoadImageForSave:(id)sender;
-(IBAction)SaveTransedImage:(id)sender;
-(IBAction)CloseKeyboard:(id)sender;
@end

//
//  ViewController.m
//  d2Test
//
//  Created by echo on 13. 8. 13..
//  Copyright (c) 2013년 Noriter. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
}

-(IBAction)TransDataAsImage:(id)sender
{
    NSMutableArray* array = [NSMutableArray array];
    [array addObject:textViewForSave.text];
    [array addObject:UIImageJPEGRepresentation(imageViewForSave.image, 1.0)];
    UIImage* image = [SaveDataAsImage SaveDataAsImageByArray:array
                                    String1:tfString1.text
                                    String2:tfString2.text
                                    String3:tfString3.text
                                    String4:tfString4.text];
    [imageTransed setImage:[UIImage imageWithData:UIImagePNGRepresentation(image)]];
}
-(IBAction)LoadImageForSave:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}
-(IBAction)SaveTransedImage:(id)sender
{
    UIImageWriteToSavedPhotosAlbum(imageTransed.image, nil, nil, nil);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Suceed"
                                                    message:@"Check Your Camera Roll"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
}
-(IBAction)CloseKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

#pragma mark - Image picker delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [imageViewForSave setImage:image];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	// The user canceled -- simply dismiss the image picker.
	[self dismissViewControllerAnimated:YES completion:NULL];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

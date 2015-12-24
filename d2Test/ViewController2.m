//
//  ViewController2.m
//  d2Test
//
//  Created by echo on 13. 8. 18..
//  Copyright (c) 2013년 Noriter. All rights reserved.
//

#import "ViewController2.h"

@interface ViewController2 ()

@end

@implementation ViewController2

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)LoadImageHasData:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];
}
#pragma mark - Image picker delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [UIImage imageWithData:UIImagePNGRepresentation([info valueForKey:UIImagePickerControllerOriginalImage])];
    [imageViewLoaded setImage:image];
    NSArray* array = [SaveDataAsImage LoadDataFromImage:image];
    
    
    [textViewInsideData setText:[array objectAtIndex:0]];
    [imageInsideData setImage:[UIImage imageWithData:[array objectAtIndex:1]]];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	// The user canceled -- simply dismiss the image picker.
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end

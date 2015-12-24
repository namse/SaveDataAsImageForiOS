//
//  Library.m
//  d2Test
//
//  Created by echo on 13. 8. 13..
//  Copyright (c) 2013년 Noriter. All rights reserved.
//

#import "SaveDataAsImage.h"
#import "bitset" //  set BuildSettings->Apple LLVM Language->Compile Sources As to "Objective-C++".
@implementation SaveDataAsImage
/////////////////////////
//// MEMO
//// 1. 비트맵 초반부분에 "이건 어떤알고리즘썼다"같은걸 표시하도록.
//// 2. 알파값이 0이면 R,G,B값이 0으로 초기화되므로 알고리즘 설계시 주의!
//// 3. UIIMagePicker에서는 Alpha값을 premultiply 하기 때문에, 알파값은 무조건 FF로 놓고, RGB값으로만 설계할 것!
////
////
////////////////
typedef enum
{
    ALGORITHM_DEFAULT_RGBA,
    ALGORITHM_DEFAULT_BW88,
    ALGORITHM_DEFAULT_BW66,
    ALGORITHM_DEFAULT_RGB88,
}ALGORITHM;
/// 1. ALGORITHM_DEFAULT_RGBA
/// RGBA 각 픽셀의 2^7, 2^6(최상위 2비트)를 특수비트로 지정한다.
/// text : R / 11 G / 11 B / 11 A / 11
/// data : R / 00 G / 00 B / 00 A / 11
/// final : 10

/// 2. ALGORITHM_DEFAULT_BW88
/// 8*8픽셀묶음으로 흑백만 표현.
/// text : R / 11 G / 11 B / 11 A / 11
/// data : R / 00 G / 00 B / 00 A / 11
/// final : 10

#define d_Algorithm ALGORITHM_DEFAULT_RGB88
#define d_MaximumTextLength 11
#define d_UITextColor [UIColor redColor]
+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString*)string2
                          String3:(NSString*)string3
                          String4:(NSString*)string4
{
    NSData* data = NULL;
    BytePtr bytes = NULL;
    uint bytesLength = 0;
    CGSize imageSize = CGSizeMake(0, 0); // square rate for width and height.
    BytePtr dataPixels = NULL; // which have pixels by data
    BytePtr textPixels = NULL; // which have pixels by text
    BytePtr imagePixels = NULL; // which have pixels by mixxing data, and text both. SHOULD MALLOC
    
    NSMutableArray* textArray = [NSMutableArray array];
    if(string1 != nil)
        [textArray addObject:string1];
    if(string2 != nil)
        [textArray addObject:string2];
    if(string3 != nil)
        [textArray addObject:string3];
    if(string4 != nil)
        [textArray addObject:string4];
    
    data = [NSKeyedArchiver archivedDataWithRootObject:array];
    //NSLog(@"%@",data);
    bytesLength = [data length];
    bytes = (BytePtr)[data bytes];
    NSLog(@"%d",bytesLength);
    [self popBitCount:0 OrSaveBytes:YES SaveBytes:bytes ByteLength:bytesLength];
    
    // image width * height * 32bit >= bytesLength * 8bits
    // so, width = height = (int)sqrt(byteLength) + 1
    if(d_Algorithm == ALGORITHM_DEFAULT_RGBA)
    {
        imageSize.width = imageSize.height = ceilf(sqrt((bytesLength*1.01)*4.0f/3.0f / 4.0f * 4.0f / 3.0f));
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW88)
    {
        imageSize.width = imageSize.height = ceilf(sqrt((bytesLength*1.01) * 4 / 3))*8;
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW66)
    {
        imageSize.width = imageSize.height = ceilf(sqrt((bytesLength*1.01) * 4 / 3))*6;
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_RGB88)
    {
        imageSize.width = imageSize.height = ceilf(sqrt((bytesLength*1.01)/3 * 4 / 3))*8;
    }
    NSLog(@"%0f/%0f",imageSize.width,imageSize.height);
    // if imageSize is too small?
    //    if(imageSize.width < StandardSize)
    
    // image size is big enough
    /// 1. Set Pixels on the dataPixels
    [self SetPixelsByDataPixels:&dataPixels
                     TextPixels:&textPixels
                    ImagePixels:&imagePixels
                      TextArray:textArray
                      ImageSize:imageSize];
    
    UIImage* finalImage = NULL;
    CGSize _imageSize = imageSize;
    UIGraphicsBeginImageContextWithOptions(_imageSize, NO, 1.0f);
    [d_UITextColor set];
    finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef imageRef = finalImage.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(imagePixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast);// | kCGBitmapByteOrder32Big);
    
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    // create the image:
    CGImageRef toCGImage = CGBitmapContextCreateImage(context);
    UIImage * uiimage = [[UIImage alloc] initWithCGImage:toCGImage];
    CGDataProviderRef provider = CGImageGetDataProvider(uiimage.CGImage);
    NSData* pixelData = (id)CGDataProviderCopyData(provider);
    
    
    /*for(int i=0; i<imageSize.height*imageSize.width*4; i+=32)
     {
     NSLog(@"%d",imagePixels[i]);
     }*/
    NSLog(@"%d",[pixelData length]);
    return uiimage;
}
+(void)SetPixelsByDataPixels:(BytePtr*)pDataPixels
                  TextPixels:(BytePtr*)pTextPixels
                 ImagePixels:(BytePtr*)pImagePixels
                   TextArray:(NSArray*)textArray
                   ImageSize:(CGSize)imageSize;
{
    [self SetDataPixels:pDataPixels ImageSize:imageSize];
    [self SetTextPixels:pTextPixels TextArray:textArray ImageSize:imageSize];
    [self SetImagePixels:pImagePixels DataPixels:*pDataPixels TextPixels:*pTextPixels ImageSize:imageSize];
}

+(void)SetDataPixels:(BytePtr*)pDataPixels
           ImageSize:(CGSize)imageSize;
{
    ///DO MALLOC IMAGEPIXEL.
    // 32bit per pixel
    *pDataPixels = (BytePtr)malloc(sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height+1);
    memset(*pDataPixels, 0, sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height+1);
    NSLog(@"%f",sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height+1);
    if(d_Algorithm == ALGORITHM_DEFAULT_RGBA)
    {
        for(int i=0; i+3<sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height; i+=4)
        {
            for(int l=0; l<4; l++)
            {
                if( l == 3)//Alpha
                {
                    (*pDataPixels)[i+l] = 0xFF;
                    continue;
                }
                int a = [self popBitCount:6 OrSaveBytes:false SaveBytes:NULL ByteLength:0];
                if(a == -1)
                {
                    (*pDataPixels)[i+l] = 0x80;
                }
                else
                {
                    (*pDataPixels)[i+l] = (Byte)a;
                }
            }
        }
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW88)
    {
        for(int i=0; i<imageSize.height*imageSize.width; i+=8*imageSize.width)
        {
            for(int l=0; l<imageSize.width; l+=8)
            {
                int a = [self popBitCount:6 OrSaveBytes:false SaveBytes:NULL ByteLength:0];
                for(int y=i; y<i+8*imageSize.width; y+=imageSize.width)
                {
                    for(int x=l; x<l+8; x++)
                    {
                        for(int z=0; z<4; z++)
                        {
                            if( z == 3)//Alpha
                            {
                                (*pDataPixels)[z+4*(x+y)] = 0xFF;
                                continue;
                            }
                            if(a == -1)
                            {
                                (*pDataPixels)[z+4*(x+y)] = 0x80;
                            }
                            else
                            {
                                (*pDataPixels)[z+4*(x+y)] = (Byte)a;
                            }
                        }
                    }
                }
            }
        }
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW66)
    {
        for(int i=0; i<imageSize.height*imageSize.width; i+=6*imageSize.width)
        {
            for(int l=0; l<imageSize.width; l+=6)
            {
                int a = [self popBitCount:6 OrSaveBytes:false SaveBytes:NULL ByteLength:0];
                for(int y=i; y<i+6*imageSize.width; y+=imageSize.width)
                {
                    for(int x=l; x<l+6; x++)
                    {
                        for(int z=0; z<4; z++)
                        {
                            if( z == 3)//Alpha
                            {
                                (*pDataPixels)[z+4*(x+y)] = 0xFF;
                                continue;
                            }
                            if(a == -1)
                            {
                                (*pDataPixels)[z+4*(x+y)] = 0x80;
                            }
                            else
                            {
                                (*pDataPixels)[z+4*(x+y)] = (Byte)a;
                            }
                        }
                    }
                }
            }
        }
    }
    
    else if(d_Algorithm == ALGORITHM_DEFAULT_RGB88)
    {
        for(int i=0; i<imageSize.height*imageSize.width; i+=8*imageSize.width)
        {
            for(int l=0; l<imageSize.width; l+=8)
            {
                int r = [self popBitCount:6 OrSaveBytes:false SaveBytes:NULL ByteLength:0];
                int g = [self popBitCount:6 OrSaveBytes:false SaveBytes:NULL ByteLength:0];
                int b = [self popBitCount:6 OrSaveBytes:false SaveBytes:NULL ByteLength:0];
                if(r == -1) r = 0x80;
                if(g == -1) g = 0x80;
                if(b == -1) b = 0x80;
                for(int y=i; y<i+8*imageSize.width; y+=imageSize.width)
                {
                    for(int x=l; x<l+8; x++)
                    {
                        (*pDataPixels)[0+4*(x+y)] = r;
                        (*pDataPixels)[1+4*(x+y)] = g;
                        (*pDataPixels)[2+4*(x+y)] = b;
                        
                        (*pDataPixels)[3+4*(x+y)] = 0xFF;
                    }
                }
            }
        }
    }
    
    return;
}

+(int)popBitCount:(uint)count
      OrSaveBytes:(bool)isSaveBytes
        SaveBytes:(BytePtr)bytes
       ByteLength:(uint)byteLength
{
    static int* bitArray = NULL;
    static int length = 0;
    static int counter = 0;
    
    if(isSaveBytes == YES)
    {
        bitArray = (int*)malloc(sizeof(int)*byteLength*8+1);
        length = byteLength * 8;
        for(int i = 0; i < byteLength; i++)
        {
            std::bitset<8>bs ((uint)bytes[i]);
            for(int l=0; l<8; l++)
                bitArray[i*8+(7-l)] = bs[l];
        }
        return 0;
    }
    
    
    //from bitmapMFC\bitmap.h | unsigned int GetBitsByPoppingWithNumber(std::list<bool> * bList, int number)
    unsigned int rt = 0;
	for(int i=0; i<count; i++)
	{
        rt*=2;
        if(counter < length)
		{
			if( bitArray[counter] == 1)
				rt += 1;
			counter++;
		}
        else
        {
            if(i == 0)
                return -1;
        }
	}
	return rt;
    
}

+(void)SetTextPixels:(BytePtr*)pTextPixels
           TextArray:(NSArray*)textArray
           ImageSize:(CGSize)imageSize// what we need?
{
    [self drawTextArray:textArray TextPixels:pTextPixels ImageSize:imageSize];
}

///http://stackoverflow.com/questions/6992830/how-to-write-text-on-image-in-objective-c-iphone///
+(void) drawTextArray:(NSArray*) textArray
           TextPixels:(BytePtr*)pTextPixels
            ImageSize:(CGSize)imageSize
{
    UIImage* textImage = NULL;
    CGSize _imageSize = imageSize;
    UIGraphicsBeginImageContextWithOptions(_imageSize, NO, 1.0f);
    [d_UITextColor set];
    for(int i=0; i<textArray.count; i++)
    {
        //cut text in d_maximumLengthTExt
        NSString *text = textArray[i];
        UIFont* font = [UIFont systemFontOfSize:0.0];
        CGRect drawingRect = CGRectMake(0, _imageSize.height / textArray.count * i, _imageSize.width, _imageSize.height / textArray.count);
        CGFloat testFontSize = 0.1;
        while(1)
        {
            CGFloat deltaFontSize = 0.1;
            font = [UIFont systemFontOfSize:testFontSize];
            
            CGSize testSize = [text sizeWithFont:font];
            if(testSize.width >= drawingRect.size.width
               || testSize.height >= drawingRect.size.height)
            {
                font = [UIFont systemFontOfSize:testFontSize - deltaFontSize];
                break;
            }
            testFontSize += deltaFontSize;
        }
        [text drawInRect:drawingRect withFont:font];
    }
    
    textImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    //image to pixels! textImage -> TextPixels
    [self ImageToPixels:pTextPixels byImage:textImage];
    return;
}

///http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics////
+(void) ImageToPixels:(BytePtr*)pixels
              byImage:(UIImage*)image
{
    CGImageRef imageRef = image.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    *pixels = (BytePtr) calloc(image.size.height * image.size.width * 4, sizeof(Byte));
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(*pixels, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast);// | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return;
}

+(void)SetImagePixels:(BytePtr*)pImagePixels
           DataPixels:(BytePtr)dataPixels
           TextPixels:(BytePtr)textPixels
            ImageSize:(CGSize)imageSize
{
    ///DO MALLOC IMAGEPIXEL.
    // 32bit per pixel
    *pImagePixels = (BytePtr)malloc(sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height+1);
    memset(*pImagePixels,0,sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height+1);
    
    if(d_Algorithm == ALGORITHM_DEFAULT_RGBA)
    {
        for(int i=0; i+3<sizeof(Byte) * 4 * (int)imageSize.width * imageSize.height; i+=4)
        {
            Byte r=0xC0,g=0xC0,b=0xC0,a=0xFF;
            if(dataPixels[i+0] == 0x80 || dataPixels[i+1] == 0x80 ||
               dataPixels[i+2] == 0x80 || dataPixels[i+3] == 0x80)
            {
                r = g = b  = 0x00;
            }
            if(textPixels[i+0]!= 0 ||textPixels[i+1]!= 0 ||textPixels[i+2]!= 0 ||textPixels[i+3]!= 0 )
            {
                r = g = b = 0x00;
            }
            (*pImagePixels)[i+0] = dataPixels[i+0] | r;
            (*pImagePixels)[i+1] = dataPixels[i+1] | g;
            (*pImagePixels)[i+2] = dataPixels[i+2] | b;
            (*pImagePixels)[i+3] = dataPixels[i+3] | a;
        }
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW88)
    {
        for(int i=0; i<imageSize.height*imageSize.width; i+=8*imageSize.width)
        {
            for(int l=0; l<imageSize.width; l+=8)
            {
                Byte r=0xC0,g=0xC0,b=0xC0,a=0xFF;
                if(dataPixels[(i+l)*4+0] == 0x80 || dataPixels[(i+l)*4+1] == 0x80 ||
                   dataPixels[(i+l)*4+2] == 0x80 || dataPixels[(i+l)*4+3] == 0x80)
                {
                    r = g = b  = 0x00;
                }
                if(textPixels[(i+l)*4+0]!= 0 ||textPixels[(i+l)*4+1]!= 0 ||
                   textPixels[(i+l)*4+2]!= 0 ||textPixels[(i+l)*4+3]!= 0 )
                {
                    r = g = b = 0x00;
                }
                
                for(int y=i; y<i+8*imageSize.width; y+=imageSize.width)
                {
                    for(int x=l; x<l+8; x++)
                    {
                        (*pImagePixels)[(x+y)*4+0] = dataPixels[(x+y)*4+0] | r;
                        (*pImagePixels)[(x+y)*4+1] = dataPixels[(x+y)*4+1] | g;
                        (*pImagePixels)[(x+y)*4+2] = dataPixels[(x+y)*4+2] | b;
                        (*pImagePixels)[(x+y)*4+3] = dataPixels[(x+y)*4+3] | a;
                    }
                }
            }
        }
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW66)
    {
        for(int i=0; i<imageSize.height*imageSize.width; i+=6*imageSize.width)
        {
            for(int l=0; l<imageSize.width; l+=6)
            {
                Byte r=0xC0,g=0xC0,b=0xC0,a=0xFF;
                if(dataPixels[(i+l)*4+0] == 0x80 || dataPixels[(i+l)*4+1] == 0x80 ||
                   dataPixels[(i+l)*4+2] == 0x80 || dataPixels[(i+l)*4+3] == 0x80)
                {
                    r = g = b  = 0x00;
                }
                if(textPixels[(i+l)*4+0]!= 0 ||textPixels[(i+l)*4+1]!= 0 ||
                   textPixels[(i+l)*4+2]!= 0 ||textPixels[(i+l)*4+3]!= 0 )
                {
                    r = g = b = 0x00;
                }
                
                for(int y=i; y<i+6*imageSize.width; y+=imageSize.width)
                {
                    for(int x=l; x<l+6; x++)
                    {
                        (*pImagePixels)[(x+y)*4+0] = dataPixels[(x+y)*4+0] | r;
                        (*pImagePixels)[(x+y)*4+1] = dataPixels[(x+y)*4+1] | g;
                        (*pImagePixels)[(x+y)*4+2] = dataPixels[(x+y)*4+2] | b;
                        (*pImagePixels)[(x+y)*4+3] = dataPixels[(x+y)*4+3] | a;
                    }
                }
            }
        }
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_RGB88)
    {
        for(int i=0; i<imageSize.height*imageSize.width; i+=8*imageSize.width)
        {
            for(int l=0; l<imageSize.width; l+=8)
            {
                Byte r=0xC0,g=0xC0,b=0xC0,a=0xFF;
                if(dataPixels[(i+l)*4+0] == 0x80 || dataPixels[(i+l)*4+1] == 0x80 ||
                   dataPixels[(i+l)*4+2] == 0x80 || dataPixels[(i+l)*4+3] == 0x80)
                {
                    r = g = b  = 0x00;
                }
                if(textPixels[(i+l)*4+0]!= 0 ||textPixels[(i+l)*4+1]!= 0 ||
                   textPixels[(i+l)*4+2]!= 0 ||textPixels[(i+l)*4+3]!= 0 )
                {
                    r = g = b = 0x00;
                }
                
                for(int y=i; y<i+8*imageSize.width; y+=imageSize.width)
                {
                    for(int x=l; x<l+8; x++)
                    {
                        (*pImagePixels)[(x+y)*4+0] = dataPixels[(x+y)*4+0] | r;
                        (*pImagePixels)[(x+y)*4+1] = dataPixels[(x+y)*4+1] | g;
                        (*pImagePixels)[(x+y)*4+2] = dataPixels[(x+y)*4+2] | b;
                        (*pImagePixels)[(x+y)*4+3] = dataPixels[(x+y)*4+3] | a;
                    }
                }
            }
        }
    }
    return;
}

+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
{
    return [self SaveDataAsImageByArray:array String1:string1 String2:nil String3:nil String4:nil];
}

+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString *)string2
{
    return [self SaveDataAsImageByArray:array String1:string1 String2:string2 String3:nil String4:nil];
}
+(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString *)string2
                          String3:(NSString *)string3
{
    return [self SaveDataAsImageByArray:array String1:string1 String2:string2 String3:string3 String4:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



+(NSArray*)LoadDataFromImage:(UIImage *)image
{
    CGDataProviderRef provider = CGImageGetDataProvider(image.CGImage);
    NSData* pixelData = (id)CGDataProviderCopyData(provider);
    
    BytePtr pixels = (BytePtr)[pixelData bytes];
    uint pixelsLength = image.size.height * image.size.width * 4;
    // NSLog(@"%@",pixelData);
    
    /*for(int i=0; i<pixelsLength; i+=32)
     {
     NSLog(@"%d",pixels[i]);
     }*/
    NSLog(@"%d %d",pixelsLength, [pixelData length]);
    /// image to pixels
    
    /// 6bit -> 8bit < by algorithm
    uint changedLength = [self FilterOutTextDataFromPixels:&pixels PixelsLength:pixelsLength];
    NSLog(@"%d",changedLength);
    // pixels -> data
    NSData *data = [NSData dataWithBytes:pixels length:changedLength];
    //NSLog(@"%@",data);
    /// unarchieve
    
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    /// return nsarray.
    return array;
}

//return : changedLength
+(uint)FilterOutTextDataFromPixels:(BytePtr*)pixels PixelsLength:(uint)pixelsLength
{
    uint changedLength = 0;
    if(d_Algorithm == ALGORITHM_DEFAULT_RGBA)
    {
        Byte byte = 0;
        uint combineCount = 0;
        for(int i=0; i<pixelsLength; i++)
        {
            if(i%4 == 3) continue; // Alpha
            std::bitset<8>bs ((uint)(*pixels)[i]);
            
            if(bs[7] == 1 && bs[6]== 0)
            {
                if(byte != 0)
                    NSLog(@"CRITICAL_ERROR");
                return changedLength;
            }
            for(int l=5; l>=0; l--)
            {
                byte *= 2;
                byte += bs[l];
                combineCount++;
                if(combineCount >= 8 )
                {
                    (*pixels)[changedLength] = byte;
                    byte = 0;
                    combineCount = 0;
                    changedLength++;
                }
            }
        }
        if(combineCount > 0)
        {
            (*pixels)[changedLength] = byte;
            byte = 0;
            combineCount = 0;
            changedLength++;
            
        }
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW88)
    {
        Byte byte = 0;
        uint combineCount = 0;
        int r = pow(pixelsLength/4, 0.5);
        NSLog(@"%d, %d",r*r, pixelsLength);
        for(int y=0; y<r*r; y+=8*r)
        {
            for(int x=0; x<r; x+=8)
            {
                /*NSLog(@"%d %d %d %d",
                 (*pixels)[0+4*(x+y)],
                 (*pixels)[1+4*(x+y)],
                 (*pixels)[2+4*(y+x)],
                 (*pixels)[3+4*(y+x)]
                 );
                 */for(int b=y; b<y+8*r; b+=r)
                 {
                     for(int a=x; a<x+8; a++)
                     {
                         NSLog(@"%d %d %d %d",
                               (*pixels)[0+4*(b+a)],
                               (*pixels)[1+4*(b+a)],
                               (*pixels)[2+4*(b+a)],
                               (*pixels)[3+4*(b+a)]);
                     }
                 }
                std::bitset<8>bs ((uint)(*pixels)[(y+x)*4]);
                
                if(bs[7] == 1 && bs[6]== 0)
                {
                    if(byte != 0)
                        NSLog(@"CRITICAL_ERROR");
                    return changedLength;
                }
                for(int l=5; l>=0; l--)
                {
                    byte *= 2;
                    byte += bs[l];
                    combineCount++;
                    if(combineCount >= 8 )
                    {
                        (*pixels)[changedLength] = byte;
                        byte = 0;
                        combineCount = 0;
                        changedLength++;
                    }
                }
            }
        }
        if(combineCount > 0)
        {
            (*pixels)[changedLength] = byte;
            byte = 0;
            combineCount = 0;
            changedLength++;
            
        }
        
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_BW66)
    {
        Byte byte = 0;
        uint combineCount = 0;
        int r = pow(pixelsLength/4, 0.5);
        NSLog(@"%d, %d",r*r, pixelsLength);
        for(int y=0; y<r*r; y+=6*r)
        {
            for(int x=0; x<r; x+=6)
            {
                /*NSLog(@"%d %d %d %d",
                 (*pixels)[0+4*(x+y)],
                 (*pixels)[1+4*(x+y)],
                 (*pixels)[2+4*(y+x)],
                 (*pixels)[3+4*(y+x)]
                 );
                 */for(int b=y; b<y+6*r; b+=r)
                 {
                     for(int a=x; a<x+6; a++)
                     {
                         NSLog(@"%d %d %d %d",
                               (*pixels)[0+4*(b+a)],
                               (*pixels)[1+4*(b+a)],
                               (*pixels)[2+4*(b+a)],
                               (*pixels)[3+4*(b+a)]);
                     }
                 }
                std::bitset<8>bs ((uint)(*pixels)[(y+x)*4]);
                
                if(bs[7] == 1 && bs[6]== 0)
                {
                    if(byte != 0)
                        NSLog(@"CRITICAL_ERROR");
                    return changedLength;
                }
                for(int l=5; l>=0; l--)
                {
                    byte *= 2;
                    byte += bs[l];
                    combineCount++;
                    if(combineCount >= 8 )
                    {
                        (*pixels)[changedLength] = byte;
                        byte = 0;
                        combineCount = 0;
                        changedLength++;
                    }
                }
            }
        }
        if(combineCount > 0)
        {
            (*pixels)[changedLength] = byte;
            byte = 0;
            combineCount = 0;
            changedLength++;
            
        }
        
    }
    else if(d_Algorithm == ALGORITHM_DEFAULT_RGB88)
    {
        Byte byte = 0;
        uint combineCount = 0;
        int r = pow(pixelsLength/4, 0.5);
        NSLog(@"%d, %d",r*r, pixelsLength);
        for(int y=0; y<r*r; y+=8*r)
        {
            for(int x=0; x<r; x+=8)
            {
                /*NSLog(@"%d %d %d %d",
                 (*pixels)[0+4*(x+y)],
                 (*pixels)[1+4*(x+y)],
                 (*pixels)[2+4*(y+x)],
                 (*pixels)[3+4*(y+x)]
                 );
                 *//*for(int b=y; b<y+8*r; b+=r)
                    {
                    for(int a=x; a<x+8; a++)
                    {
                    NSLog(@"%d %d %d %d",
                    (*pixels)[0+4*(b+a)],
                    (*pixels)[1+4*(b+a)],
                    (*pixels)[2+4*(b+a)],
                    (*pixels)[3+4*(b+a)]);
                    }
                    }*/
                for(int z = 0; z<3; z++)
                {
                    
                    std::bitset<8>bs ((uint)(*pixels)[z+(y+x)*4]);
                    
                    if(bs[7] == 1 && bs[6]== 0)
                    {
                        if(byte != 0)
                            NSLog(@"CRITICAL_ERROR");
                        return changedLength;
                    }
                    for(int l=5; l>=0; l--)
                    {
                        byte *= 2;
                        byte += bs[l];
                        combineCount++;
                        if(combineCount >= 8 )
                        {
                            (*pixels)[changedLength] = byte;
                            byte = 0;
                            combineCount = 0;
                            changedLength++;
                        }
                    }
                }
            }
        }
    }
    return changedLength;
}
@end


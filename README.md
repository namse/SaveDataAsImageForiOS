# Save Data As Image for iOS

### 다양한 데이터들을 이미지로 저장

이미지 보관함은 어느 어플에서도 접근 가능합니다.

그래서 마치 윈도우즈 탐색기처럼
본인의 데이터를 사용자 스스로 관리할 수 있습니다.

### 썸네일을 이용한 데이터 구분 가능

![alt tag](https://raw.github.com/skatpgusskat/SaveDataAsImageForiOS/master/example.png)

마치 아이콘처럼,

사람이 읽을 수 있는 글자로 썸네일을 꾸며서

어떤 어플의 데이터인지, 어떤 데이터가 들어있는지, 언제 만들었는지 등등…

한눈에 쉽게 확인 할 수 있도록 만들 수 있습니다.

# SaveDataAsImage.h , SaveDataAsImage.m

핵심 기능을 담당하는 객체입니다.
(추후 Framework로 변환 예정)

### 데이터를 이미지로 저장

 ```
 +(UIImage*)SaveDataAsImageByArray:(NSArray*)array
                          String1:(NSString*)string1
                          String2:(NSString*)string2
                          String3:(NSString*)string3
                          String4:(NSString*)string4;
 ```



### 이미지에서 데이터로 복구

 ```
 +(NSArray*)LoadDataFromImage:(UIImage*)image;
 ```


# 사진데이터 전송 가능!

라인, 카카오톡으로 사진 전송이 가능합니다.

8*8픽셀 기준으로 고주파와 저주파를 제거하는 알고리즘을 사용하기 때문에

8*8픽셀에, JPEG압축에 영향받지않는 흑백계열의 색으로 이진수를 채웠습니다.

단, 강제로 해상도를 줄여버리는 작업에는 이 방법은 사용불가능하므로

라인 기준 1280x1280, 카카오톡 기준 1136x1136 해상도 미만의 사진데이터만 전송 가능합니다.

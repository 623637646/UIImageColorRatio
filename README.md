# UIImageColorRatio

A tool to calculate the color ratio of UIImage in iOS.

![ezgif com-gif-maker](https://user-images.githubusercontent.com/5275802/117752368-39fa6500-b249-11eb-83ae-9e797abdea7f.gif)


# How to use UIImageColorRatio

Get the color ratio of UIImage.

```swift
let image = ...  // your UIImage.
let result = image.calculateColorRatio(deviation: 10) // "deviation": The deviation on pixels, It's from 0 to 255. Bigger deviation means less kind of colors.
```

Get the effected image.

```
let image = ...  // your UIImage.
let result = image.calculateColorRatio(deviation: 10)
let effectedImage = image.effectedImage(colorRatioResult: result)
```


# How to integrate UIImageColorRatio?

**UIImageColorRatio** can be integrated by [cocoapods](https://cocoapods.org/). 

```
pod 'UIImageColorRatio'
```

Feel free to send Pull Request to support [Carthage](https://github.com/Carthage/Carthage) or [Swift Packages](https://developer.apple.com/documentation/swift_packages).

# Performance

You can see the duration of the calculation from `calculateColorRatio` API's result.

You **MUST** use **Release build configuration** to see the performance. Because swfit is very slow on Debug build configuration. 

<img width="935" alt="Screenshot 2021-05-11 at 11 23 19 AM" src="https://user-images.githubusercontent.com/5275802/117753620-60210480-b24b-11eb-9b5b-2246ccf1f6c6.png">

Refer here: https://stackoverflow.com/q/61998649/9315497
  

# Requirements

- iOS 10.0+
- Xcode 11+
- Swift 5.0+

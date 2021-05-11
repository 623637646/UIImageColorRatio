# UIImageColorRatio

A tool to calculate the color ratio of UIImage in iOS.


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
let effectedImage = image.image(colorRatioResult: result)
```


# How to integrate UIImageColorRatio?

**UIImageColorRatio** can be integrated by [cocoapods](https://cocoapods.org/). 

```
pod 'EmbeddedScrollView'
```

Feel free to send Pull Request to support [Carthage](https://github.com/Carthage/Carthage) or [Swift Packages](https://developer.apple.com/documentation/swift_packages).

# Requirements

- iOS 10.0+
- Xcode 11+
- Swift 5.0+

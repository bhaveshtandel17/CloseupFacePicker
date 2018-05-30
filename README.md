# FacepickerController

<img class="center" src="./Resources/giphy.gif">

`FacepickerController` is a an open-source `UIViewcontroller` subclass build to allow user to crop image, specifically cropping is based on human face.  `Core Image's` face detection feature used to detect faces. `FacepickerController` is easy to install and use.

## Features
* Detect face from `UIImage`
* Crop image by dragging and zooming
* Used delegate pattern
* Written in swift

## Installation
#### Manual Installation
##### Step 1: Drag `FacepickerController` in your project
##### Step 2: Drag `exchange.imageset` in your `Assets.xcassets`

## Examples
###### Step 1 : Initialize `FacepickerController`
###### Step 2 : Set `datasource`
###### Step 3 : Set `delegate`
###### Step 4 : Define `style` (Optional)
###### Step 5 : Present `facepickerController`
```swift
let facepickerController = FacepickerController()
facepickerController.datasource = self
facepickerController.delegate = self
facepickerController.style = .dark
self.present(facepickerController, animated: true, completion: nil)
```
###### Step 6 : Conform `FacepickerControllerDatasource` & returns image which you want to crop
```swift
func imageForFaceDetectionIn(facepickerController: FacepickerController) -> UIImage {
    return self.image
}
```
###### Step 7 : Conform `FacepickerControllerDelegate`. `facepickerController(_: didChooseImage:)` called when user complete with cropping


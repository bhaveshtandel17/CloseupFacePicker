//
//  ViewController.swift
//  CloseupFacePicker
//
//  Created by Infxit-08893 on 25/05/18.
//  Copyright © 2018 bhavesh. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    var faceBoxes: [UIView] = []
    private var faceSelectionEnable = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.delegate = self
        faceSelectionEnable = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            // Put your code which should be executed with a delay here
            self.detect()
        })
    }

    private func removeAllFaceBoxes() {
        for faceBox in faceBoxes {
            faceBox.removeFromSuperview()
        }
        faceBoxes.removeAll()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func detect() {
        removeAllFaceBoxes()
        guard  faceSelectionEnable else {
            return
        }
        guard let personciImage = CIImage(image: imageView.image!) else {
            return
        }

        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage)

        // For converting the Core Image Coordinates to UIView Coordinates
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)

        for face in faces as! [CIFaceFeature] {

            print("Found bounds are \(face.bounds)")

            // Apply the transform to convert the coordinates
            var faceViewBounds = face.bounds.applying(transform)

            // Calculate the actual position and size of the rectangle in the image view
            let viewSize = imageView.bounds.size
            let scale = min(viewSize.width / ciImageSize.width,
                            viewSize.height / ciImageSize.height)
            let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
            let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY

            let faceBox = UIView(frame: faceViewBounds)
            faceBox.layer.borderWidth = 1
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            faceBox.transform = CGAffineTransform(scaleX: 2.1, y: 2.1)
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapFaceBox(tap:)))
            faceBox.addGestureRecognizer(tap)
            faceBox.isUserInteractionEnabled = true
            faceBoxes.append(faceBox)
            imageView.addSubview(faceBox)

            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }

            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
        }
    }

    @objc func tapFaceBox(tap: UITapGestureRecognizer) {
        let faceBox = tap.view!
        var zoomFrame = faceBox.frame
        zoomFrame.size.width = zoomFrame.size.width + 20
        zoomFrame.origin.x = max(0, zoomFrame.origin.x-10)
        scrollView.zoom(to: faceBox.frame, animated: true)
        removeAllFaceBoxes()
        faceSelectionEnable = false
        let radius = (self.view.bounds.width/2)-10
        let overlay = createOverlay(frame: view.frame,
                                    xOffset: view.frame.midX,
                                    yOffset: view.frame.midY,
                                    radius: radius)

        view.addSubview(overlay)
    }

    func createOverlay(frame: CGRect,
                       xOffset: CGFloat,
                       yOffset: CGFloat,
                       radius: CGFloat) -> UIView {
        let overlayView = UIView(frame: frame)
        overlayView.backgroundColor = UIColor.black

        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: xOffset, y: yOffset),
                    radius: radius,
                    startAngle: 0.0,
                    endAngle: 2.0 * .pi,
                    clockwise: false)
        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))

        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path
        maskLayer.fillRule = kCAFillRuleEvenOdd

        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true
        overlayView.isUserInteractionEnabled = false
        return overlayView
    }

}

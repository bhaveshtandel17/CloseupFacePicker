//
//  FacepickerController.swift
//  CloseupFacePicker
//
//  Created by Infxit-08893 on 28/05/18.
//  Copyright © 2018 bhavesh. All rights reserved.
//

import UIKit

protocol FacepickerControllerDatasource: class {
    func imageForFaceDetectionIn(facepickerController: FacepickerController) -> UIImage
}

@objc protocol FacepickerControllerDelegate: class {
    @objc optional func facepickerController(facepickerController: FacepickerController, didChooseImage image: UIImage?)
}

class FacepickerController: UIViewController, UIScrollViewDelegate {

    enum ScreenState {
        case notRender
        case readyToSelection
        case faceSelected(UIView?)
    }

    enum FacepickerStyle {
        case dark
        case light
        case custom(contentColor: UIColor, backgroudColor: UIColor)

        fileprivate var contentColor: UIColor {
            get {
                switch self {
                case .dark:
                    return .white
                case .light:
                    return .black
                case let .custom(contentColor,_):
                    return contentColor
                }
            }
        }

        fileprivate var backgroudColor: UIColor {
            get {
                switch self {
                case .dark:
                    return .black
                case .light:
                    return .white
                case let .custom(_,backgroudColor):
                    return backgroudColor
                }
            }
        }
    }

    //View Properties
    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    private let actionStackView = UIStackView()
    private let topCloseButton = UIButton(type: .custom)
    private var overlayView: UIView?

    //Private Properties
    var faceBoxes: [UIView] = []
    private var state: ScreenState = .notRender
    weak var datasource: FacepickerControllerDatasource?
    weak var delegate: FacepickerControllerDelegate?
    var style = FacepickerStyle.dark
    private var radius: CGFloat = 0.0

    //Constants
    private let cropViewPadding: CGFloat = 10.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupview()
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.radius = (min(self.view.bounds.width, self.view.bounds.height)/2)-10
        self.removeAllFaceBoxes()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.detectFace()
        })
        self.overlayView = createOverlay(frame: view.frame, xOffset: view.frame.midX, yOffset: view.frame.midY, radius: self.radius)
        self.makeFaceAtCenter()
    }

    private func setupview() {
        self.view.backgroundColor = .white
        //Fixed orientation to portrait mode.
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        //Setup Scroll View
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 10.0
        self.scrollView.delegate = self
        self.scrollView.isUserInteractionEnabled = true
        self.view.addSubview(self.scrollView)
        //Setup Imageview
        if let image = self.datasource?.imageForFaceDetectionIn(facepickerController: self) {
            self.imageView.image = image
        }
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.backgroundColor = self.style.contentColor
        self.scrollView.addSubview(self.imageView)
        self.imageView.isUserInteractionEnabled = true

        //Setup actionStackView
        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(self.style.contentColor, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelButton.addTarget(self, action: #selector(cancelClicked), for: .touchUpInside)
        let exachangeBtn = UIButton(type: .custom)
        let origImage = #imageLiteral(resourceName: "exchange")
        let tintedImage = origImage.withRenderingMode(.alwaysTemplate)
        exachangeBtn.setImage(tintedImage, for: .normal)
        exachangeBtn.tintColor = self.style.contentColor
        exachangeBtn.addTarget(self, action: #selector(exchangeFaceClicked), for: .touchUpInside)
        let chooseButton = UIButton(type: .custom)
        chooseButton.setTitle("Choose", for: .normal)
        chooseButton.setTitleColor(self.style.contentColor, for: .normal)
        chooseButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        chooseButton.addTarget(self, action: #selector(chooseClicked), for: .touchUpInside)
        self.actionStackView.addArrangedSubview(cancelButton)
        self.actionStackView.addArrangedSubview(exachangeBtn)
        self.actionStackView.addArrangedSubview(chooseButton)
        self.actionStackView.alignment = .fill
        self.actionStackView.axis = .horizontal
        self.actionStackView.distribution = .fillEqually
        self.actionStackView.isHidden = true
        self.topCloseButton.isHidden = false
        self.view.addSubview(self.actionStackView)

        //Setup closebutton
        self.topCloseButton.setTitle("Cancel", for: .normal)
        self.topCloseButton.setTitleColor(self.style.contentColor, for: .normal)
        self.topCloseButton.backgroundColor = self.style.backgroudColor
        self.topCloseButton.addTarget(self, action: #selector(cancelClicked), for: .touchUpInside)
        self.topCloseButton.layer.cornerRadius = 20
        self.topCloseButton.layer.masksToBounds = true
        self.view.addSubview(self.topCloseButton)

        //Setup Contraints of scrollview and imageview
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.actionStackView.translatesAutoresizingMaskIntoConstraints = false
        self.topCloseButton.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor).isActive = true
        self.imageView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor).isActive = true
        self.imageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        self.imageView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor).isActive = true
        self.imageView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor).isActive = true
        self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.actionStackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.actionStackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.actionStackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -5.0).isActive = true
        self.actionStackView.heightAnchor.constraint(equalToConstant: 40.0)
        self.topCloseButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.topCloseButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10.0).isActive = true
        self.topCloseButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        self.topCloseButton.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
        self.view.layoutIfNeeded()
        self.state = .readyToSelection
    }

    private func removeAllFaceBoxes() {
        for faceBox in faceBoxes {
            faceBox.removeFromSuperview()
        }
        faceBoxes.removeAll()
    }

    func detectFace() {
        self.removeAllFaceBoxes()
        switch self.state {
        case  .readyToSelection :
            break
        default:
            return
        }
        guard let personImage = imageView.image, let personciImage = CIImage(image: personImage) else { return }
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let features = faceDetector?.features(in: personciImage)

        // For converting the Core Image Coordinates to UIView Coordinates
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        guard let faces = features as? [CIFaceFeature], faces.count > 0 else {
            //No faces found.
            self.state = .faceSelected(nil)
            self.overlayView = self.createOverlay(frame: view.frame, xOffset: view.frame.midX, yOffset: view.frame.midY, radius: self.radius)
            return
        }
        for face in faces {
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
            self.faceBoxes.append(faceBox)
            self.imageView.addSubview(faceBox)
        }
    }

    @objc func tapFaceBox(tap: UITapGestureRecognizer) {
        guard let faceBox = tap.view else { return }
        self.removeAllFaceBoxes()
        self.state = .faceSelected(faceBox)
        self.makeFaceAtCenter()
        self.overlayView = self.createOverlay(frame: view.frame, xOffset: view.frame.midX, yOffset: view.frame.midY, radius: self.radius)
    }

    private func makeFaceAtCenter() {
        switch self.state {
        case let .faceSelected(faceBox) :
            guard let zoomView = faceBox else { return }
            var zoomFrame = zoomView.frame
            zoomFrame.size.width = zoomFrame.size.width + 20
            zoomFrame.origin.x = max(0, zoomFrame.origin.x-10)
            self.scrollView.zoom(to: zoomFrame, animated: true)
        default:
            return
        }
    }

    private func removeOverlayView() {
        guard let overlayView = self.overlayView else { return }
        overlayView.removeFromSuperview()
        self.overlayView = nil
    }

    private func createOverlay(frame: CGRect, xOffset: CGFloat, yOffset: CGFloat, radius: CGFloat) -> UIView? {
        self.removeOverlayView()
        switch self.state {
        case  .faceSelected(_) :
            break
        default:
            return nil
        }
        let overlayView = UIView(frame: frame)
        overlayView.backgroundColor = self.style.backgroudColor.withAlphaComponent(0.8)

        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: xOffset, y: yOffset), radius: radius, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = self.style.backgroudColor.cgColor
        maskLayer.path = path
        maskLayer.fillRule = kCAFillRuleEvenOdd
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true
        overlayView.isUserInteractionEnabled = false
        self.view.addSubview(overlayView)
        let topLabelFrame = CGRect(x: 0, y: 0, width: frame.width, height: yOffset - radius)
        let topLabel = UILabel(frame: topLabelFrame)
        topLabel.textColor = self.style.contentColor
        topLabel.textAlignment = .center
        topLabel.font = UIFont.systemFont(ofSize: 15.0)
        topLabel.text = "Move and Scale"
        overlayView.addSubview(topLabel)
        self.actionStackView.isHidden = false
        self.topCloseButton.isHidden = true
        self.view.bringSubview(toFront: self.actionStackView)
        return overlayView
    }

    @objc func cancelClicked() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func exchangeFaceClicked() {
        self.removeOverlayView()
        self.actionStackView.isHidden = true
        self.topCloseButton.isHidden = false
        self.scrollView.zoom(to: self.imageView.frame, animated: true)
        self.state = .readyToSelection
        self.detectFace()
    }

    @objc func chooseClicked() {
        guard let delegate = self.delegate else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        let cGImage = imageView.image?.cgImage?.cropping(to: self.cropArea)
        guard let croppedCGImage = cGImage else {
            delegate.facepickerController?(facepickerController: self, didChooseImage: nil)
            return
        }
        let croppedImage = UIImage(cgImage: croppedCGImage)
        delegate.facepickerController?(facepickerController: self, didChooseImage: croppedImage)

    }

    private var cropArea: CGRect {
        get{
            let factor = self.imageView.image!.size.width/view.frame.width
            let scale = 1/self.scrollView.zoomScale
            let imageFrame = self.imageView.imageFrame()
            var cropAreaRect = CGRect(x: 0, y: 0, width: self.radius*2, height: self.radius*2)
            cropAreaRect.origin.x = self.view.frame.midX-self.radius
            cropAreaRect.origin.y = self.view.frame.midY-self.radius
            let x = (self.scrollView.contentOffset.x + cropAreaRect.origin.x - imageFrame.origin.x) * scale * factor
            let y = (self.scrollView.contentOffset.y + cropAreaRect.origin.y - imageFrame.origin.y) * scale * factor
            let width = cropAreaRect.size.width * scale * factor
            let height = cropAreaRect.size.height * scale * factor
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

extension UIImageView{
    func imageFrame() -> CGRect {
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else{return CGRect.zero}
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        }else{
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}

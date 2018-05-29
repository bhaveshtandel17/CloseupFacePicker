//
//  DemonstrationViewController.swift
//  CloseupFacePicker
//
//  Created by Infxit-08893 on 29/05/18.
//  Copyright © 2018 bhavesh. All rights reserved.
//

import UIKit

class DemonstrationViewController: UIViewController {

    @IBOutlet weak var croppedImageView: UIImageView!
    let imagePicker = UIImagePickerController()
    var image = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.imagePicker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func detectFaceBtnClicked(_ sender: Any) {
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }

    private func loadFacepickerController() {
        let facepickerController = FacepickerController()
        facepickerController.datasource = self
        facepickerController.delegate = self
        facepickerController.style = .dark
        self.present(facepickerController, animated: true, completion: nil)
        self.croppedImageView.image = nil
    }
}

extension DemonstrationViewController: FacepickerControllerDatasource {
    func imageForFaceDetectionIn(facepickerController: FacepickerController) -> UIImage {
        return self.image
    }
}

extension DemonstrationViewController: FacepickerControllerDelegate {
    func facepickerController(facepickerController: FacepickerController, didChooseImage image: UIImage?) {
        facepickerController.dismiss(animated: true, completion: nil)
        self.croppedImageView.image = image
    }
}

extension DemonstrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.image = pickedImage
        }
        picker.dismiss(animated: true) {

        }
        self.loadFacepickerController()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

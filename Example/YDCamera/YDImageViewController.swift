//
//  YDImageViewController.swift
//  YDCameraSwift
//
//  Created by 王远东 on 2022/11/9.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class ImageViewController: UIViewController {
    var image: UIImage?
    var cameraManager: YDCameraManager?
    var imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        guard let validImage = image else {
            return
        }

        imageView.image = validImage

        if cameraManager?.cameraDevice == .front {
            switch validImage.imageOrientation {
            case .up, .down:
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            default:
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func closeButtonTapped(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
}

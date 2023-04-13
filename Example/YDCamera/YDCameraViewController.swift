//
//  YDCameraViewController.swift
//  YDCameraSwift
//
//  Created by 王远东 on 2022/11/9.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import SnapKit
import AVFoundation
import CoreServices

open class YDCameraViewController: UIViewController, UINavigationControllerDelegate {
    let darkBlue = UIColor(red: 4 / 255, green: 14 / 255, blue: 26 / 255, alpha: 1)
    let lightBlue = UIColor(red: 24 / 255, green: 125 / 255, blue: 251 / 255, alpha: 1)
    let redColor = UIColor(red: 229 / 255, green: 77 / 255, blue: 67 / 255, alpha: 1)
    
    public enum YDCameraImageType {
        case camera
        case library
        case dismiss
    }
    
    public var doAction: ((_ action: YDCameraImageType, _ data: Any?) -> Void)?
    
    let cameraManager = YDCameraManager()
    
//    var isOpenTorch:CameraTorchMode = .on

    /// 相机画面
    lazy var cameraView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var cameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "yd_camera_camera"), for: .normal)
        button.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var topBlackView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    lazy var bottomBlackView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    lazy var closeButton: UIButton = {
        let bt = UIButton(type: .custom)
        bt.setImage(UIImage(named: "yd_camera_close"), for: .normal)
        bt.addTarget(self, action: #selector(closeAction(_:)), for: .touchUpInside)
        return bt
    }()
    
    lazy var zoomBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "000000", alpha: 0.2)
        return view
    }()
    
    lazy var zoom1x: UIButton = {
        let bt = UIButton(type: .custom)
        bt.backgroundColor = UIColor(hexString: "000000", alpha: 0.5)
        bt.setTitle("1x", for: .normal)
        bt.setTitle("1x", for: .selected)
        bt.setTitleColor(UIColor(hexString: "FFFFFF"), for: .normal)
        bt.setTitleColor(UIColor(hexString: "FFBC00"), for: .selected)
        bt.addTarget(self, action: #selector(select1x), for: .touchUpInside)
        return bt
    }()
    
    lazy var zoom15x: UIButton = {
        let bt = UIButton(type: .custom)
        bt.backgroundColor = UIColor(hexString: "000000", alpha: 0.5)
        bt.setTitle("1.5x", for: .normal)
        bt.setTitle("1.5x", for: .selected)
        bt.setTitleColor(UIColor(hexString: "FFFFFF"), for: .normal)
        bt.setTitleColor(UIColor(hexString: "FFBC00"), for: .selected)
        bt.addTarget(self, action: #selector(select15x), for: .touchUpInside)
        return bt
    }()
    
    lazy var torchButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "yd_camera_torch_off"), for: .normal)
        button.setImage(UIImage(named: "yd_camera_torch_on"), for: .selected)
        button.addTarget(self, action: #selector(tourchButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var albumButton: UIButton = {
        let button = UIButton(type: .custom)
//        button.setTitle("相册", for: .normal)
        button.addTarget(self, action: #selector(imagePicker(_:)), for: .touchUpInside)
        
        let image = UIImageView(image: UIImage(named: "yd_camera_photo"))
        image.isUserInteractionEnabled = true
        button.addSubview(image)
        image.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(22.5)
        }
        
        let label = UILabel()
        label.text = "从相册中选择"
        label.font = .systemFont(ofSize: 10)
        label.textAlignment = .center
        label.textColor = UIColor(hexString: "CCCCCC")
        button.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(image.snp.bottom).offset(7)
            make.height.equalTo(14)
        }
        
        return button
    }()
    
    
    /// 工具页面
    lazy var toolbarView: UIView = {
        let view = UIView()
        return view
    }()
    
    
    open override func viewDidLoad() {
        self.view.backgroundColor = .black
        setupCameraManager()
        setupView()
        let currentCameraState = cameraManager.currentCameraStatus()
        
        if currentCameraState == .notDetermined {
            AuthHelper.requestAuthorizationForCamera({ [weak self](granted: Bool) in
                guard let self = self else { return }
                if granted {
                    self.addCameraToView()
                } else {
                    
                }
            })
        } else if currentCameraState == .ready {
            addCameraToView()
        } else {
            
        }
        
        willEnterForegroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            guard let self = self else { return }
            self.cameraManager.torchMode = .off
            self.torchButton.isSelected = false
        }
        
    }
    
    var willEnterForegroundObserver: Any? = nil
    
    deinit {
        
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            willEnterForegroundObserver = nil
        }
        
        cameraView.removeFromSuperview()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
                cameraManager.resumeCaptureSession()

//        cameraManager.startQRCodeDetection { result in
//            switch result {
//                case .success(let value):
//                    print(value)
//                case .failure(let error):
//                    print(error.localizedDescription)
//            }
//        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        self.isOpenTorch = self.cameraManager.torchMode
        self.cameraManager.torchMode = .off
        self.torchButton.isSelected = false
//        cameraManager.stopQRCodeDetection()
        cameraManager.stopCaptureSession()
    }
    
    func setupView() {
        self.view.addSubview(topBlackView)
        self.view.addSubview(bottomBlackView)
        self.view.addSubview(cameraView)
        self.view.addSubview(cameraButton)
        self.view.addSubview(torchButton)
        self.view.addSubview(albumButton)
        self.view.addSubview(closeButton)
        
        self.view.addSubview(zoomBgView)
        zoomBgView.ai_addSubViews(subViews: [zoom1x, zoom15x])
        
        if AIIsiPad {
            topBlackView.isHidden = true
            bottomBlackView.isHidden = true
            cameraView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }else {
            topBlackView.isHidden = false
            bottomBlackView.isHidden = false
            
            if !UIDevice.isIPhoneX {
                zoomBgView.isHidden = true
            }
            
            let h:CGFloat = 4.000/3.000*ScreenWidth
            
            topBlackView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(110)
            }
            
            cameraView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.topBlackView.snp.bottom)
                make.height.equalTo(h)
            }
            
            bottomBlackView.snp.makeConstraints { make in
                make.left.bottom.right.equalToSuperview()
                make.top.equalTo(self.cameraView.snp.bottom)
            }
            
        }
        
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.width.height.equalTo(24)
            make.top.equalToSuperview().offset(44)
        }
        
        cameraButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-73)
            make.width.height.equalTo(66)
        }
        
        torchButton.snp.makeConstraints { make in
            make.centerY.equalTo(cameraButton)
            make.right.equalToSuperview().offset(-28)
            make.width.height.equalTo(48)
        }
        
        albumButton.snp.makeConstraints { make in
            make.centerY.equalTo(cameraButton)
            make.left.equalToSuperview().offset(28)
            make.width.equalTo(65)
            make.height.equalTo(44)
        }
        
        if cameraManager.hasTorch {
            torchButton.isHidden = false
            if cameraManager.torchMode == .on {
                torchButton.isSelected = true
            }else {
                torchButton.isSelected = false
            }
        }else {
            torchButton.isHidden = true
        }
        
        if AIIsiPad {
            zoomBgView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(82.5)
                make.height.equalTo(42.5)
                make.bottom.equalTo(self.cameraButton.snp.top).offset(-73.5)
            }
        }else {
            zoomBgView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(82.5)
                make.height.equalTo(42.5)
                make.bottom.equalTo(self.bottomBlackView.snp.top).offset(-10)
            }
        }
        
        zoomBgView.layer.cornerRadius = 21.25
        zoom1x.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(36)
        }
        
        zoom15x.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(36)
        }
    }
    
    func reloadZoom() {
        if zoom1x.isSelected {
            zoom1x.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(4)
                make.centerY.equalToSuperview()
                make.height.width.equalTo(36)
            }
            
            zoom15x.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-4)
                make.centerY.equalToSuperview()
                make.height.width.equalTo(28)
            }
            
            zoom1x.titleLabel?.font = .systemFont(ofSize: 12)
            zoom15x.titleLabel?.font = .systemFont(ofSize: 10)
            zoom1x.layer.cornerRadius = 18
            zoom15x.layer.cornerRadius = 14
        }else {
            zoom1x.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(4)
                make.centerY.equalToSuperview()
                make.height.width.equalTo(28)
            }
            
            zoom15x.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-4)
                make.centerY.equalToSuperview()
                make.height.width.equalTo(36)
            }
            
            zoom1x.layer.cornerRadius = 14
            zoom15x.layer.cornerRadius = 18
            zoom1x.titleLabel?.font = .systemFont(ofSize: 10)
            zoom15x.titleLabel?.font = .systemFont(ofSize: 12)
        }
    }
    
    @objc func select1x() {
        cameraManager.zoom(1)
        zoom1x.isSelected = true
        zoom15x.isSelected = false
        reloadZoom()
    }
    
    @objc func select15x() {
        cameraManager.zoom(1.5)
        zoom1x.isSelected = false
        zoom15x.isSelected = true
        reloadZoom()
    }
    
    // MARK: - ViewController
    fileprivate func setupCameraManager() {
        cameraManager.shouldEnableExposure = true
        cameraManager.writeFilesToPhoneLibrary = false
        cameraManager.shouldFlipFrontCameraImage = false
        cameraManager.showAccessPermissionPopupAutomatically = false
        cameraManager.cameraOutputQuality = .high
        cameraManager.cameraOutputMode = .stillImage
        cameraManager.doZoomAction = { [weak self](zoom) in
            print(zoom)
            DispatchQueue.main.async {
                if 1 <= zoom && zoom < 1.5 {
                    self?.zoom1x.isSelected = true
                    self?.zoom15x.isSelected = false

                    self?.zoom1x.snp.remakeConstraints { make in
                        make.left.equalToSuperview().offset(4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(36)
                    }

                    self?.zoom15x.snp.remakeConstraints { make in
                        make.right.equalToSuperview().offset(-4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(28)
                    }

                    self?.zoom1x.setTitle(String(format: "%.1fx", zoom), for: .selected)
                    self?.zoom1x.setTitle(String(format: "%.1fx", zoom), for: .normal)

                    self?.zoom15x.setTitle(String(format: "1.5x"), for: .selected)
                    self?.zoom15x.setTitle(String(format: "1.5x"), for: .normal)
                    
                    self?.zoom1x.titleLabel?.font = .systemFont(ofSize: 12)
                    self?.zoom15x.titleLabel?.font = .systemFont(ofSize: 10)
                    self?.zoom1x.layer.cornerRadius = 18
                    self?.zoom15x.layer.cornerRadius = 14
                    
                }else if zoom >= 1.5 && zoom <= 2 {
                    self?.zoom1x.isSelected = false
                    self?.zoom15x.isSelected = true

                    self?.zoom1x.snp.remakeConstraints { make in
                        make.left.equalToSuperview().offset(4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(28)
                    }

                    self?.zoom15x.snp.remakeConstraints { make in
                        make.right.equalToSuperview().offset(-4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(36)
                    }

                    self?.zoom1x.setTitle(String(format: "1x"), for: .selected)
                    self?.zoom1x.setTitle(String(format: "1x"), for: .normal)

                    self?.zoom15x.setTitle(String(format: "%.1fx", zoom), for: .selected)
                    self?.zoom15x.setTitle(String(format: "%.1fx", zoom), for: .normal)
                    
                    self?.zoom1x.layer.cornerRadius = 14
                    self?.zoom15x.layer.cornerRadius = 18
                    self?.zoom1x.titleLabel?.font = .systemFont(ofSize: 10)
                    self?.zoom15x.titleLabel?.font = .systemFont(ofSize: 12)

                }else if zoom < 1 {
                    self?.zoom1x.isSelected = true
                    self?.zoom15x.isSelected = false


                    self?.zoom1x.snp.remakeConstraints { make in
                        make.left.equalToSuperview().offset(4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(36)
                    }

                    self?.zoom15x.snp.remakeConstraints { make in
                        make.right.equalToSuperview().offset(-4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(28)
                    }

                    self?.zoom1x.setTitle(String(format: "1x"), for: .selected)
                    self?.zoom1x.setTitle(String(format: "1x"), for: .normal)

                    self?.zoom15x.setTitle(String(format: "1.5x"), for: .selected)
                    self?.zoom15x.setTitle(String(format: "1.5x"), for: .normal)
                    
                    self?.zoom1x.titleLabel?.font = .systemFont(ofSize: 12)
                    self?.zoom15x.titleLabel?.font = .systemFont(ofSize: 10)
                    self?.zoom1x.layer.cornerRadius = 18
                    self?.zoom15x.layer.cornerRadius = 14

                }else {
                    self?.zoom1x.isSelected = false
                    self?.zoom15x.isSelected = true

                    self?.zoom1x.snp.remakeConstraints { make in
                        make.left.equalToSuperview().offset(4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(28)
                    }

                    self?.zoom15x.snp.remakeConstraints { make in
                        make.right.equalToSuperview().offset(-4)
                        make.centerY.equalToSuperview()
                        make.height.width.equalTo(36)
                    }

                    self?.zoom1x.setTitle(String(format: "1x", zoom), for: .selected)
                    self?.zoom1x.setTitle(String(format: "1x", zoom), for: .normal)

                    self?.zoom15x.setTitle(String(format: "%.1fx", zoom), for: .selected)
                    self?.zoom15x.setTitle(String(format: "%.1fx", zoom), for: .normal)
                    
                    self?.zoom1x.layer.cornerRadius = 14
                    self?.zoom15x.layer.cornerRadius = 18
                    self?.zoom1x.titleLabel?.font = .systemFont(ofSize: 10)
                    self?.zoom15x.titleLabel?.font = .systemFont(ofSize: 12)
                }
            }

        }
    }
    
    
    fileprivate func addCameraToView() {
//        cameraManager.addPreviewLayerToView(cameraView, newCameraOutputMode: CameraOutputMode.stillImage)
        cameraManager.addLayerPreviewToView(cameraView, newCameraOutputMode: CameraOutputMode.stillImage) {
            DispatchQueue.main.async {
                self.zoom1x.isSelected = false
                self.zoom15x.isSelected = true
                self.reloadZoom()
                
                self.torchOn()
                self.torchButton.isSelected = true
            }
        }
        cameraManager.showErrorBlock = { (erTitle: String, erMessage: String) -> Void in
//            DispatchQueue.main.async {
//                let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
//                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (_) -> Void in }))
//
//                self?.present(alertController, animated: true, completion: nil)
//            }
            AILog("\(erMessage)")
        }
    }
    
    @objc open func closeAction(_ sender: UIButton) {
        self.doAction?(.dismiss, nil)
        self.dismiss(animated: true)
    }
    
    @objc open func tourchButtonTapped(_ sender: UIButton) {
        if torchButton.isSelected {
            torchButton.isSelected = false
            torchOff()
        }else {
            torchButton.isSelected = true
            torchOn()
        }
    }
    
    @objc open func recordButtonTapped(_ sender: UIButton) {
        switch cameraManager.cameraOutputMode {
            case .stillImage:
                cameraManager.capturePictureWithCompletion { result in
                    switch result {
                        case .failure:
                            self.cameraManager.showErrorBlock("Error occurred", "Cannot save picture.")
                        case .success(let content):
                            if case let capturedData = content.asData {
                                let capturedImage = UIImage(data: capturedData!)!
                                self.doAction?(.camera, capturedImage)
//                                self.navigationController?.popViewController(animated: true)
                                self.dismiss(animated: true)
                            }
                    }
                }
            case .videoWithMic, .videoOnly:
                cameraButton.isSelected = !cameraButton.isSelected
                cameraButton.setTitle("", for: UIControl.State.selected)
                
                cameraButton.backgroundColor = cameraButton.isSelected ? redColor : lightBlue
                if sender.isSelected {
                    cameraManager.startRecordingVideo()
                } else {
                    cameraManager.stopVideoRecording { (_, error) -> Void in
                        if error != nil {
                            self.cameraManager.showErrorBlock("Error occurred", "Cannot save video.")
                        }
                    }
                }
        }
    }
    
    
    
    @objc open func stillImage() {
        cameraManager.capturePictureWithCompletion { result in
            switch result {
                case .failure:
                    self.cameraManager.showErrorBlock("Error occurred", "Cannot save picture.")
                case .success(let content):
                    
                    let vc: ImageViewController = ImageViewController()
                    if case let capturedData = content.asData {
                        print(capturedData!.printExifData())
                        let capturedImage = UIImage(data: capturedData!)!
                        vc.image = capturedImage
                        vc.cameraManager = self.cameraManager
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
            }
        }
    }
    
    @objc open func videoWithMic(_ sender: UIButton) {
        cameraButton.isSelected = !cameraButton.isSelected
        cameraButton.setTitle("", for: UIControl.State.selected)
        
        cameraButton.backgroundColor = cameraButton.isSelected ? redColor : lightBlue
        if sender.isSelected {
            cameraManager.startRecordingVideo()
        } else {
            cameraManager.stopVideoRecording { (_, error) -> Void in
                if error != nil {
                    self.cameraManager.showErrorBlock("Error occurred", "Cannot save video.")
                }
            }
        }
    }
    
    @objc open func videoOnly (_ sender: UIButton) {
        cameraButton.isSelected = !cameraButton.isSelected
        cameraButton.setTitle("", for: UIControl.State.selected)
        
        cameraButton.backgroundColor = cameraButton.isSelected ? redColor : lightBlue
        if sender.isSelected {
            cameraManager.startRecordingVideo()
        } else {
            cameraManager.stopVideoRecording { (_, error) -> Void in
                if error != nil {
                    self.cameraManager.showErrorBlock("Error occurred", "Cannot save video.")
                }
            }
        }
    }
    
    
    /// 切换清晰度
    @objc open func changeCameraQualityMode(mode: AVCaptureSession.Preset) {
        cameraManager.cameraOutputQuality = mode
    }
    
    /// 设置闪光灯
    @objc open func changeFlashMode(mode: Int) {
        cameraManager.flashMode = CameraFlashMode(rawValue: mode) ?? .off
    }
    
    /// 闪光灯开
    @objc open func flashOn() {
        cameraManager.flashMode = .on
    }
    
    /// 闪光灯关
    @objc open func flashOff() {
        cameraManager.flashMode = .off
    }
    
    @objc open func torchOn() {
        cameraManager.torchMode = .on
    }
    
    @objc open func torchOff() {
        cameraManager.torchMode = .off
    }
    
    @objc open func imagePicker(_ sender: UIButton) {
        
//        AIImagePickerViewController.webAIimagePicker(fromPage: self, type: .photoLibrary) { [weak self] image in
//
//            guard let self = self else { return }
//            self.doAction?(.library, image)
//            self.dismiss(animated: true)
//        }

        
        let vc = UAImagePickerController()
        vc.allowsEditing = false
        vc.delegate = self
        vc.sourceType = .photoLibrary
        vc.mediaTypes = [kUTTypeImage as String]
        vc.modalPresentationStyle = .fullScreen
        //
        AuthHelper.requestAuthorizationForPhotoLibrary({ [weak self](granted: Bool) in
            guard let self = self else { return }
            if granted {
                self.present(vc, animated: true)
            }
        })
    }
    /// 打开手电筒
}

public extension Data {
    func printExifData() {
        let cfdata: CFData = self as CFData
        let imageSourceRef = CGImageSourceCreateWithData(cfdata, nil)
        let imageProperties = CGImageSourceCopyMetadataAtIndex(imageSourceRef!, 0, nil)!
        
        let mutableMetadata = CGImageMetadataCreateMutableCopy(imageProperties)!
        
        CGImageMetadataEnumerateTagsUsingBlock(mutableMetadata, nil, nil) { _, tag in
            print(CGImageMetadataTagCopyName(tag)!, ":", CGImageMetadataTagCopyValue(tag)!)
            return true
        }
    }
}

// MARK: UIImagePickerControllerDelegate,  UINavigationControllerDelegate
extension YDCameraViewController: UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
            switch mediaType {
                case "public.image":
                    if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                        self.doAction?(.library, image)
                        picker.dismiss(animated: true) {
                            self.dismiss(animated: false)
                        }
                    }
                    break
                default:
                    break
            }
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

//
//  YDCameraEnum.swift
//  YDCameraSwift
//
//  Created by 王远东 on 2022/11/9.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import Photos

public enum CameraState {
    case ready, accessDenied, noDeviceFound, notDetermined
}

public enum CameraDevice {
    case front, back
}

public enum CameraFlashMode: Int {
    case off, on, auto
}

public enum CameraTorchMode: Int {
    case off, on
}

public enum CameraOutputMode {
    case stillImage, videoWithMic, videoOnly
}

public enum CaptureResult {
    case success(content: CaptureContent)
    case failure(Error)
    
    init(_ image: UIImage) {
        self = .success(content: .image(image))
    }
    
    init(_ data: Data) {
        self = .success(content: .imageData(data))
    }
    
    init(_ asset: PHAsset) {
        self = .success(content: .asset(asset))
    }
    
    var imageData: Data? {
        if case let .success(content) = self {
            return content.asData
        } else {
            return nil
        }
    }
}

extension CaptureContent {
    public var asImage: UIImage? {
        switch self {
            case let .image(image): return image
            case let .imageData(data): return UIImage(data: data)
            case let .asset(asset):
                if let data = getImageData(fromAsset: asset) {
                    return UIImage(data: data)
                } else {
                    return nil
            }
        }
    }
    
    public var asData: Data? {
        switch self {
            case let .image(image): return image.jpegData(compressionQuality: 1.0)
            case let .imageData(data): return data
            case let .asset(asset): return getImageData(fromAsset: asset)
        }
    }
    
    private func getImageData(fromAsset asset: PHAsset) -> Data? {
        var imageData: Data?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            
            imageData = data
        }
        return imageData
    }
}

public enum CaptureContent {
    case imageData(Data)
    case image(UIImage)
    case asset(PHAsset)
}

public enum CaptureError: Error {
    case noImageData
    case invalidImageData
    case noVideoConnection
    case noSampleBuffer
    case assetNotSaved
}

//
//  CameraViewModel.swift
//  mockup
//
//  Created by Studente on 19/08/24.
//

import Foundation
import AVFoundation
import UIKit

class CameraViewModel: NSObject, ObservableObject {
    public static let MAX_ZOOM_FACTOR: CGFloat = 12.0
    public static let MIN_ZOOM_FACTOR: CGFloat = 1.0
    
    public var session: AVCaptureSession
    private var photoOutput: AVCapturePhotoOutput
    private var videoOutput: AVCaptureMovieFileOutput
    private var previewLayer: AVCaptureVideoPreviewLayer
    private var timer: Timer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    @Published var media: TMedia? = nil
    
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var recordedSeconds: Int = 0
    @Published var isRecording = false
    @Published var currentZoomFactor: CGFloat = 1.0 {
        didSet {
            approximateZoomFactor = (currentZoomFactor - 1) > 0.1
            ? "\(String(format: "%.1f", currentZoomFactor))x"
            : ""
        }
    }
    @Published var approximateZoomFactor: String = ""
    
    override init() {
        self.session = AVCaptureSession()
        self.photoOutput = AVCapturePhotoOutput()
        self.videoOutput = AVCaptureMovieFileOutput()
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init()
        setupSession()
    }
    
    func resumeSessionIfNeeded() {
        if !session.isRunning {
            startSession()
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
             
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            session.sessionPreset = .photo // 4:3 Format
            session.commitConfiguration()
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func startSession() {
        DispatchQueue(label: "camera.provider").async {
            Task {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
    }
    
    func stopSession() {
        DispatchQueue(label: "camera.provider").async {
            Task {
                if self.session.isRunning {
                    self.session.stopRunning()
                }
            }
        }
    }
    
    func clearCapturedMedia() {
        self.media = nil
    }
    
    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No video capture device found.")
            return
        }
        
        do {
            try device.lockForConfiguration()
            if device.hasTorch {
                if on {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
            } else {
                print("Torch is not available on this device.")
            }
            device.unlockForConfiguration()
        } catch {
            print("Error configuring torch: \(error)")
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecording() {
        let outputURL = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        if currentCameraPosition == .front {
            flashMode = .off
        } else {
            setTorch(on : flashMode == .off ? false :  true)
        }
        recordedSeconds = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.recordedSeconds += 1
        }
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
        isRecording = false
        if flashMode != .off {
            setTorch(on: false)
        }
        timer?.invalidate()
        timer = nil
        recordedSeconds = 0
    }
    
    func switchCamera() {
        guard let currentCameraInput: AVCaptureInput = session.inputs.first else {
            return
        }
        
        session.beginConfiguration()
        session.removeInput(currentCameraInput)
        
        let newCameraDevice: AVCaptureDevice
        if let input = currentCameraInput as? AVCaptureDeviceInput, input.device.position == .back {
            newCameraDevice = camera(with: .front)
            currentCameraPosition = .front
        } else {
            newCameraDevice = camera(with: .back)
            currentCameraPosition = .back
        }
        
        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newCameraDevice)
            session.addInput(newVideoInput)
        } catch {
            print("Error switching cameras: \(error)")
            session.addInput(currentCameraInput)
        }
        
        session.commitConfiguration()
        currentZoomFactor = 1.0 // Reset zoom factor to default
    }
    
    private func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices
        return devices.first(where: { $0.activeFormat.videoMaxZoomFactor > 1.0 }) ?? devices.first!
    }
    
    func toggleFlashMode() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasFlash else {
            print("Flash not supported on this device")
            return
        }
        
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .off
        default:
            flashMode = .off
        }
    }
    
    func zoom(factor: CGFloat) {
        guard let device = AVCaptureDevice.default(for: .video), currentCameraPosition == .back else { return }
        
        do {
            try device.lockForConfiguration()
            
            let newZoomFactor = max(Self.MIN_ZOOM_FACTOR, min(Self.MAX_ZOOM_FACTOR, device.videoZoomFactor * factor))
            if newZoomFactor >= Self.MIN_ZOOM_FACTOR && newZoomFactor <= device.activeFormat.videoMaxZoomFactor {
                device.videoZoomFactor = newZoomFactor
                self.currentZoomFactor = newZoomFactor
            } else {
                print("Zoom factor out of range")
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Failed to change zoom factor: \(error)")
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        do {
            guard let data = photo.fileDataRepresentation() else {
                return
            }
            
            self.media = try TMedia(image: TImage(withData: data), origin: .camera)
        } catch {
            print(error)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        do {
            self.media = try TMedia(video: TVideo(withURL: outputFileURL), origin: .camera)
        } catch {
            print(error)
        }
    }
}


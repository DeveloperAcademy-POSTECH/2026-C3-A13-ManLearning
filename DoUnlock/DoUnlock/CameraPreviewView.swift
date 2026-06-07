//
//  CameraPreviewView.swift
//  FastViTTest
//
//  Created by 정필규 on 5/15/26.
//

@preconcurrency import AVFoundation
import SwiftUI
import UIKit



struct CameraPreviewView: UIViewRepresentable {
    
    let isActive: Bool    // true이면 라이브 프리뷰 세션을 실행, false이면 카메라 장치 점유를 해제
    let captureImageTrigger: Bool
    let pixelHandler: (CVPixelBuffer, CGRect) -> Void
    let imageHandler: (UIImage, UIImage) -> Void

    func makeUIView(context: Context) -> PreviewView {
        // AVCaptureVideoPreviewLayer를 가진 UIView를 만들고 coordinator가 세션을 연결합니다.
        let view = PreviewView()
        context.coordinator.configureSession(
            for: view,
            captureImageTrigger: captureImageTrigger,
            pixelHandler: pixelHandler,
            imageHandler: imageHandler,
            isActive: isActive
        )
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.update(
            isActive: isActive,
            captureImageTrigger: captureImageTrigger,
            pixelHandler: pixelHandler,
            imageHandler: imageHandler
        )
    }

    func makeCoordinator() -> CameraCoordinator {
        // 실제 카메라 작업을 담당하는 코디네이터 생성
        CameraCoordinator()
    }
    
    
    static func dismantleUIView(_ uiView: PreviewView, coordinator: CameraCoordinator) {
        // SwiftUI에서 view가 해제될 때 카메라 세션도 정리합니다.
        coordinator.stop()
    }
}

// MARK

final class PreviewView: UIView {
    var cropWidthRatio: CGFloat = 0.63
    var cropHeightRatio: CGFloat = 0.45
    var normalizedCropRectHandler: ((CGRect) -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateNormalizedCropRect()
    }

    private func updateNormalizedCropRect() {
        let bounds = previewLayer.bounds
        guard bounds.isEmpty == false else { return }

        let guideWidth = bounds.width * cropWidthRatio
        let guideHeight = bounds.height * cropHeightRatio

        let guideRect = CGRect(
            x: bounds.midX - guideWidth / 2,
            y: bounds.midY - guideHeight / 2,
            width: guideWidth,
            height: guideHeight
        )

        let normalizedRect = previewLayer.metadataOutputRectConverted(
            fromLayerRect: guideRect
        )

        normalizedCropRectHandler?(normalizedRect)
    }
}


final class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var pixelHandler: ((CVPixelBuffer, CGRect) -> Void)?
    private var imageHandler: ((UIImage, UIImage) -> Void)?
    private var normalizedGuideRect: CGRect?



    private let cropWidthRatio: CGFloat = 0.63 //카메라 가로 대비 객체 인식 비율
    private let cropHeightRatio: CGFloat = 0.45  //카메라 세로 대비 객체 인식 비율

    private var shouldCaptureImage = false
    private var shouldCaptureFullImage = false
    private var lastCaptureImageTrigger = false
    
    // 라이브 카메라 입력/출력을 묶는 capture session입니다.
    private let session = AVCaptureSession()

    // 세션 구성과 start/stop은 전용 큐에서 처리해 UI thread를 막지 않습니다.
    private let sessionQueue = DispatchQueue(label: "FastViTTest.CameraSession")

    // 프레임 delegate callback을 받는 큐입니다.
    private let videoQueue = DispatchQueue(label: "FastViTTest.CameraFrames")

    // 현재 프레임을 view model로 전달하는 callback입니다.
    private var frameHandler: ((CVPixelBuffer) -> Void)?

    // 카메라 세션을 켤지 여부를 기억합니다.
    private var isActive = false

    // 세션 input/output 구성은 한 번만 하고, 이후에는 start/stop만 반복합니다.
    private var isConfigured = false

    
    private func updateNormalizedGuideRect(_ rect: CGRect) {
        videoQueue.async {
            self.normalizedGuideRect = rect
        }
    }
    
    func configureSession(
        for view: PreviewView,
        captureImageTrigger: Bool,
        pixelHandler: @escaping (CVPixelBuffer, CGRect) -> Void,
        imageHandler: @escaping (UIImage, UIImage) -> Void,
        isActive: Bool
    ) {
        self.isActive = isActive
        self.lastCaptureImageTrigger = captureImageTrigger
        self.pixelHandler = pixelHandler
        self.imageHandler = imageHandler

        view.cropWidthRatio = cropWidthRatio
        view.cropHeightRatio = cropHeightRatio
        view.normalizedCropRectHandler = { [weak self] rect in
            self?.updateNormalizedGuideRect(rect)
        }
        
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        

        sessionQueue.async {
            self.requestAccessIfNeeded()
        }
    }

    func update(
        isActive: Bool,
        captureImageTrigger: Bool,
        pixelHandler: @escaping (CVPixelBuffer, CGRect) -> Void,
        imageHandler: @escaping (UIImage, UIImage) -> Void
    ) {
        self.pixelHandler = pixelHandler
        self.imageHandler = imageHandler

        if captureImageTrigger != lastCaptureImageTrigger {
            shouldCaptureImage = true
            lastCaptureImageTrigger = captureImageTrigger
        }

        sessionQueue.async {
            guard self.isActive != isActive else { return }
            self.isActive = isActive

            if isActive {
                self.requestAccessIfNeeded()
            } else {
                self.stopSession()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            self.stopSession()
        }
    }

    private func requestAccessIfNeeded() {
        guard isActive else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureIfNeededAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else { return }
                self.sessionQueue.async {
                    self.configureIfNeededAndStart()
                }
            }
        default:
            return
        }
    }

    private func configureIfNeededAndStart() {
        guard isActive else { return }

        if isConfigured == false {
            configureSessionInputsAndOutputs()
        }

        guard isConfigured, session.isRunning == false else { return }
        session.startRunning()
    }

    private func configureSessionInputsAndOutputs() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // 재구성 시 기존 input/output을 지우고 현재 후면 카메라 + 비디오 프레임 output만 붙입니다.
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            isConfigured = false
            return
        }
        session.addInput(input)

        // YCbCr bi-planar: CropQualityAnalyzer 루마 플레인 접근 및 Vision 추론 모두 지원합니다.
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            isConfigured = false
            return
        }
        session.addOutput(output)

        // 세로 UI와 맞추기 위해 프레임 회전을 portrait 기준으로 맞춥니다.
        if let connection = output.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()
        isConfigured = true
    }

    private func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func makeFullImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func makeCroppedImage(
        // 이미지 전송이 필요할 경우
        
        from pixelBuffer: CVPixelBuffer,
        cropRect: CGRect
    ) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let croppedImage = ciImage.cropped(to: cropRect)

        let context = CIContext()

        guard let cgImage = context.createCGImage(croppedImage, from: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 비디오 프레임에서 pixel buffer를 꺼내 실시간 유사도 계산 쪽으로 넘깁니다.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let normalizedRect = normalizedGuideRect else { return }

        let pixelWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        let cropRect = CGRect(
            x: normalizedRect.minX * pixelWidth,
            y: normalizedRect.minY * pixelHeight,
            width: normalizedRect.width * pixelWidth,
            height: normalizedRect.height * pixelHeight
        ).integral


        pixelHandler?(pixelBuffer, cropRect)
        
        //저장용 잘린 이미지 전송
        if shouldCaptureImage {
            shouldCaptureImage = false

            guard
                let fullImage = makeFullImage(from: pixelBuffer),
                let croppedImage = makeCroppedImage(from: pixelBuffer, cropRect: cropRect)
            else {
                return
            }

            imageHandler?(fullImage, croppedImage)
        }

    }
}

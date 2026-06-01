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
    let frameHandler: (CVPixelBuffer) -> Void     // 각 비디오 프레임을 밖으로 callback


    func makeUIView(context: Context) -> PreviewView {
        // AVCaptureVideoPreviewLayer를 가진 UIView를 만들고 coordinator가 세션을 연결합니다.
        let view = PreviewView()
        context.coordinator.configureSession(
            for: view,
            frameHandler: frameHandler,
            isActive: isActive
        )
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // SwiftUI 상태 변화에 맞춰 카메라 세션을 시작하거나 멈춥니다.
        context.coordinator.setActive(isActive)
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
    // 카메라 영상을 실제로 화면에 보여주는 UIKit view
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    // preview layer 접근을 단순하게 만듭니다.
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}


final class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
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

    func configureSession(
        for view: PreviewView,
        frameHandler: @escaping (CVPixelBuffer) -> Void,
        isActive: Bool
    ) {
        self.frameHandler = frameHandler
        self.isActive = isActive
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill

        sessionQueue.async {
            self.requestAccessIfNeeded()
        }
    }

    func setActive(_ newValue: Bool) {
        sessionQueue.async {
            guard self.isActive != newValue else { return }
            self.isActive = newValue

            if newValue {
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
        session.sessionPreset = .medium

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

        // CoreML 입력으로 바로 넘기기 쉬운 BGRA pixel buffer를 요청합니다.
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
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

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 비디오 프레임에서 pixel buffer를 꺼내 실시간 유사도 계산 쪽으로 넘깁니다.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        frameHandler?(pixelBuffer)
    }
}

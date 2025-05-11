import SwiftUI
import AVFoundation
import UIKit

struct LiveMonitoringView: View {
    private let classNames = [
        "Çatlama",      // 0
        "Kapsama",      // 1
        "Yamalar",      // 2
        "Çukur Yüzey",  // 3
        "Hadde Kabukları", // 4
        "Çizikler"      // 5
    ]
    
    @State private var detectedClass: String = "Hata Bekleniyor..."
    @State private var confidence: Double = 0.0
    @State private var isDetecting: Bool = false
    
    var body: some View {
        ZStack {
            CameraView { image in
                if let cgImage = image.cgImage {
                    detectError(in: UIImage(cgImage: cgImage))
                }
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                Text(detectedClass)
                    .font(.headline)
                    .foregroundColor(confidence > 0.8 ? .green : (confidence > 0.5 ? .yellow : .red))
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(12)
                    .padding()
                
                Text("Güven: \(String(format: "%.2f", confidence * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func detectError(in image: UIImage) {
        // Model ile hata tespiti
        NetworkManager.shared.predictImage(image: image) { result in
            DispatchQueue.main.async {
                let components = result.split(separator: "-")
                if components.count == 2 {
                    let classIndex = Int(components[0].trimmingCharacters(in: .whitespaces)) ?? 0
                    let confidenceValue = Double(components[1].trimmingCharacters(in: .whitespaces)) ?? 0.0
                    self.detectedClass = classIndex < 6 ? classNames[classIndex] : "Bilinmeyen"
                    self.confidence = confidenceValue
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    var onFrameCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onFrameCaptured = onFrameCaptured
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrameCaptured: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return }
        captureSession?.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        captureSession?.addOutput(output)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession?.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.onFrameCaptured?(image)
            }
        }
    }
}

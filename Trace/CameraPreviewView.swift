import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        // Called whenever bounds change, including on device rotation.
        override func layoutSubviews() {
            super.layoutSubviews()
            syncVideoOrientation()
        }

        // Called when the view enters the window hierarchy, so the initial
        // orientation is applied before the first frame is drawn.
        override func didMoveToWindow() {
            super.didMoveToWindow()
            setNeedsLayout()
        }

        private func syncVideoOrientation() {
            guard
                let connection = previewLayer.connection,
                let orientation = window?.windowScene?.interfaceOrientation
            else { return }

            if #available(iOS 17.0, *) {
                let angle: CGFloat = switch orientation {
                case .landscapeLeft:      180
                case .landscapeRight:     0
                case .portraitUpsideDown: 270
                default:                  90   // .portrait
                }
                if connection.isVideoRotationAngleSupported(angle) {
                    connection.videoRotationAngle = angle
                }
            } else {
                guard connection.isVideoOrientationSupported else { return }
                connection.videoOrientation = switch orientation {
                case .portrait:           .portrait
                case .portraitUpsideDown: .portraitUpsideDown
                case .landscapeLeft:      .landscapeLeft
                case .landscapeRight:     .landscapeRight
                default:                  .portrait
                }
            }
        }
    }
}

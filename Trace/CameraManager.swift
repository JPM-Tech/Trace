import AVFoundation

enum CameraStatus: Equatable {
    case loading        // Authorization not yet determined, or session starting
    case unauthorized   // Permission denied or restricted
    case ready          // Session is running
}

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var status: CameraStatus = .loading

    override init() {
        super.init()
        checkAuthorization()
    }

    private func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configure()
                } else {
                    DispatchQueue.main.async { self?.status = .unauthorized }
                }
            }
        default:
            status = .unauthorized
        }
    }

    private func configure() {
        session.sessionPreset = .high
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            DispatchQueue.main.async { self.status = .unauthorized }
            return
        }
        session.addInput(input)
        // startRunning() is synchronous — it blocks until the session is
        // fully live, so status becomes .ready only once frames are flowing.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.status = .ready
            }
        }
    }
}

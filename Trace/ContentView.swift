import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    // Photo state
    @State private var pickerItem: PhotosPickerItem?
    @State private var overlayImage: UIImage?

    // Controls
    @State private var opacity: Double = 0.5
    @State private var isLocked = false
    @State private var showControls = true

    // Committed transform
    @State private var position: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero

    // In-progress gesture deltas — auto-reset when gesture ends
    @GestureState private var dragDelta: CGSize = .zero
    @GestureState private var scaleDelta: CGFloat = 1.0
    @GestureState private var rotationDelta: Angle = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            cameraLayer
            overlayLayer
            controlsLayer
        }
        .animation(.easeIn(duration: 0.4), value: camera.status)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .onChange(of: pickerItem) { item in
            Task { @MainActor in
                guard let item,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { return }
                overlayImage = image
                resetTransform()
            }
        }
        .onChange(of: isLocked) { locked in
            camera.setFocusLocked(locked)
        }
    }

    // MARK: - Layers

    @ViewBuilder
    private var cameraLayer: some View {
        switch camera.status {
        case .loading:
            cameraLoadingView
        case .unauthorized:
            cameraPermissionView
        case .ready:
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
                .transition(.opacity)
        }
    }

    private var cameraLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(.white)
            Text("Starting camera…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var overlayLayer: some View {
        if let image = overlayImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(opacity)
                .scaleEffect(scale * scaleDelta)
                .rotationEffect(rotation + rotationDelta)
                .offset(
                    x: position.width + dragDelta.width,
                    y: position.height + dragDelta.height
                )
                .allowsHitTesting(!isLocked)
                .gesture(dragGesture)
                .simultaneousGesture(magnifyGesture)
                .simultaneousGesture(rotateGesture)
        }
    }

    private var controlsLayer: some View {
        VStack {
            Spacer()
            if showControls {
                controlBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragDelta) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                position.width += value.translation.width
                position.height += value.translation.height
            }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleDelta) { value, state, _ in
                state = value
            }
            .onEnded { value in
                scale = max(0.05, scale * value)
            }
    }

    private var rotateGesture: some Gesture {
        RotationGesture()
            .updating($rotationDelta) { value, state, _ in
                state = value
            }
            .onEnded { value in
                rotation += value
            }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: 8) {
            if overlayImage != nil {
                opacityRow
            }
            buttonRow
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var opacityRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.min")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Slider(value: $opacity, in: 0...1)
                .tint(.white)
            Image(systemName: "sun.max")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial)
        .clipShape(Capsule())
    }

    private var buttonRow: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(
                    overlayImage == nil ? "Choose Photo" : "Change Photo",
                    systemImage: "photo.badge.plus"
                )
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if overlayImage != nil {
                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        resetTransform()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                }

                Button {
                    withAnimation(.spring(response: 0.25)) {
                        isLocked.toggle()
                    }
                } label: {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                        .foregroundStyle(isLocked ? Color.yellow : Color.white)
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .foregroundStyle(.white)
    }

    // MARK: - Camera Permission Fallback

    private var cameraPermissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("Camera Access Required")
                .font(.title3.weight(.semibold))
            Text("Open Settings to allow Trace to use your camera.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func resetTransform() {
        position = .zero
        scale = 1.0
        rotation = .zero
    }
}

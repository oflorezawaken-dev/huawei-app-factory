import AVFoundation
import SwiftData
import SwiftUI
import UIKit

/// S004 Barcode Scanner. Recalls an item you already named; never looks a
/// barcode up online. No advertising of any kind.
struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allItems: [Item]

    @State private var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var torchOn = false
    @State private var manualSearchText = ""
    @State private var showManualSearch = false
    @State private var unknownCode: String?
    @State private var scannedItem: Item?

    var body: some View {
        NavigationStack {
            Group {
                switch authorizationStatus {
                case .authorized:
                    cameraContent
                case .notDetermined:
                    ProgressView().task { await requestAccess() }
                default:
                    deniedContent
                }
            }
            .navigationTitle("scanner.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                        .accessibilityIdentifier("scanner.cancel")
                }
            }
            .sheet(isPresented: $showManualSearch) { manualSearchSheet }
            .sheet(item: unknownCodeBinding) { code in
                ItemEditView(item: nil, prefilledBarcode: code.value)
            }
            .navigationDestination(item: $scannedItem) { item in
                ItemHistoryView(item: item)
            }
        }
    }

    private struct UnknownCode: Identifiable { let value: String; var id: String { value } }
    private var unknownCodeBinding: Binding<UnknownCode?> {
        Binding(get: { unknownCode.map(UnknownCode.init) }, set: { unknownCode = $0?.value })
    }

    @ViewBuilder
    private var cameraContent: some View {
        ZStack {
            ScannerCameraView(torchOn: torchOn, onCode: handleScannedCode)
                .accessibilityIdentifier("scanner.camera")
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 260, height: 160)
                    .accessibilityIdentifier("scanner.scanRegion")
                Spacer()
                HStack(spacing: 24) {
                    Button {
                        torchOn.toggle()
                    } label: {
                        Label("scanner.torch", systemImage: torchOn ? "bolt.fill" : "bolt.slash")
                    }
                    .accessibilityIdentifier("scanner.torch")

                    Button("scanner.manualSearch") { showManualSearch = true }
                        .accessibilityIdentifier("scanner.manualSearch")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 32)
            }
        }
    }

    private var deniedContent: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("scanner.denied.title", systemImage: "camera.fill",
                                   description: Text("scanner.denied.body"))
            Button("scanner.denied.openSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .accessibilityIdentifier("scanner.denied.openSettings")
            Button("scanner.manualSearch") { showManualSearch = true }
                .accessibilityIdentifier("scanner.denied.manualSearch")
        }
        .accessibilityIdentifier("scanner.denied")
    }

    private var manualSearchSheet: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    Button {
                        showManualSearch = false
                        scannedItem = item
                    } label: {
                        Text(item.name)
                    }
                    .accessibilityIdentifier("scanner.manualSearch.row.\(item.name)")
                }
            }
            .searchable(text: $manualSearchText, prompt: Text("priceBook.search"))
            .navigationTitle("scanner.manualSearch")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { showManualSearch = false }
                }
            }
        }
    }

    private var filteredItems: [Item] {
        guard !manualSearchText.trimmingCharacters(in: .whitespaces).isEmpty else { return allItems }
        let needle = manualSearchText.lowercased()
        return allItems.filter { $0.name.lowercased().contains(needle) || $0.brand.lowercased().contains(needle) }
    }

    private func requestAccess() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = granted ? .authorized : .denied
    }

    private func handleScannedCode(_ code: String) {
        if let match = allItems.first(where: { $0.barcode == code }) {
            scannedItem = match
        } else {
            unknownCode = code
        }
    }
}

/// A thin AVFoundation capture session wrapped for SwiftUI. Recognises the
/// four symbologies the spec names: EAN-8, EAN-13, UPC-E and Code128.
private struct ScannerCameraView: UIViewControllerRepresentable {
    let torchOn: Bool
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCode = onCode
        return controller
    }

    func updateUIViewController(_ controller: ScannerViewController, context: Context) {
        controller.setTorch(on: torchOn)
    }
}

private final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var hasReportedCode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [session] in session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        (view.layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = view.bounds
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasReportedCode,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        hasReportedCode = true
        onCode?(value)
    }
}

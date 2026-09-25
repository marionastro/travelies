//
//  CameraView.swift
//  mockup
//
//  Created by Studente on 19/08/24.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: CameraViewModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        return CameraViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context)
    {}
}

class CameraViewController: UIViewController {
    let viewModel: CameraViewModel
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let previewLayer = AVCaptureVideoPreviewLayer(session: viewModel.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = calculatePreviewLayerFrame()
        previewLayer.cornerRadius = 24.0
        view.layer.addSublayer(previewLayer)
        viewModel.startSession()
    }
    
    func createCGRect(withWidth width: CGFloat, aspectRatio: CGFloat = 4.0/3.0) -> CGRect {
        let height = width / aspectRatio
        return CGRect(x: 0, y: 0, width: width, height: height)
    }

    private func calculatePreviewLayerFrame() -> CGRect {
        let aspectRatio: CGFloat = 3.0 / 4.0
        let screenSize = view.bounds.size
        let screenAspectRatio = screenSize.width / screenSize.height
        
        var previewLayerFrame: CGRect
        
        if screenAspectRatio > aspectRatio {
            // Schermo più largo rispetto al rapporto 4:3
            let width   = screenSize.height * aspectRatio
            let xOffset = (screenSize.width - width) / 2.0
            previewLayerFrame = CGRect(x: xOffset, y: 0, width: width, height: screenSize.height)
        } else {
            // Schermo più stretto rispetto al rapporto 4:3
            let height  = screenSize.width / aspectRatio
            let yOffset = (screenSize.height - height) / 2.0
            previewLayerFrame = CGRect(x: 0, y: yOffset, width: screenSize.width, height: height)
        }
        
        return previewLayerFrame
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let previewLayer = view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = calculatePreviewLayerFrame()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        return
    }
}

struct Camera: View {
    @StateObject var viewModel = CameraViewModel()
    @State private var lastScaleValue: CGFloat = 1.0
    @State var buttonColor: Color = Color("CameraYellow")
    @State var selectedItems: [PhotosPickerItem] = []
    @State private var showUploader = false

    func resetSelection() {
        selectedItems.removeAll()
    }
    
    var body: some View {
        ZStack {
            VStack {
                VStack {
                    Button(action: { viewModel.toggleFlashMode() }) {
                        Image(systemName: viewModel.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.5), radius: 10, x: 0, y: 0)
                    .padding([.top, .bottom])
                    ZStack {
                        // Camera View
                        CameraView(viewModel: viewModel)
                            .edgesIgnoringSafeArea(.all)
                            .gesture(MagnificationGesture()
                                .onChanged { val in
                                    let delta = val / self.lastScaleValue
                                    self.lastScaleValue = val
                                    viewModel.zoom(factor: delta)
                                }
                                .onEnded { val in
                                    self.lastScaleValue = 1.0
                                }
                            )
                        VStack {
                            Spacer()
                            // Zoom Indicator
                            if viewModel.currentZoomFactor >= 1.1 {
                                VStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .frame(width: 32, height: 32)
                                            .foregroundColor(Color(UIColor.systemBackground))
                                            .opacity(0.5)
                                        Text(viewModel.approximateZoomFactor)
                                            .font(.custom("DIN Alternate", size: 13))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }.padding([.top, .bottom], 12)
                    }
                }
                .padding(24)
                Text(withAnimation { viewModel.isRecording ? secondsToHHMMSS(seconds: viewModel.recordedSeconds) : "MANTIENI PER REGISTRARE" })
                    .font(.custom("DIN Alternate", size: 13))
                    .foregroundColor(Color(UIColor.systemGray))
                ZStack {
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                            buttonColor = Color("CameraYellow")
                        } else {
                            viewModel.capturePhoto()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .frame(width: 75, height: 75)
                                .foregroundColor(.white)
                            Circle()
                                .frame(width: 65, height: 65)
                                .foregroundColor(.black)
                            Circle()
                                .frame(width: 55, height: 55)
                                .foregroundColor(buttonColor)
                        }
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                        withAnimation {
                            buttonColor = Color("CameraRed")
                        }
                        
                        viewModel.startRecording()
                    })
                    .buttonStyle(CameraButton())
                    HStack {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .any(of: [.images, .videos]), photoLibrary: .shared()) {
                            Image(systemName: "photo.stack")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .semibold))
                        }
                        .onChange(of: selectedItems) {
                            handlePhotosPickerSelection(selectedItems)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .semibold))
                        }
                    }
                    .padding([.leading, .trailing], 64)
                }
                .padding([.top], 32)
                .padding([.bottom], 64)
            }
            .background(.black)
            .edgesIgnoringSafeArea([.bottom])
            .onAppear {
                viewModel.resumeSessionIfNeeded()
                selectedItems.removeAll()
            }
            .fullScreenCover(isPresented: $showUploader) {
                Uploader(media: viewModel.media)
                    .onDisappear {
                        viewModel.clearCapturedMedia()
                    }
            }
            // Disable animation
            .transaction({ transaction in
                transaction.disablesAnimations = true
            })
        }
        .onChange(of: viewModel.media) {
            if viewModel.media != nil {
                showUploader = true
            }
        }
        .onChange(of: selectedItems) {
            handlePhotosPickerSelection(selectedItems)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
    }
    
    private func handlePhotosPickerSelection(_ items: [PhotosPickerItem]) {
        guard let item = items.first else {
            return
        }
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let image = try? TImage(withData: data)
                    
                    if let image = image {
                        viewModel.media = TMedia(image: image, origin: .library)
                    } else {
                        let tempDirectory = FileManager.default.temporaryDirectory
                        let videoFileName = UUID().uuidString + ".mov"
                        let videoUrl = tempDirectory.appendingPathComponent(videoFileName)
                        try data.write(to: videoUrl)
                        viewModel.media = TMedia(video: try TVideo(withURL: videoUrl), origin: .library)
                    }

                    resetSelection()
                }
            } catch {
                print("Failed to load item: \(error)")
            }
        }
    }
    
    func secondsToHHMMSS(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var rotationAngle: Double = -30
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var textColor: Color = .gray
    @State private var backgroundColor: Color = .black.opacity(0.7)
    @State private var loadedImage: UIImage?
    
    var body: some View {
        
        NavigationView {
                   ZStack {
                       backgroundLayer
                       mainContentLayer
                   }
                   .navigationTitle("Vinyl").foregroundColor(textColor)
                   .padding()
               }
    }

    private var backgroundLayer: some View {
        GeometryReader { geo in
            if let loadedImage = loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 20)
                    .scaleEffect(1.2)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
//                        analyzeImageBrightness(image: loadedImage)
                    }
                    .background(backgroundColor)
            } else {
                AsyncImage(url: viewModel.currentItem?.artworkURL) { image in
                    image.image?.resizable().scaledToFit()
                }
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .blur(radius: 20)
                .scaleEffect(1.2)
                .edgesIgnoringSafeArea(.all)
            }
         
        }
    }

    private var mainContentLayer: some View {
        Group {
            if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                // Vertical Layout
                VStack {
                    vinylAndArm
                    Text(String(viewModel.currentItem?.artist ?? "No artist found")).foregroundColor(textColor)
                    Spacer()
                    actionButton
                }
            } else {
                // Horizontal Layout
                HStack {
                    vinylAndArm
                    Spacer()
                    Text(String(viewModel.currentItem?.artist ?? "No artist found")).foregroundColor(textColor)
                    actionButton
                }
            }
        }
    }

    private var vinylAndArm: some View {
        ZStack {
            AsyncImage(url: viewModel.currentItem?.artworkURL) { image in
                image.image?.resizable().scaledToFit()
            }
//            Image("lauryn")
            .scaledToFit()
            .scaleEffect(0.5)
            .spinning()

            Image("disc")
            .resizable()
            .scaledToFill()
            .frame(width: 280, height: 280)
//            .background(Color.red)
            .spinning()
                
                Image("arm")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 150)
//                    .background(Color.green)
                    .rotationEffect(.degrees(rotationAngle), anchor: .topTrailing)
                    .offset(x: 90, y: -60)
        }
        .frame(width: 300, height: 300, alignment: .center)
//        .offset(x: -10, y: 0)
//        .background(Color.yellow)
    }

    private var actionButton: some View {
        Group {
            if viewModel.shazaming {
                Button("Stop Shazaming") {
                    viewModel.stopRecognition()
                    withAnimation {
                        removeArm()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button("Start Shazaming") {
                    viewModel.startRecognition()
                    withAnimation {
                        placeArm()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    func placeArm() -> Void {
        rotationAngle += 15
    }
    
    func removeArm() -> Void {
        rotationAngle -= 15
    }
    
    func estimateAverageBrightness(of image: UIImage) -> CGFloat {
        let size = CGSize(width: 50, height: 50) // Resize to 50x50
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = resizedImage?.cgImage else { return 0.5 }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var bitmapData = Data(count: width * height)
        bitmapData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(data: ptr.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: 0) else { return }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        let totalPixels = width * height
        let pixelArray = Array(bitmapData)

        let totalBrightness = pixelArray.reduce(0) { $0 + Int($1) }
        return CGFloat(totalBrightness) / CGFloat(totalPixels) / 255.0
    }
    
    private func analyzeImageBrightness(image: UIImage) {
        let brightness = estimateAverageBrightness(of: image)
        textColor = brightness < 0.5 ? .white : .black
        backgroundColor = brightness < 0.5 ? Color.black.opacity(0.7) : Color.white.opacity(0.7)
    }
}

struct Spinning: ViewModifier {
    @State private var isSpinning = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: isSpinning ? 360 : 0))
            .animation(Animation.linear(duration: 3).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear {
                self.isSpinning = true
            }
    }
}

extension View {
    func spinning() -> some View {
        self.modifier(Spinning())
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// FROM CHATGPT You can easily convert a UIImage to a SwiftUI Image using Image(uiImage: myUIImage). This conversion is handy when you need to use both UIKit and SwiftUI in the same app.

struct AsyncImageLoader: View {
    let url: URL?
    @Binding var loadedImage: UIImage?

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                Image(uiImage: image)
                    .resizable()
                    .onAppear {
                        self.loadedImage = image
                    }
            } else {
                // Placeholder or Progress View
                Color.gray
            }
        }
    }
}

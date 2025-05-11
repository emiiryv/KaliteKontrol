import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var predictionResult: String = "Sonuç burada görünecek"
    @State private var predictionColor: Color = .gray
    @State private var isLoading: Bool = false
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showActionSheet = false
    @State private var showHistory = false
    @State private var showLiveMonitoring = false
    @State private var showMenu = false

    let filterOptions = ["Tümü", "Çatlama", "Kapsama", "Yamalar", "Çukur Yüzey", "Hadde Kabukları", "Çizikler"]
    @State private var predictionHistory: [HistoryEntry] = []

    let classNames = ["Çatlama", "Kapsama", "Yamalar", "Çukur Yüzey", "Hadde Kabukları", "Çizikler"]

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                showMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("Kalite Kontrol")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    if isLoading {
                        ProgressView("Tahmin ediliyor...")
                            .padding()
                            .foregroundColor(.white)
                    } else {
                        Text(predictionResult)
                            .font(.headline)
                            .foregroundColor(predictionColor)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                    }

                    HStack {
                        Button(action: {
                            showActionSheet = true
                        }) {
                            Text("Görsel Ekle")
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            if let image = selectedImage {
                                predictImage(image: image)
                            }
                        }) {
                            Text("Tahmin Et")
                                .fontWeight(.bold)
                                .padding()
                                .background(selectedImage == nil ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(selectedImage == nil)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                
                // Sidebar Menu (Slide-In)
                if showMenu {
                    ZStack(alignment: .leading) {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showMenu = false
                                }
                            }
                        
                        VStack(alignment: .leading, spacing: 25) {
                            HStack {
                                Text("Kalite Kontrol")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                Spacer()
                                Button(action: {
                                    showMenu = false
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .padding(.trailing, 15)
                                .padding(.top, 10)
                            }
                            .padding(.top, 40)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                Button(action: {
                                    showLiveMonitoring = true
                                    showMenu = false
                                }) {
                                    HStack {
                                        Image(systemName: "eye")
                                        Text("Canlı İzleme")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    showHistory = true
                                    showMenu = false
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                        Text("Sonuç Geçmişi")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.leading, 20)
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                        .frame(width: 250)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                        .shadow(radius: 10)
                    }
                    .transition(.move(edge: .leading))
                    .zIndex(1)
                }
            }
            .sheet(isPresented: $showLiveMonitoring) {
                LiveMonitoringView()
            }
            .sheet(isPresented: $showHistory) {
                PredictionHistoryView(history: $predictionHistory)
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(title: Text("Görsel Seç"), buttons: [
                    .default(Text("Kamera")) { showCameraPicker = true },
                    .default(Text("Galeri")) { showImagePicker = true },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(image: $selectedImage)
            }
            .onAppear {
                loadHistory()
            }
        }
    }

    func predictImage(image: UIImage) {
        isLoading = true
        predictionResult = "Tahmin ediliyor..."
        predictionColor = .gray
        
        NetworkManager.shared.predictImage(image: image) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                let components = result.split(separator: "-")
                if components.count == 2,
                   let classIndex = Int(components[0].trimmingCharacters(in: .whitespaces)),
                   let confidence = Double(components[1].trimmingCharacters(in: .whitespaces)) {
                    
                    let className = classIndex < classNames.count ? classNames[classIndex] : "Bilinmeyen"
                    
                    self.predictionResult = "Sınıf: \(className)\nGüven: \(String(format: "%.2f", confidence * 100))%"
                    self.predictionColor = confidence >= 0.8 ? .green : (confidence >= 0.5 ? .yellow : .red)
                    
                    // Sonuç Geçmişine Kaydet
                    let newEntry = HistoryEntry.create(from: image, result: self.predictionResult, confidence: confidence, color: self.predictionColor, timestamp: Date())
                    self.predictionHistory.append(newEntry)
                    self.saveHistory()
                } else {
                    self.predictionResult = "Hata: Tahmin Sonucu Alınamadı"
                    self.predictionColor = .red
                }
            }
        }
    }

    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "predictionHistory"),
           let loadedHistory = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            self.predictionHistory = loadedHistory
        }
    }
    
    func saveHistory() {
        if let data = try? JSONEncoder().encode(predictionHistory) {
            UserDefaults.standard.set(data, forKey: "predictionHistory")
        }
    }
}

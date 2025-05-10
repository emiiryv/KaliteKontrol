import SwiftUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var predictionResult: String = "Sonuç burada görünecek"
    @State private var predictionColor: Color = .gray
    @State private var isLoading: Bool = false
    @State private var showImagePicker = false
    @State private var showHistory = false
    @State private var selectedFilter: String = "Tümü" // Geçmişi filtrelemek için
    let filterOptions = ["Tümü", "Çatlama", "Kapsama", "Yamalar", "Çukur Yüzey", "Hadde Kabukları", "Çizikler"]
    
    // Sonuç Geçmişi Dizisi
    @State private var predictionHistory: [HistoryEntry] = []
    
    let classNames = [
        "Çatlama",            // 0 - Crazing
        "Kapsama",            // 1 - Inclusion
        "Yamalar",            // 2 - Patches
        "Çukur Yüzey",        // 3 - Pitted Surface
        "Hadde Kabukları",    // 4 - Rolled-in Scale
        "Çizikler"            // 5 - Scratches
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Kalite Kontrol Modeli")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
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
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if isLoading {
                    ProgressView("Tahmin ediliyor...")
                        .padding()
                        .foregroundColor(.white)
                } else {
                    Text(predictionResult)
                        .font(.headline)
                        .foregroundColor(predictionColor)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                HStack {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text("Görsel Seç")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
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
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedImage == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(selectedImage == nil)
                }
                .padding(.horizontal)
                
                // Geçmişi Görüntüle Butonu
                Button("Sonuç Geçmişi") {
                    showHistory = true
                }
                .padding()
                .foregroundColor(.blue)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .sheet(isPresented: $showHistory) {
                    PredictionHistoryView(history: $predictionHistory)
                }
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Kalite Kontrol")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
        .onAppear {
            loadHistory()
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
                if components.count == 2 {
                    let classIndex = Int(components[0].trimmingCharacters(in: .whitespaces)) ?? 0
                    let confidence = Double(components[1].trimmingCharacters(in: .whitespaces)) ?? 0.0
                    let className = classIndex < classNames.count ? classNames[classIndex] : "Bilinmeyen"
                    
                    self.predictionResult = "Sınıf: \(className)\nGüven: \(String(format: "%.2f", confidence * 100))%"
                    self.predictionColor = confidence >= 0.8 ? .green : (confidence >= 0.5 ? .yellow : .red)
                    
                    // Sonuç Geçmişine Kaydet
                    let newEntry = HistoryEntry.create(
                        from: image,
                        result: className,
                        confidence: confidence,
                        color: self.predictionColor,
                        timestamp: Date()
                    )
                    self.predictionHistory.append(newEntry)
                    self.saveHistory()
                } else {
                    self.predictionResult = "Hata: Sonuç alınamadı"
                    self.predictionColor = .red
                }
            }
        }
    }
    
    func saveHistory() {
        if let data = try? JSONEncoder().encode(predictionHistory) {
            UserDefaults.standard.set(data, forKey: "predictionHistory")
        }
    }

    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "predictionHistory"),
           let loadedHistory = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            self.predictionHistory = loadedHistory
        }
    }
}

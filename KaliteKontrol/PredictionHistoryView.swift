import SwiftUI

// UIImage yerine Base64 String kullanıyoruz
// HistoryEntry Modelini Güncelle
struct HistoryEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let imageData: String // Base64 encoded image
    let result: String
    let confidence: Double // Güven değeri
    let colorHex: String // Hex format of Color
    let timestamp: Date

    // UIImage'den Base64'e dönüştürme
    static func create(from image: UIImage, result: String, confidence: Double, color: Color, timestamp: Date) -> HistoryEntry {
        let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? ""
        let colorHex = color.toHex() // Renk kodunu kaydediyoruz
        return HistoryEntry(id: UUID(), imageData: imageData, result: result, confidence: confidence, colorHex: colorHex, timestamp: timestamp)
    }

    // Base64'ten UIImage'a dönüştürme
    func getImage() -> UIImage? {
        guard let data = Data(base64Encoded: imageData) else { return nil }
        return UIImage(data: data)
    }

    // Hex kodundan Color'a dönüştürme
    func getColor() -> Color {
        Color(hex: colorHex) ?? .gray
    }
}
// Color uzantısı (Hex'e dönüştürme ve geri yükleme)
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
    }
    
    init?(hex: String) {
        let r, g, b: CGFloat
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                self = Color(red: r, green: g, blue: b)
                return
            }
        }
        return nil
    }
}

struct PredictionHistoryView: View {
    @Binding var history: [HistoryEntry]
    @State private var sortDescending: Bool = true
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Tümü"
    let filterOptions = ["Tümü", "Çatlama", "Kapsama", "Yamalar", "Çukur Yüzey", "Hadde Kabukları", "Çizikler"]

    var filteredHistory: [HistoryEntry] {
        let sortedHistory = history.sorted {
            sortDescending ? $0.timestamp > $1.timestamp : $0.timestamp < $1.timestamp
        }
        let searchedHistory = searchText.isEmpty ? sortedHistory : sortedHistory.filter {
            $0.result.localizedCaseInsensitiveContains(searchText)
        }
        if selectedFilter == "Tümü" {
            return searchedHistory
        } else {
            return searchedHistory.filter { $0.result.contains(selectedFilter) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Sonuç Ara...", text: $searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Button(action: {
                        sortDescending.toggle()
                    }) {
                        Image(systemName: sortDescending ? "arrow.down" : "arrow.up")
                    }
                }
                .padding()

                Picker("Kategori:", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                List {
                    ForEach(filteredHistory, id: \.id) { entry in
                        HStack {
                            if let image = entry.getImage() {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(10)
                            }

                            VStack(alignment: .leading) {
                                Text(entry.result)
                                    .font(.headline)
                                    .foregroundColor(entry.getColor())
                                Text("Güven: \(String(format: "%.2f", entry.confidence * 100))%") // Güven bilgisi
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(entry.timestamp, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteHistory)
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Sonuç Geçmişi")
            .toolbar {
                Button("Temizle") {
                    history.removeAll()
                    saveHistory()
                }
            }
        }
        .onAppear {
            loadHistory()
        }
    }

    private func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "predictionHistory")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "predictionHistory"),
           let loadedHistory = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = loadedHistory
        }
    }
}

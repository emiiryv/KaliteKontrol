import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func predictImage(image: UIImage, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "http://192.168.1.4:8000/predict/") else {
            DispatchQueue.main.async {
                completion("Hata: Geçersiz URL")
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = image.jpegData(compressionQuality: 0.8)!
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion("Hata: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion("Hata: Veri Yok")
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let prediction = json?["prediction"] as? [[Any]] {
                    print("Prediction Array:", prediction)
                    let predictedValues = prediction.first?.compactMap { value -> Double? in
                        if let stringValue = value as? String {
                            return Double(stringValue)
                        } else if let doubleValue = value as? Double {
                            return doubleValue
                        } else {
                            return nil
                        }
                    }
                    
                    guard let values = predictedValues, !values.isEmpty else {
                        DispatchQueue.main.async {
                            completion("Hata: Tahminler Boş")
                        }
                        return
                    }
                    
                    let highestValue = values.max() ?? 0.0
                    let index = values.firstIndex(of: highestValue) ?? 0
                    DispatchQueue.main.async {
                        completion("\(index) - \(highestValue)")
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion("Hata: Yanıt Beklenen Format Değil")
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Hata: JSON Okunamadı - \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

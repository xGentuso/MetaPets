import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
    let joinDate: Date
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinDate)
    }
} 
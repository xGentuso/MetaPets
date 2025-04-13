//
//  NotificationManager.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermissions() async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus != .authorized else { return }
            
            try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
    
    // Schedule a pet need notification
    func schedulePetNeedNotification(for need: PetNeed, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Your Pet Needs You!"
        content.body = "Your pet needs \(need.description)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Schedule a daily bonus reminder
    func scheduleDailyBonusReminder(at hour: Int = 20) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Bonus Available!"
        content.body = "Your streak reward is ready to claim. Don't miss out!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_BONUS"
        
        // Create date components for the trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour // Default to 8 PM
        dateComponents.minute = 0
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "dailyBonus", 
                                            content: content, 
                                            trigger: trigger)
        
        // Add the request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily bonus notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled daily bonus notification")
            }
        }
    }
    
    // Schedule notifications based on pet state
    func scheduleNotificationsBasedOnPetState(pet: Pet) {
        // Clear any existing notifications
        cancelAllNotifications()
        
        // Schedule notifications based on pet state
        if pet.hunger < 30 {
            schedulePetNeedNotification(for: .hunger, timeInterval: 3600)
        }
        
        if pet.happiness < 30 {
            schedulePetNeedNotification(for: .happiness, timeInterval: 3600)
        }
        
        if pet.cleanliness < 30 {
            schedulePetNeedNotification(for: .cleanliness, timeInterval: 3600)
        }
        
        // Schedule daily bonus reminder if not already claimed today
        scheduleDailyBonusReminder()
    }
    
    // Cancel all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// Pet needs enum
enum PetNeed {
    case hunger, happiness, health, cleanliness
    
    var description: String {
        switch self {
        case .hunger: return "food"
        case .happiness: return "attention"
        case .health: return "medicine"
        case .cleanliness: return "cleaning"
        }
    }
}

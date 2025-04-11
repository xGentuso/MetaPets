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
    
    // Request notification permissions
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // Schedule a pet need notification
    func schedulePetNeedNotification(for need: PetNeed, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Your pet needs attention!"
        content.body = notificationMessage(for: need)
        content.sound = .default
        content.categoryIdentifier = "PET_NEED"
        
        // Add action button
        let actionIdentifier = "VIEW_PET"
        let action = UNNotificationAction(identifier: actionIdentifier, title: "Check Pet", options: .foreground)
        let category = UNNotificationCategory(identifier: "PET_NEED", actions: [action], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        // Trigger after the specified time interval
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // Create the request with a unique identifier
        let request = UNNotificationRequest(identifier: "\(need.rawValue)_\(Date().timeIntervalSince1970)", 
                                            content: content, 
                                            trigger: trigger)
        
        // Add the request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled notification for \(need.rawValue)")
            }
        }
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
        
        // Check hunger levels
        if pet.hunger < 50 {
            let timeToEmpty = (pet.hunger / 5) * 3600 // Rough estimate: each hunger point lasts ~3600 seconds
            schedulePetNeedNotification(for: .hunger, timeInterval: timeToEmpty)
        }
        
        // Check energy levels
        if pet.energy < 40 {
            let timeToExhaustion = (pet.energy / 4) * 3600
            schedulePetNeedNotification(for: .energy, timeInterval: timeToExhaustion)
        }
        
        // Check cleanliness
        if pet.cleanliness < 40 {
            let timeToDirty = (pet.cleanliness / 2) * 3600
            schedulePetNeedNotification(for: .cleanliness, timeInterval: timeToDirty)
        }
        
        // Check happiness
        if pet.happiness < 40 {
            let timeToSad = (pet.happiness / 3) * 3600
            schedulePetNeedNotification(for: .happiness, timeInterval: timeToSad)
        }
        
        // Schedule daily bonus reminder if not already claimed today
        scheduleDailyBonusReminder()
    }
    
    // Cancel all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Generate notification message based on need
    private func notificationMessage(for need: PetNeed) -> String {
        switch need {
        case .hunger:
            return "Your pet is getting hungry! Time for a snack."
        case .energy:
            return "Your pet is tired. Let it get some rest."
        case .cleanliness:
            return "Your pet needs a bath. It's getting dirty!"
        case .happiness:
            return "Your pet is feeling lonely. Play with it!"
        case .health:
            return "Your pet isn't feeling well. Some medicine might help."
        }
    }
}

// Pet needs enum
enum PetNeed: String {
    case hunger
    case energy
    case cleanliness
    case happiness
    case health
}

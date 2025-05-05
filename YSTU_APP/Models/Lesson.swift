//
//  Lesson.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 24.09.2024.
//

import UIKit


struct LessonsResponse: Codable {
    let isCache: Bool?
    let items: [Item]
}

// Структура для "items"
struct Item: Codable {
    let number: Int?
    let days: [Day]
}

// Структура для days
struct Day: Codable {
    let info: Info
    let lessons: [Lesson]
}

// Структура для info
struct Info: Codable {
    let type: Int?
    let weekNumber: Int?
    let date: String?
    
    public func formDateFromString() -> Date? {
        guard let dateString = date, !dateString.isEmpty else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter.date(from: dateString)
    }
}

// Структура для lessons
struct Lesson: Codable {
    let number: Int?
    let startAt: String? // TODO: заменить на Date()
    let endAt: String? // TODO: заменить на Date()
    let timeRange: String?
    let originalTimeTitle: String?
    let parity: Int?
    let lessonName: String?
    let type: Int?
    let isStream: Bool?
    let duration: Int?
    let durationMinutes: Int?
    let isDivision: Bool?
    let teacherName: String?
    let teacherId: Int?
    let auditoryName: String?
    let isDistant: Bool?
    let isShort: Bool?
    let isLecture: Bool?
}

/*
 {
auditoryName = "\U0412-209";
duration = 2;
durationMinutes = 90;
endAt = "2024-02-05T07:00:00.000Z";
isDistant = 0;
isDivision = 0;
isLecture = 1;
isShort = 0;
isStream = 1;
lessonName = "\U042d\U043b\U0435\U043a\U0442\U0440\U043e\U043d\U0438\U043a\U0430 \U0438 \U0441\U0445\U0435\U043c\U043e\U0442\U0435\U0445\U043d\U0438\U043a\U0430 (\U0418\U0421\U0418\U0422)";
number = 1;
originalTimeTitle = "1. 08:30-10:00";
parity = 1;
startAt = "2024-02-05T05:30:00.000Z";
teacherId = 1115;
teacherName = "\U0441\U0442.\U043f\U0440\U0435\U043f. \U0412\U043e\U0440\U043e\U043d\U0438\U043d \U041c\U0411";
timeRange = "08:30-10:00";
type = 2;
}
 */

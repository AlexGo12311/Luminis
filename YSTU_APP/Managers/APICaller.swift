//
//  APICaller.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 23.09.2024.
//


import Foundation

struct Constants {
    static let API_KEY = "ЦПИ-11"
    static let baseURL = "https://gg-api.ystuty.ru/s"
}

enum APIError: Error {
    case failedToGetData
}

class APICaller {
    static let shared = APICaller()
    
    func getSchedule(for date: Date, completion: @escaping (Result<[Lesson], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/schedule/v1/schedule/group/\(Constants.API_KEY)") else {
            completion(.failure(APIError.failedToGetData))
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(.failure(APIError.failedToGetData))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            } else {
                print("Failed to convert data to string")
            }
            
            do {
                let results = try JSONDecoder().decode(LessonsResponse.self, from: data)
                print("Received \(results.items.count) items from API")
                
                // Фильтруем данные для выбранного дня
                let selectedDayLessons = self.filterLessons(for: date, from: results.items)
                
                completion(.success(selectedDayLessons))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func filterLessons(for date: Date, from items: [Item]) -> [Lesson] {
        let calendar = Calendar.current
        var lessonsForSelectedDay: [Lesson] = []
        
        for item in items {
            for day in item.days {
                // Преобразуем строку даты в объект Date
                if let dayDate = day.info.formDateFromString() {
                    if calendar.isDate(dayDate, inSameDayAs: date) {
                        lessonsForSelectedDay.append(contentsOf: day.lessons)
                    }
                } else {
                    print("Failed to parse date: \(day.info.date ?? "nil")")
                }
            }
        }
        
        print("Filtered \(lessonsForSelectedDay.count) lessons for date: \(date)")
        return lessonsForSelectedDay
    }
    
    func getGroupsList(completion: @escaping (Result<[GroupSection], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/schedule/v1/schedule/actual_groups?additional=false") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let results = try JSONDecoder().decode(GroupsListResponse.self, from: data)
                let sections = results.items.compactMap { item -> GroupSection? in
                    guard let name = item.name, let groups = item.groups else { return nil }
                    return GroupSection(title: name, groups: groups)
                }
                completion(.success(sections))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

}

    

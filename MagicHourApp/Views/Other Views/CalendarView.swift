//
//  CalendarView.swift
//  CallsheetApp
//
//  Created by Lauri-Matti Parppei on 30.9.2024.
//

import SwiftUI

struct CalendarView: View {
    @State var importing = false
    @State var showSheetlist = false
    
    @Binding var selectedDay:Date
    @ObservedObject var callSheetManager:CallSheetManager = CallSheetManager.shared

    @State private var currentMonth:Date
    private var onSelection:(Date) -> Void = { _ in }
    
    private let calendar = Calendar(identifier: .gregorian)

    init(selectedDay: Binding<Date>, showSheetlist:Bool = false, onSelection: @escaping (Date) -> Void = { _ in }) {
        self._selectedDay = selectedDay
        self.onSelection = onSelection
        self.showSheetlist = showSheetlist
        
        currentMonth = selectedDay.wrappedValue
    }

    var body: some View {
        VStack {
            // Month and Year Header with Previous/Next buttons
            HStack {
                Button(action: {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                }) {
                    Image(systemName: "chevron.left")
                }
                .background(.clear)
                
                Spacer()
                
                Text(monthAndYearString(for: currentMonth))
                    .font(.title2)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                }) {
                    Image(systemName: "chevron.right")
                }
                .background(.clear)
            }

            // Weekday header (Mon, Tue, etc.)
            HStack {
                ForEach(weekdays(for: currentMonth), id: \.self) { weekday in
                    Text(weekday)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.secondary)
                }
            }

            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(generateDays(for: currentMonth), id: \.self) { day in
                    Button(action: {
                        onSelection(day)
                    }) {
                        DayCell(day: day, selectedDay: $selectedDay, isHighlighted: hasCallSheet(on: day))
                    }
                    .background(.clear)
                    .buttonStyle(.plain)
                    .underline(false)
                }
            }
        }
        .padding()
        
        if showSheetlist {
            CallSheetList(selectedDay: $selectedDay, callSheetManager: CallSheetManager.shared, onSelection: onSelection)
        }
    }
    
    // Helper to get all days in the selected month (including leading/trailing days)
    func generateDays(for date: Date) -> [Date] {
        var days: [Date] = []
        
        // Get the first day of the month
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return days }
        
        // Calculate how many days we need to show from the previous month (adjusting for Monday start)
        let firstWeekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7 + 1 // Make Monday the first day (1)
        let daysInPreviousMonth = firstWeekday - 1
        
        // Calculate the start date for the calendar (might be in the previous month)
        guard let calendarStart = calendar.date(byAdding: .day, value: -daysInPreviousMonth, to: firstOfMonth) else { return days }
        
        // Calculate how many days to show (6 weeks grid)
        let totalDays = 42  // 7 days * 6 weeks = 42 days

        // Generate each day to display
        for dayOffset in 0..<totalDays {
            if let day = calendar.date(byAdding: .day, value: dayOffset, to: calendarStart) {
                days.append(day)
            }
        }
        
        return days
    }

    // Helper to check if a specific day has a call sheet
    func hasCallSheet(on day: Date) -> Bool {
        let dayString = dayFormatter.string(from: day)
        return callSheetManager.callSheets.keys.contains(dayString)
    }

    // Get the full month and year string for header
    func monthAndYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // Get the localized weekday abbreviations (e.g., "Mon", "Tue")
    func weekdays(for date: Date) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"
        return Array(formatter.shortWeekdaySymbols.dropFirst(1)) + [formatter.shortWeekdaySymbols.first!] // Reorder for Monday start
    }
}

struct DayCell: View {
    let day: Date
    @Binding var selectedDay: Date
    let isHighlighted: Bool
    
    private let calendar = Calendar(identifier: .gregorian)
    private let dateFormatter = DateFormatter()

    init(day: Date, selectedDay: Binding<Date>, isHighlighted: Bool) {
        self.day = day
        self._selectedDay = selectedDay
        self.isHighlighted = isHighlighted
        dateFormatter.dateFormat = "d"
    }

    var body: some View {
        Text(dateFormatter.string(from: day))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            .background(isSelected() ? Color.blue : (isHighlighted ? Color.green.opacity(0.3) : Color.clear))
            .cornerRadius(8)
            .foregroundColor(isInCurrentMonth() ? Color.primary : Color.secondary.opacity(0.5))
            .controlSize(.small)
    }
    
    // Check if the current day is the selected day
    func isSelected() -> Bool {
        return calendar.isDate(day, inSameDayAs: selectedDay)
    }
    
    // Check if the day is in the current month
    func isInCurrentMonth() -> Bool {
        return calendar.isDate(day, equalTo: selectedDay, toGranularity: .month)
    }
}

struct CallSheetList:View {
    @Binding var selectedDay:Date
    //@Binding var callSheets:[String: CallSheet]
    @ObservedObject var callSheetManager:CallSheetManager = CallSheetManager.shared
    var onSelection:(Date) -> Void = { _ in }
    
    var body:some View {
        TabView {
            // Show days that have a call sheet
            List(callSheetManager.callSheets.keys.sorted(), id: \.self) { day in
                if let thisDay = dayFormatter.date(from: dayFormatter.string(from: Date())),
                   let date = dayFormatter.date(from: day),
                   date >= thisDay {
                    // Format the title
                    let dayStr = mediumDateFromISODate(day)
                    Text(dayStr)
                        .onTapGesture {
                            if let d = dayFormatter.date(from: day) {
                                onSelection(d)
                            }
                        }
                }
            }
            .tabItem {
                Image(systemName: "calendar.badge.clock")
                Text("Upcoming")
            }
            
            // Show days that have a call sheet
            List(callSheetManager.callSheets.keys.sorted(), id: \.self) { day in
                // Format the title
                let dayStr = mediumDateFromISODate(day)
                Text(dayStr)
                    .onTapGesture {
                        if let d = dayFormatter.date(from: day) {
                            onSelection(d)
                        }
                    }
            }
            .tabItem {
                Image(systemName: "calendar.circle.fill")
                Text("All")
            }
        }
    }
}


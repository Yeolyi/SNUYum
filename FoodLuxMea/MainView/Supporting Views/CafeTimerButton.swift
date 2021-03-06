//
//  Alami.swift
//  FoodLuxMea
//
//  Created by Seong Yeol Yi on 2020/08/30.
//

import SwiftUI

/// Shows remaining cafe operating hours.
///
/// - Note: Must use suggestedDate and suggestedMeal propery of SettingManager, because Timer always based on suggested
/// time and meal.
struct CafeTimer: View {
    
    let cafe: Cafe
    /// Determines to show sheet on tap or not.
    let isInMainView: Bool
    @State var isCafeViewSheet = false
    @Binding var selectedCafe: Cafe?
    
    @EnvironmentObject var listManager: CafeList
    @EnvironmentObject var dataManager: Cafeteria
    @EnvironmentObject var settingManager: UserSetting
    let themeColor = ThemeColor()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // If view is in mainview, show sheet.
        Button(action: {
            isCafeViewSheet = isInMainView
            withAnimation {
                selectedCafe = cafe
            }
        }) {
            VStack {
                HStack {
                    Text(isInMainView ? "\(cafe.name) 운영정보" : "운영정보")
                        .accentedText()
                        .foregroundColor(themeColor.title(colorScheme))
                        .padding(.bottom, 1.5)
                    Spacer()
                }
                HStack {
                    Text(remainingTimeNotice())
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .rowBackground()
        }
    }
    
    func remainingTimeNotice() -> String {
        
        // Get current setting time component.
        let currentSimpleTime = SimpleTime(date: settingManager.date)
        
        var dayOfTheWeek: String {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko")
            dateFormatter.dateFormat = "EEEE"
            return dateFormatter.string(from: settingManager.date)
        }
        
        // When cafe operating hour data exists
        if let endDate =
            cafeOperatingHour[cafe.name]?.daily(
                at: settingManager.date)?.endTime(at: settingManager.suggestedMeal) {
            // If menu exists in next meal.
            if !cafe.isEmpty(at: [settingManager.suggestedMeal], emptyKeywords: closedKeywords) {
                // Force unwrap is available becaufe startDate and endDate are always together.
                let startTime = cafeOperatingHour[cafe.name]!.daily(at: settingManager.date)!
                    .startTime(at: settingManager.suggestedMeal)!
                if currentSimpleTime.hour < 5 || currentSimpleTime.hour > endDate.hour {
                    return "영업 종료🌙"
                } else if currentSimpleTime < startTime {
                    return
                        "\(settingManager.isSuggestedTomorrow ? "내일" : "오늘")" +
                    " \(settingManager.suggestedMeal.rawValue)밥 준비중!"
                } else {
                    let time = remainTime(from: SimpleTime(date: settingManager.date), to: endDate)
                    return "\(settingManager.suggestedMeal.rawValue) 마감까지 \(time.hour)시간 \(time.minute)분!"
                }
            // If menu not exists in next meal.
            } else {
                return "\(settingManager.suggestedMeal.rawValue) 메뉴가 없어요."
            }
        }
        // When cafe operating hour data not exists
        else {
            return "\(dayOfTheWeek) \(settingManager.suggestedMeal.rawValue)에는 운영하지 않아요."
        }
    }
    
    /// Calculate time difference of two arguments.
    func remainTime(from simpleDate1: SimpleTime, to simpleDate2: SimpleTime) -> SimpleTime {
        
        func getDate(from simpleDate: SimpleTime) -> Date {
            let userCalendar = Calendar.current
            var dateComponents = DateComponents() 
            dateComponents.hour = simpleDate.hour
            dateComponents.minute = simpleDate.minute
            return userCalendar.date(from: dateComponents) ?? settingManager.date
        }
        
        let date1 = getDate(from: simpleDate1)
        let date2 = getDate(from: simpleDate2)
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: date1, to: date2)
        // diffComponents variable is clearly valible. 
        return SimpleTime(hour: diffComponents.hour!, minute: diffComponents.minute!)
    }
}

struct CafeTimerText_Previews: PreviewProvider {
    static var previews: some View {
        CafeTimer(cafe: previewCafe, isInMainView: true, selectedCafe: .constant(nil))
            .environmentObject(Cafeteria())
            .environmentObject(UserSetting())
            .environmentObject(CafeList())
    }
}

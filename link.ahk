wday := FormatTime(, "WDay")
; 1 - sun
; 2 - mon
; 3 - tue
; 4 - wed
; 5 - thu
; 6 - fri
; 7 - sat
if(wday != 7 and wday != 1){
    if (wday = 2) {
        ; staffit
        ; Run "https://staffit.deloitteresources.com/WebUI/UserValidation?gw-client=200#/dashboard"
    } else if (wday = 6){
        ; myTime
        ; Run "https://mytime.thomsonreuters.com/mytime/WeeklyView.htm"
        Run "https://www.fieldglass.net/worker_desktop.do"

        ; DTE
        Run "https://uswasfdp.deloitte.com/sap/bc/ui5_ui5/sap/ztime_tge/index.html?actingAs=me#/"
    }


    ; Run "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
    ; Run "https://outlook.office.com/mail"
    ; Run "https://thomsonreuters.cloud.com/Citrix/StoreWeb/#/home"
}

; Run "https://leetcode.com/studyplan/top-interview-150/"

; Run "https://www.geeksforgeeks.org/problem-of-the-day"
; Run "C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2023.1.1\bin\idea64.exe"

; //https://sakshamsangal.github.io/resume/ach#jun-17-2024-monday
myDate := FormatTime(, "MMM-d-yyyy-dddd")
myDate := StrLower(myDate)
Run "https://sakshamsangal.github.io/resume/ach#" . myDate

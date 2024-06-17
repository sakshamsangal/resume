::hj::Hi John
;::wc::When can we connect for
; ::cr::, call regarding
; :*:cro::call for review of ?{left 1}
; :*:ss::$${left 1}
; :*:ff::f(){left 1}
; :*:gg::g(){left 1}
; :*:dd::"my description"
; :c*:ee::eDocumentId {{}

; :*:]d::  ; This hotstring replaces "]d" with the current date and time via the statement below.
; {
;     Send A_Now  ; It will look like 9/1/2005 3:53 PM
; }

:*:qq::  ; This hotstring replaces "]d" with the current date and time via the statement below.
{
    Send "Sample" . FormatTime(, "h_mm_ss")  ; It will look like 9/1/2005 3:53 PM
}

:*:]dd::  ; This hotstring replaces "]d" with the current date and time via the statement below.
{
    Send "{Raw}## " . FormatTime(, "MMM d, yyyy dddd h:mm") . "`n"  ; It will look like 9/1/2005 3:53 PM
}

 ;   Send FormatTime(, "M/d/yyyy h:mm tt")  ; It will look like 9/1/2005 3:53 PM

::]d::As a user I should be able to
:*:swc::Shall we connect?{space}
:*:cyp::Can you please{space}
:*:]lmc::Let me check{space}
:*:]ns::Not sure{space}
:*:rtp::Raised the PR.{space}
:*:dod::Deployed on DEV.{space}
:*:doq::Deployed on QA.{space}
:*:mtp::merge the PR


::]a::{
	SendInput " - Development team should be able to {enter}"
	SendInput " - There should be no sonar issues. {enter}"
	SendInput " - Add proper logs.  {enter}"
	SendInput " - Add JUnit test cases with proper code coverage. {enter}"
}

::]pr::{
	SendInput "{Raw}##"
	SendInput "Added in this PR {enter}"
	SendInput " - Developed code for. {enter}"
	SendInput "{Raw}##"
	SendInput "Testing {enter}"
	SendInput "- Added junit test cases. {enter}"
	SendInput "{Raw}##"
	SendInput "Impact {enter}"
	SendInput "{Raw}##"
	SendInput "Notes {enter}"
}


::]sbd::mkdir controller config service util\constant model persistence\entity persistence\repo




:*:]enh::enhancements
::]roll::git checkout -- .
::]lgtm::lgtm
::]gm::Good morning{!}
::]ga::Good afternoon{!}
::]ge::Good evening{!}
::]imp::Implementation



:*:iia::It is about
:*:]sc::--spring.config.location=C:/Users/c282465/Desktop/config/


::]kp::netstat -ano | findstr 8080`ntaskkill /F /PID


::616::{
	SendInput "delete from ar_documents`;{enter}"
	SendInput "delete from process_document_ar_history`;{enter}"
	SendInput "delete from process_document_ar_party`;{enter}"
	SendInput "delete from business_res_ar_reason_code`;{enter}"
	SendInput "delete from business_res_ar`;{enter}"
	SendInput "delete from clearance_res_ar_reason_code`;{enter}"
	SendInput "delete from clearance_res_ar`;{enter}"
	SendInput "delete from process_document_ar`;{enter}"
}
::616ap::{
	SendInput "delete from ap_documents`;{enter}"
	SendInput "delete from process_document_ap_history`;{enter}"
	SendInput "delete from process_document_ap_party`;{enter}"
	SendInput "delete from business_res_ap_reason_code`;{enter}"
	SendInput "delete from business_res_ap`;{enter}"
	SendInput "delete from clearance_res_ap_reason_code`;{enter}"
	SendInput "delete from clearance_res_ap`;{enter}"
	SendInput "delete from process_document_ap`;{enter}"
}

::77::{
	SendInput "delete record from pagero company if not found in reposne json of pagero company api for that particular user--instead of only processing one list size of onboardedLegalEntity we need to process those records for list size is greater than 1 but for the we will process only latest record(to process this we need to consider one more thing the VAT number we are getting in response is already exist in identifier table or not, if it's already exist with some other legal entity then we will process that legal entity and for which we update the createTime), this we are doing becuase if next time the entry again created in pageroCompany table"

}






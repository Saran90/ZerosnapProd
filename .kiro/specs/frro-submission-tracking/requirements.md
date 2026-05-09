# Requirements: FRRO Submission Tracking

## Introduction

This feature adds automatic detection of FRRO Form C submission outcomes within the existing WebView-based FRRO page. When the WebView navigates to a known submission confirmation URL, the app extracts the application ID (where available), calls the backend API to mark the guest as synced, provides user feedback via a snackbar, and refreshes the guest list.

---

## Requirements

### Requirement 1: Detect FRRO Submission URLs

**User Story**: As a hotel staff member, I want the app to automatically detect when I have successfully submitted a guest's FRRO form, so that I don't have to manually mark the guest as synced.

#### Acceptance Criteria

1.1. WHEN the WebView's `onPageFinished` callback fires with a URL containing `svnext.jsp`, THEN the app SHALL treat this as a successful "Temporary Save and Exit" submission.

1.2. WHEN the WebView's `onPageFinished` callback fires with a URL containing `/ext.jsp`, THEN the app SHALL treat this as a successful "Save and Continue" submission.

1.3. WHEN a submission URL is detected but no guest has been selected (`_selectedGuest` is null), THEN the app SHALL NOT dispatch any check-in event and SHALL NOT show any snackbar.

1.4. WHEN a submission URL is detected, THEN the app SHALL NOT execute the credential auto-fill or form auto-fill JavaScript scripts on that page.

---

### Requirement 2: Extract Application ID from Submission Page

**User Story**: As a hotel staff member, I want the application ID to be automatically captured from the FRRO confirmation page, so that the guest record is updated with the correct reference number.

#### Acceptance Criteria

2.1. WHEN the submission URL is `/ext.jsp`, THEN the app SHALL attempt to extract the application ID from the page DOM via JavaScript injection.

2.2. WHEN the JavaScript extraction succeeds and returns a non-empty string, THEN that string SHALL be used as the `applicationId` in the `CheckInGuest` event.

2.3. WHEN the JavaScript extraction fails (throws an error) or returns an empty string, THEN `applicationId` SHALL default to an empty string `""` and the check-in flow SHALL continue normally.

2.4. WHEN the submission URL is `svnext.jsp`, THEN the app SHALL NOT attempt JavaScript extraction and SHALL use an empty string `""` as the `applicationId`.

---

### Requirement 3: Call Backend API to Update FRRO Status

**User Story**: As a hotel staff member, I want the guest's FRRO status to be updated in the backend system automatically after submission, so that the record is kept in sync without manual data entry.

#### Acceptance Criteria

3.1. WHEN a submission URL is detected and a guest is selected, THEN the app SHALL dispatch a `CheckInGuest` event to `GuestListBloc` with the guest's `guestdataId`, `branchId = 5`, the extracted `applicationId` (or `""`), and `userId = 0`.

3.2. WHEN `CheckInGuest` is dispatched, THEN `GuestListBloc` SHALL call `UpdateFRROStatusForChrome` via `GuestRemoteDataSource.checkIn()` with the correct parameters.

3.3. WHEN the API call succeeds (returns `Status = 1`), THEN `GuestListBloc` SHALL emit `GuestCheckInSuccess`.

3.4. WHEN the API call fails (network error, server error, or `Status != 1`), THEN `GuestListBloc` SHALL emit `GuestCheckInFailure` with a descriptive error message.

---

### Requirement 4: Show User Feedback via Snackbar

**User Story**: As a hotel staff member, I want to see a clear confirmation or error message after submitting a guest's FRRO form, so that I know whether the submission was recorded successfully.

#### Acceptance Criteria

4.1. WHEN `GuestCheckInSuccess` state is emitted, THEN the app SHALL display a green snackbar with the message "FRRO submitted successfully".

4.2. WHEN `GuestCheckInFailure` state is emitted, THEN the app SHALL display a red snackbar with a message indicating the failure reason.

4.3. The snackbar SHALL be shown using `ScaffoldMessenger` so it is visible above the WebView content.

---

### Requirement 5: Refresh Guest List After Successful Submission

**User Story**: As a hotel staff member, I want the guest list to automatically update after a successful FRRO submission, so that the submitted guest's card immediately shows the "Synced" status without requiring a manual refresh.

#### Acceptance Criteria

5.1. WHEN `GuestCheckInSuccess` state is emitted, THEN the app SHALL dispatch a `LoadGuestList(branchId: 5)` event to reload the guest list.

5.2. AFTER the guest list reloads, the submitted guest's `passToFRRO` field SHALL be `1`, causing `isSyncedToFRRO` to return `true`.

5.3. WHEN `GuestCheckInFailure` state is emitted, THEN the app SHALL NOT dispatch `LoadGuestList` (the list remains unchanged).

---

### Requirement 6: Prevent Errors from Unmounted Widget

**User Story**: As a developer, I want the submission detection logic to be safe against widget lifecycle issues, so that navigating away from the FRRO page during an async operation does not cause crashes.

#### Acceptance Criteria

6.1. WHEN the widget is unmounted before `_handleSubmissionDetected` completes its async operations, THEN the app SHALL check `mounted` before dispatching any bloc event and SHALL skip the dispatch if not mounted.

6.2. The app SHALL NOT throw any unhandled exceptions as a result of the submission detection flow.

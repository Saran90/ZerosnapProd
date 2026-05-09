# Tasks: FRRO Submission Tracking

## Task List

- [x] 1. Add submission URL detection to `_FrroListPageState`
  - [x] 1.1 Add `_isSubmissionUrl(String lowerUrl) → bool` helper method that returns `true` for URLs containing `svnext.jsp` or `/ext.jsp`
  - [x] 1.2 Update `onPageFinished` in `NavigationDelegate` to call `_isSubmissionUrl` before the existing login/form-fill logic; if it returns `true` and `_selectedGuest != null`, call `_handleSubmissionDetected` and `return` early

- [x] 2. Implement application ID extraction
  - [x] 2.1 Add `_extractApplicationIdScript` static const String with JavaScript that searches the DOM for known application ID element IDs/classes and falls back to a regex pattern scan of `document.body.innerText`
  - [x] 2.2 Implement `_handleSubmissionDetected(String url, Guest guest) → Future<void>` that: (a) runs `_extractApplicationIdScript` via `runJavaScriptReturningResult` only when URL contains `/ext.jsp`, (b) catches any JS errors and defaults `applicationId` to `""`, (c) checks `mounted` before proceeding, (d) dispatches `CheckInGuest` to `GuestListBloc`

- [x] 3. Wire BlocListener for user feedback and list refresh
  - [x] 3.1 Wrap the existing `Scaffold` in `_FrroListPageContent.build` with a `BlocListener<GuestListBloc, GuestListState>` that handles `GuestCheckInSuccess` and `GuestCheckInFailure`
  - [x] 3.2 On `GuestCheckInSuccess`: show a green `SnackBar` with "FRRO submitted successfully" and dispatch `LoadGuestList(branchId: 5)` to refresh the guest list
  - [x] 3.3 On `GuestCheckInFailure`: show a red `SnackBar` with the failure message

- [ ] 4. Write unit tests for `_isSubmissionUrl`
  - [ ] 4.1 Test that `svnext.jsp` URLs return `true`
  - [ ] 4.2 Test that `/ext.jsp` URLs return `true`
  - [ ] 4.3 Test that `formc.jsp`, `formc`, `newcform`, `addcform`, and unrelated URLs return `false`

- [ ] 5. Write widget tests for the BlocListener feedback
  - [ ] 5.1 Mock `GuestListBloc` and emit `GuestCheckInSuccess` → assert success snackbar is shown and `LoadGuestList` event is added
  - [ ] 5.2 Mock `GuestListBloc` and emit `GuestCheckInFailure` → assert error snackbar is shown and no `LoadGuestList` event is added

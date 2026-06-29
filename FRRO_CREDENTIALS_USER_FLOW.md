# FRRO Credentials Management - User Flow

## Complete User Journey

### Scenario 1: Update FRRO Credentials

```
┌─────────────────────────────────────────────────────────────┐
│                    Settings Page                            │
├─────────────────────────────────────────────────────────────┤
│  [Profile Info]                                             │
│  └─ Username, Hotel Name                                    │
│                                                              │
│  Settings Options:                                           │
│  ├─ HTTPS Address                                           │
│  ├─ System Settings                                         │
│  ├─ FRRO Credentials ← [TAP]                                │
│  ├─ Clear Cache                                             │
│  └─ Logout                                                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
        (navigation via: context.push('/settings/frro-credentials'))
                           ↓
┌─────────────────────────────────────────────────────────────┐
│            FRRO Credentials Page (Loads)                    │
├─────────────────────────────────────────────────────────────┤
│  [AppBar]                                                   │
│  "FRRO Credentials"                                         │
│                                                              │
│  [Info Card]                                                │
│  "Manage your FRRO login credentials here..."              │
│                                                              │
│  FRRO Username: [Loading...]                               │
│  FRRO Password: [Loading...]                               │
│                                                              │
│  [Save Credentials]                                         │
│  [Sync from Server]                                         │
│                                                              │
│  [How it works section]                                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
              (Credentials loaded from SharedPreferences)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│        FRRO Credentials Page (Credentials Loaded)           │
├─────────────────────────────────────────────────────────────┤
│  [AppBar]                                                   │
│  "FRRO Credentials"                                         │
│                                                              │
│  [Info Card]                                                │
│  "Manage your FRRO login credentials here..."              │
│                                                              │
│  FRRO Username:                                             │
│  [🧑 _________old_username__________]                       │
│                                                              │
│  FRRO Password:                                             │
│  [🔒 ••••••••••••• ] [👁]  ← Toggle visibility              │
│                                                              │
│  [Save Credentials]  [🔄 Sync from Server]                 │
│                                                              │
│  [How it works section]                                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
                 (User edits fields)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│     FRRO Credentials Page (User Editing)                    │
├─────────────────────────────────────────────────────────────┤
│  FRRO Username:                                             │
│  [🧑 _________new_username__________]   ← Edited            │
│                                                              │
│  FRRO Password:                                             │
│  [🔐 new_password_visible_text ↻] [👁]  ← Password shown   │
│                                                              │
│  [Save Credentials]  [🔄 Sync from Server]                 │
└─────────────────────────────────────────────────────────────┘
                           ↓
              (User taps "Save Credentials")
                           ↓
             ┌─────────────────────────────┐
             │   Validating Fields         │
             │  (Check: not empty)         │
             └─────────────────────────────┘
                           ↓
             ┌─────────────────────────────┐
             │   Saving to SharedPrefs     │
             │  1. Get current session     │
             │  2. Update FRRO creds       │
             │  3. Persist to device       │
             └─────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│        FRRO Credentials Page (Save Success)                 │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ✓ Changes saved successfully                         │   │
│  └──────────────────────────────────────────────────────┘   │ ← Auto-hide after 2s
│                                                              │
│  FRRO Username:                                             │
│  [🧑 _________new_username__________]                       │
│                                                              │
│  FRRO Password:                                             │
│  [🔒 •••••••••••••• ] [👁]                                  │
│                                                              │
│  [Save Credentials]  [🔄 Sync from Server]                 │
│                                                              │
│  ✓ Green SnackBar: "FRRO credentials updated successfully" │
│    (visible for 2 seconds)                                 │
└─────────────────────────────────────────────────────────────┘
                           ↓
            (User navigates back or closes)
                           ↓
          ✅ Credentials updated successfully!
             New credentials will be used on next
             FRRO page load for auto-fill.
```

---

## Scenario 2: Sync Credentials from Server (Future Feature)

```
┌─────────────────────────────────────────────────────────────┐
│        FRRO Credentials Page                                │
├─────────────────────────────────────────────────────────────┤
│  FRRO Username: [________existing_______]                  │
│  FRRO Password: [•••••••••] [👁]                            │
│                                                              │
│  [Save Credentials]  [🔄 Sync from Server] ← [TAP]         │
└─────────────────────────────────────────────────────────────┘
                           ↓
                    (Loading spinner)
                           ↓
             ┌─────────────────────────────┐
             │   API Call                  │
             │  GET /api/frro/sync         │
             │  (Future implementation)    │
             └─────────────────────────────┘
                           ↓
                    (Success Response)
                           ↓
             ┌─────────────────────────────┐
             │   Auto-update fields        │
             │  frroUsername: new_user     │
             │  frroPassword: new_pass     │
             │                             │
             │   Save to SharedPrefs       │
             └─────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│     FRRO Credentials Page (Synced)                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐   │
│  │ ✓ Credentials synced from server                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  FRRO Username: [________new_user__________]               │
│  FRRO Password: [•••••••••] [👁]                            │
│                                                              │
│  [Save Credentials]  [🔄 Sync from Server]                 │
│                                                              │
│  ✓ Green SnackBar: "Credentials synced from server"         │
└─────────────────────────────────────────────────────────────┘
```

---

## Scenario 3: Error Handling

### Case A: Empty Fields
```
FRRO Username: [________]  ← Left empty
FRRO Password: [________]  ← Left empty

                           ↓
                (User taps "Save Credentials")
                           ↓
          ┌──────────────────────────────┐
          │ Validation Check             │
          │ ❌ Fields cannot be empty!   │
          └──────────────────────────────┘
                           ↓
     🔴 Red SnackBar: "Please fill in all fields"
                           ↓
     Page remains unchanged, user can correct
```

### Case B: API Error (Future)
```
                (User taps "Sync from Server")
                           ↓
             ┌──────────────────────────────┐
             │ API Call Fails               │
             │ Network error or 500 error   │
             └──────────────────────────────┘
                           ↓
     🔴 Red SnackBar: "Error syncing credentials: [error details]"
                           ↓
     Page remains unchanged, user can retry or edit manually
```

### Case C: Session Not Found
```
                (Page loads)
                           ↓
          ┌──────────────────────────────┐
          │ Load Credentials             │
          │ No session found in prefs    │
          └──────────────────────────────┘
                           ↓
     Fields remain empty, ready for user input
     (Usually happens after app is freshly installed
      or user has logged out)
```

---

## Feature Readiness Checklist

### ✅ Completed
- [x] FRRO Credentials page UI
- [x] Load credentials from SharedPreferences
- [x] Display credentials in form fields
- [x] Edit credentials locally
- [x] Save credentials to SharedPreferences
- [x] Password visibility toggle
- [x] Validation for empty fields
- [x] Success/error feedback via SnackBar
- [x] Success indicator widget
- [x] Sync button placeholder
- [x] Info/help section
- [x] GoRouter navigation setup
- [x] Settings page menu integration

### ⏳ Pending (Future Work)
- [ ] Sync API implementation
- [ ] API error handling
- [ ] Loading state during sync
- [ ] Credentials validation (format check)
- [ ] Confirmation dialog on save
- [ ] Update other pages to use GoRouter for settings
- [ ] Add encryption for sensitive data

---

## Integration with FRRO Form Auto-fill

### Current Flow (Before This Feature)
```
1. User logs in
   ↓
2. FRRO_Username & FRRO_Password received from API
   ↓
3. Stored in SharedPreferences via LoginSession
   ↓
4. User opens FRRO page
   ↓
5. Auto-fill script reads from SharedPreferences
   ↓
6. Credentials filled in FRRO form
```

### Updated Flow (With This Feature)
```
1. User logs in
   ↓
2. FRRO_Username & FRRO_Password received from API
   ↓
3. Stored in SharedPreferences via LoginSession
   ↓
4. [NEW] User can visit Settings → FRRO Credentials
   ├─ View current credentials
   ├─ Edit to different FRRO account
   ├─ Sync with server to get latest
   └─ Save changes locally
   ↓
5. User opens FRRO page
   ↓
6. Auto-fill script reads from SharedPreferences
   ↓
7. Credentials filled in FRRO form
   (Will be updated credentials if user changed them)
```

---

## Key Benefits

### For Users
✅ Easy switching between FRRO accounts without logging out
✅ Handle outdated FRRO credentials from server
✅ Override server credentials with local account
✅ Sync latest credentials from server when available
✅ Clear visibility of current credentials being used

### For Developers
✅ Centralized credential management
✅ Reuse existing SharedPreferences infrastructure
✅ Clean separation of concerns (settings feature)
✅ Ready for API integration
✅ No breaking changes to existing code

---

## Security Considerations

### Current Implementation
⚠️ Credentials stored in plain text (SharedPreferences)
- **Impact**: Low-Medium (local device storage only)
- **Mitigation**: Device-level security (PIN, biometric)

### Recommendations for Production
1. Consider adding encryption layer
2. Add audit logging for credential changes
3. Implement session timeout
4. Add "Require authentication" for credential changes
5. Clear credentials on logout
6. Add certificate pinning for API sync

---

## Future Enhancements

### Phase 2
- [ ] Add "Last Synced" timestamp
- [ ] Add credential history (view previous values)
- [ ] Add "Reset to defaults" option
- [ ] Multi-account support

### Phase 3
- [ ] Biometric authentication for access
- [ ] Encrypted local storage
- [ ] Cloud backup option
- [ ] Credential rotation alerts

### Phase 4
- [ ] Single Sign-On (SSO) integration
- [ ] FRRO account validation
- [ ] Credential strength indicator
- [ ] Automated sync scheduling

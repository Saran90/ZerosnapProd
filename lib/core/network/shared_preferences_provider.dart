import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the Android project's SharedPreferencesDataProvider.
/// Stores base URL, access token, API key, image quality, and login session data.
class SharedPreferencesProvider {
  static const _keyToken = 'authorization_token';
  static const _keyApiKey = 'api_key';
  static const _keyBaseUrl = 'base_url';
  static const _keyQuality = 'quality';

  // ── Login session ─────────────────────────────────────────────────────────
  static const _keyUsername = 'username';
  static const _keyHotelName = 'hotelname';
  static const _keyCountry = 'country';
  static const _keyUserEmail = 'user_email';
  static const _keyApiUrl = 'api_url';
  static const _keyFrroUsername = 'frro_username';
  static const _keyFrroPassword = 'frro_password';
  static const _keyFrroDistrictId = 'frro_district_id';
  static const _keyShowRoomNo = 'showRoomNo';
  static const _keyShowVehicleType = 'showVehicleType';
  static const _keyShowVehicleNo = 'showVehicleNo';
  static const _keyShowContactPerson = 'showContactPersonToVisit';
  static const _keyShowDepartment = 'showDepartmentToVisit';
  static const _keyShowScanNational = 'showScanNationalCard';
  static const _keyShowScanForeign = 'showScanForeignCard';
  static const _keyShowGuestSignature = 'showGuestSignature';
  static const _keyShowPrintMobileApp = 'showPrintMobileApp';
  static const _keyShowFrroCheckOutInExt = 'showFrroCheckOutInExt';
  static const _keyShowNextDestination = 'showNextDestination';
  static const _keyShowFRROGuestListApp = 'showFRROGuestListApp';
  static const _keyScanByMrz = 'scanByMrz';

  // ── Logout behaviour ──────────────────────────────────────────────────────
  /// When true  → logout clears everything (including base URL) → domain entry screen.
  /// When false → logout keeps base URL → login credentials screen.
  static const _keyClearUrlOnLogout = 'clear_url_on_logout';

  // ── Base URL ──────────────────────────────────────────────────────────────
  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? '';
  }

  // ── Access token ──────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) ?? '';
  }

  // ── API key (IntelliKey) ──────────────────────────────────────────────────
  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
  }

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey) ?? '';
  }

  // ── Image quality ─────────────────────────────────────────────────────────
  Future<void> saveQuality(int q) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQuality, q);
  }

  Future<int> getQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuality) ?? 80;
  }

  // ── Login session data ────────────────────────────────────────────────────
  Future<void> saveLoginSession(LoginSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyToken, session.token),
      prefs.setString(_keyApiKey, session.apiKey),
      if (session.country != null)
        prefs.setString(_keyCountry, session.country!),
      prefs.setString(_keyUsername, session.username),
      prefs.setString(_keyHotelName, session.hotelName),
      prefs.setString(_keyUserEmail, session.userEmail),
      prefs.setString(_keyApiUrl, session.apiUrl),
      prefs.setString(_keyFrroUsername, session.frroUsername),
      prefs.setString(_keyFrroPassword, session.frroPassword),
      prefs.setString(_keyFrroDistrictId, session.frroDistrictId),
      prefs.setBool(_keyShowRoomNo, session.showRoomNo),
      prefs.setBool(_keyShowVehicleType, session.showVehicleType),
      prefs.setBool(_keyShowVehicleNo, session.showVehicleNo),
      prefs.setBool(_keyShowContactPerson, session.showContactPersonToVisit),
      prefs.setBool(_keyShowDepartment, session.showDepartmentToVisit),
      prefs.setBool(_keyShowScanNational, session.showScanNationalCard),
      prefs.setBool(_keyShowScanForeign, session.showScanForeignCard),
      prefs.setBool(_keyShowGuestSignature, session.showGuestSignature),
      prefs.setBool(_keyShowPrintMobileApp, session.showPrintMobileApp),
      prefs.setBool(_keyShowFrroCheckOutInExt, session.showFrroCheckOutInExt),
      prefs.setBool(_keyShowNextDestination, session.showNextDestination),
      prefs.setBool(_keyShowFRROGuestListApp, session.showFRROGuestListApp),
      prefs.setBool(_keyScanByMrz, session.scanByMrz),
    ]);
  }

  Future<LoginSession?> getLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken) ?? '';
    if (token.isEmpty) return null;
    return LoginSession(
      token: token,
      apiKey: prefs.getString(_keyApiKey) ?? '',
      country: prefs.getString(_keyCountry),
      username: prefs.getString(_keyUsername) ?? '',
      hotelName: prefs.getString(_keyHotelName) ?? '',
      userEmail: prefs.getString(_keyUserEmail) ?? '',
      apiUrl: prefs.getString(_keyApiUrl) ?? '',
      frroUsername: prefs.getString(_keyFrroUsername) ?? '',
      frroPassword: prefs.getString(_keyFrroPassword) ?? '',
      frroDistrictId: prefs.getString(_keyFrroDistrictId) ?? '',
      showRoomNo: prefs.getBool(_keyShowRoomNo) ?? false,
      showVehicleType: prefs.getBool(_keyShowVehicleType) ?? false,
      showVehicleNo: prefs.getBool(_keyShowVehicleNo) ?? false,
      showContactPersonToVisit: prefs.getBool(_keyShowContactPerson) ?? false,
      showDepartmentToVisit: prefs.getBool(_keyShowDepartment) ?? false,
      showScanNationalCard: prefs.getBool(_keyShowScanNational) ?? false,
      showScanForeignCard: prefs.getBool(_keyShowScanForeign) ?? false,
      showGuestSignature: prefs.getBool(_keyShowGuestSignature) ?? false,
      showPrintMobileApp: prefs.getBool(_keyShowPrintMobileApp) ?? false,
      showFrroCheckOutInExt: prefs.getBool(_keyShowFrroCheckOutInExt) ?? false,
      showNextDestination: prefs.getBool(_keyShowNextDestination) ?? false,
      showFRROGuestListApp: prefs.getBool(_keyShowFRROGuestListApp) ?? false,
      scanByMrz: prefs.getBool(_keyScanByMrz) ?? false,
    );
  }

  Future<bool> clear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }

  // ── Logout behaviour toggle ───────────────────────────────────────────────
  /// When true  → logout clears everything (including base URL) → domain entry screen.
  /// When false → logout keeps base URL → login credentials screen.
  Future<void> saveClearUrlOnLogout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyClearUrlOnLogout, value);
  }

  /// Defaults to true — matches the original behaviour (clear everything).
  Future<bool> getClearUrlOnLogout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyClearUrlOnLogout) ?? true;
  }

  Future<String> getFrroUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFrroUsername) ?? '';
  }

  Future<String> getFrroPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFrroPassword) ?? '';
  }

  Future<String> getFrroDistrictId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFrroDistrictId) ?? '';
  }

  // ── Mobile settings (from /api/GetSettingMobile) ─────────────────────────
  /// Persist the mobile settings returned by `/api/GetSettingMobile`.
  /// Uses the same keys as the login session so downstream code (which reads
  /// these flags via [getLoginSession]) automatically picks up the latest
  /// values without requiring a re-login.
  Future<void> saveMobileSettings(MobileSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      if (settings.apiUrl.isNotEmpty)
        prefs.setString(_keyApiUrl, settings.apiUrl),
      prefs.setBool(_keyShowPrintMobileApp, settings.showPrintMobileApp),
      prefs.setBool(_keyShowContactPerson, settings.showContactPersonToVisit),
      prefs.setBool(_keyShowDepartment, settings.showDepartmentToVisit),
      prefs.setBool(_keyShowVehicleType, settings.showVehicleType),
      prefs.setBool(_keyShowVehicleNo, settings.showVehicleNo),
      prefs.setBool(_keyShowRoomNo, settings.showRoomNo),
      prefs.setBool(_keyShowGuestSignature, settings.showGuestSignature),
      prefs.setBool(_keyShowFrroCheckOutInExt, settings.showFrroCheckOutInExt),
      prefs.setBool(_keyShowNextDestination, settings.showNextDestination),
      prefs.setBool(_keyShowFRROGuestListApp, settings.showFrroGuestListApp),
      prefs.setBool(_keyScanByMrz, settings.scanByMrz),
      // Derive the national/foreign card visibility from `ScanType`
      // (1 = both, 2 = national only, 3 = foreign only, anything else = none)
      prefs.setBool(
        _keyShowScanNational,
        settings.scanType == 1 || settings.scanType == 2,
      ),
      prefs.setBool(
        _keyShowScanForeign,
        settings.scanType == 1 || settings.scanType == 3,
      ),
    ]);
  }
}

// ── Login session model ───────────────────────────────────────────────────────
class LoginSession {
  final String token;
  final String apiKey;
  final String? country;
  final String username;
  final String hotelName;
  final String userEmail;
  final String apiUrl;
  final String frroUsername;
  final String frroPassword;
  final String frroDistrictId;
  final bool showRoomNo;
  final bool showVehicleType;
  final bool showVehicleNo;
  final bool showContactPersonToVisit;
  final bool showDepartmentToVisit;
  final bool showScanNationalCard;
  final bool showScanForeignCard;
  final bool showGuestSignature;
  final bool showPrintMobileApp;
  final bool showFrroCheckOutInExt;
  final bool showNextDestination;
  final bool showFRROGuestListApp;
  final bool scanByMrz; // true = MRZ scanner, false = OCR API

  const LoginSession({
    required this.token,
    required this.apiKey,
    this.country,
    required this.username,
    required this.hotelName,
    this.userEmail = '',
    this.apiUrl = '',
    this.frroUsername = '',
    this.frroPassword = '',
    this.frroDistrictId = '',
    this.showRoomNo = false,
    this.showVehicleType = false,
    this.showVehicleNo = false,
    this.showContactPersonToVisit = false,
    this.showDepartmentToVisit = false,
    this.showScanNationalCard = false,
    this.showScanForeignCard = false,
    this.showGuestSignature = false,
    this.showPrintMobileApp = false,
    this.showFrroCheckOutInExt = false,
    this.showNextDestination = false,
    this.showFRROGuestListApp = false,
    this.scanByMrz = false, // default to OCR flow
  });
}

// ── Mobile settings model (from /api/GetSettingMobile) ──────────────────────
/// Mobile settings returned by the backend's `/api/GetSettingMobile` endpoint.
/// These are the same flags that arrive inside the login response's
/// `setting` object — persisting them lets the app pick up new config
/// values on every cold start (no re-login required).
class MobileSettings {
  final bool showPrintMobileApp;
  final bool showContactPersonToVisit;
  final bool showDepartmentToVisit;
  final bool showVehicleType;
  final bool showVehicleNo;
  final bool showRoomNo;
  final String apiUrl;
  final int scanType; // 1 = both, 2 = national, 3 = foreign
  final bool showGuestSignature;
  final bool showFrroCheckOutInExt;
  final bool scanByMrz;
  final bool showNextDestination;
  final bool showFrroGuestListApp;

  const MobileSettings({
    this.showPrintMobileApp = false,
    this.showContactPersonToVisit = false,
    this.showDepartmentToVisit = false,
    this.showVehicleType = false,
    this.showVehicleNo = false,
    this.showRoomNo = false,
    this.apiUrl = '',
    this.scanType = 0,
    this.showGuestSignature = false,
    this.showFrroCheckOutInExt = false,
    this.scanByMrz = false,
    this.showNextDestination = false,
    this.showFrroGuestListApp = false,
  });

  factory MobileSettings.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool asBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is num) return v == 1;
      if (v is String) {
        final s = v.toLowerCase();
        return s == '1' || s == 'true';
      }
      return false;
    }

    return MobileSettings(
      showPrintMobileApp: asBool(json['ShowPrintMobileApp']),
      showContactPersonToVisit: asBool(json['ShowContactPersonToVisit']),
      showDepartmentToVisit: asBool(json['ShowDepartmentToVisit']),
      showVehicleType: asBool(json['ShowVehicleType']),
      showVehicleNo: asBool(json['ShowVehicleNo']),
      showRoomNo: asBool(json['ShowRoomNo']),
      apiUrl: json['apiurl'] as String? ?? '',
      scanType: asInt(json['ScanType']),
      showGuestSignature: asBool(json['ShowGuestSignature']),
      showFrroCheckOutInExt: asBool(json['ShowFRROCheckOutInExt']),
      scanByMrz: asBool(json['AppScanByMRZ']),
      showNextDestination: asBool(json['ShowNextDestination']),
      showFrroGuestListApp: asBool(json['ShowFRROGuestListApp']),
    );
  }
}

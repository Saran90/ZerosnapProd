import '../../../core/config/api_constants.dart';
import '../../../core/network/api_base_helper.dart';
import '../../../core/network/shared_preferences_provider.dart';

class AuthRepository {
  final ApiBaseHelper _api;
  final SharedPreferencesProvider _prefs;

  AuthRepository({ApiBaseHelper? api, SharedPreferencesProvider? prefs})
    : _api = api ?? ApiBaseHelper(),
      _prefs = prefs ?? SharedPreferencesProvider();

  Future<String> getBaseUrl() => _prefs.getBaseUrl();
  Future<void> saveBaseUrl(String url) => _prefs.saveBaseUrl(url);
  Future<String> getAccessToken() => _prefs.getAccessToken();

  /// Verify the domain URL is a valid Zerosnap server.
  Future<bool> verifyDomain(String url) async {
    final response =
        await _api.get(ApiConstants.verify, baseUrl: url)
            as Map<String, dynamic>;
    final status =
        response['status'] as int? ?? response['Status'] as int? ?? 0;
    return status == 1;
  }

  /// Login with username + password.
  /// On success, persists the full session (token, apiKey, settings) locally.
  Future<LoginResult> login(
    String url,
    String username,
    String password,
  ) async {
    final response =
        await _api.get(
              ApiConstants.login,
              baseUrl: url,
              queryParameters: {'username': username, 'password': password},
            )
            as Map<String, dynamic>;

    final result = LoginResult.fromJson(response);

    if (result.success && result.session != null) {
      await _prefs.saveLoginSession(result.session!);
    }

    return result;
  }
}

// ── Login result ──────────────────────────────────────────────────────────────
class LoginResult {
  final bool success;
  final String? message;
  final LoginSession? session;

  const LoginResult({required this.success, this.message, this.session});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final status = json['Status'] as int? ?? json['status'] as int? ?? 0;
    final success = status == 1;

    LoginSession? session;
    if (success) {
      final setting = json['setting'] as Map<String, dynamic>?;
      final scanType = setting?['ScanType'] as int? ?? 0;

      session = LoginSession(
        token:
            json['access_token'] as String? ?? json['token'] as String? ?? '',
        apiKey: json['key'] as String? ?? '',
        country: json['Country'] as String? ?? json['country'] as String?,
        username: json['username'] as String? ?? '',
        hotelName:
            json['hotelname'] as String? ?? json['hotelName'] as String? ?? '',
        userEmail: json['login_useremail'] as String? ?? '',
        apiUrl: setting?['apiurl'] as String? ?? '',
        frroUsername: json['FRRO_Username'] as String? ?? '',
        frroPassword: json['FRRO_Password'] as String? ?? '',
        frroDistrictId: json['FrroDistrictId'] as String? ?? '',
        showRoomNo: setting?['ShowRoomNo'] == 1,
        showVehicleType: setting?['ShowVehicleType'] == 1,
        showVehicleNo: setting?['ShowVehicleNo'] == 1,
        showContactPersonToVisit: setting?['ShowContactPersonToVisit'] == 1,
        showDepartmentToVisit: setting?['ShowDepartmentToVisit'] == 1,
        showScanNationalCard: scanType == 1 || scanType == 2,
        showScanForeignCard: scanType == 1 || scanType == 3,
        showGuestSignature: setting?['ShowGuestSignature'] == 1,
        showPrintMobileApp: setting?['ShowPrintMobileApp'] == 1,
        showFrroCheckOutInExt: setting?['ShowFRROCheckOutInExt'] == 1,
        showNextDestination: setting?['ShowNextDestination'] == 1,
        showFRROGuestListApp: false,
        scanByMrz:
            (json['AppScanByMRZ'] as int? ??
                json['appScanByMRZ'] as int? ??
                json['AppScanByMrz'] as int? ??
                0) ==
            1,
      );
    }

    return LoginResult(
      success: success,
      message: json['StatusMessage'] as String? ?? json['message'] as String?,
      session: session,
    );
  }
}

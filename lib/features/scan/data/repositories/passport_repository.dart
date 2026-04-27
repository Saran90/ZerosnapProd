import '../../../../core/config/api_constants.dart';
import '../../../../core/network/api_base_helper.dart';
import '../../../../core/network/shared_preferences_provider.dart';

class PassportRepository {
  final ApiBaseHelper _api;
  final SharedPreferencesProvider _prefs;

  PassportRepository({ApiBaseHelper? api, SharedPreferencesProvider? prefs})
    : _api = api ?? ApiBaseHelper(),
      _prefs = prefs ?? SharedPreferencesProvider();

  /// POST to /api/SavePassportAndVisa — mirrors Android savePassport()
  Future<bool> savePassport(Map<String, dynamic> body) async {
    final url = await _prefs.getBaseUrl();
    final token = await _prefs.getAccessToken();

    final response =
        await _api.post(
              ApiConstants.savePassport,
              baseUrl: url,
              body: body,
              headers: {'Authorization': 'Bearer $token'},
            )
            as Map<String, dynamic>;

    final status =
        response['Status'] as int? ?? response['status'] as int? ?? 0;
    return status == 1;
  }

  /// OCR extract from passport image — returns extracted field map or null.
  Future<Map<String, dynamic>?> extractPassport({
    required String frontBase64,
    String? backBase64,
  }) async {
    final url = await _prefs.getBaseUrl();
    final token = await _prefs.getAccessToken();
    final apiKey = await _prefs.getApiKey();

    final response =
        await _api.post(
              ApiConstants.savePassport,
              baseUrl: url,
              body: {
                'idfrontbase64': frontBase64,
                if (backBase64 != null && backBase64.isNotEmpty)
                  'idbackbase64': backBase64,
              },
              headers: {'Authorization': 'Bearer $token', 'IntelliKey': apiKey},
            )
            as Map<String, dynamic>;

    final data = response['Data'] ?? response['data'];
    return data as Map<String, dynamic>?;
  }
}

import '../../../../core/config/api_constants.dart';
import '../../../../core/network/api_base_helper.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../domain/entities/lookup_models.dart';

class PassportRepository {
  final ApiBaseHelper _api;
  final SharedPreferencesProvider _prefs;

  PassportRepository({ApiBaseHelper? api, SharedPreferencesProvider? prefs})
    : _api = api ?? ApiBaseHelper(),
      _prefs = prefs ?? SharedPreferencesProvider();

  Future<Map<String, String>> get _authHeaders async {
    final token = await _prefs.getAccessToken();
    return {'Authorization': 'Bearer $token'};
  }

  /// POST to /api/Zerosnap/GetGVPassportFront
  /// Extracts passport data from a base64-encoded front image.
  /// Always returns the raw response map so callers can read error messages.
  /// Returns null only if the network/parse fails entirely.
  Future<Map<String, dynamic>?> extractPassport({
    required String frontBase64,
  }) async {
    try {
      final url = await _prefs.getBaseUrl();
      final apiKey = await _prefs.getApiKey();
      final response = await _api.post(
        ApiConstants.extractPassport,
        baseUrl: url,
        body: {'idbase64': frontBase64},
        headers: {...await _authHeaders, 'IntelliKey': apiKey},
      );
      if (response is Map<String, dynamic>) return response;
      return null;
    } catch (e) {
      return {'message': e.toString(), 'error': true};
    }
  }

  /// POST to /api/Zerosnap/GetGVVisa
  /// Extracts visa data from a base64-encoded visa image.
  /// Always returns the raw response map so callers can read error messages.
  /// Returns null only if the network/parse fails entirely.
  Future<Map<String, dynamic>?> extractVisa({
    required String visaBase64,
  }) async {
    try {
      final url = await _prefs.getBaseUrl();
      final apiKey = await _prefs.getApiKey();
      final response = await _api.post(
        ApiConstants.extractVisa,
        baseUrl: url,
        body: {'idbase64': visaBase64},
        headers: {...await _authHeaders, 'IntelliKey': apiKey},
      );
      if (response is Map<String, dynamic>) return response;
      return null;
    } catch (e) {
      return {'message': e.toString(), 'error': true};
    }
  }

  /// POST to /api/SavePassportAndVisa
  Future<bool> savePassport(Map<String, dynamic> body) async {
    final url = await _prefs.getBaseUrl();
    final response =
        await _api.post(
              ApiConstants.savePassport,
              baseUrl: url,
              body: body,
              headers: await _authHeaders,
            )
            as Map<String, dynamic>;

    final status =
        response['Status'] as int? ?? response['status'] as int? ?? 0;
    return status == 1;
  }

  /// GET /api/GetNationalityList
  Future<List<MrzCountry>> getCountries() async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      ApiConstants.countries,
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => MrzCountry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/GetPurposeOfVisitList
  Future<List<Purpose>> getPurposes() async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      ApiConstants.purposes,
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => Purpose.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/GetVisaTypeList
  Future<List<VisaType>> getVisaTypes() async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      ApiConstants.visaTypes,
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => VisaType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/GetVisaSubTypeList?id={visaTypeId}
  Future<List<VisaSubType>> getVisaSubTypes(String visaTypeId) async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      '${ApiConstants.visaSubTypes}?id=$visaTypeId',
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => VisaSubType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/GetVehicleTypeList
  Future<List<VehicleType>> getVehicleTypes() async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      ApiConstants.vehicleTypes,
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => VehicleType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/GetStatesList
  Future<List<IndianState>> getStates() async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      ApiConstants.states,
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => IndianState.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/GetDistrictList?id={stateId}
  Future<List<IndianDistrict>> getDistricts(String stateId) async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.get(
      '${ApiConstants.districts}?id=$stateId',
      baseUrl: url,
      headers: await _authHeaders,
    );
    final list = response is List
        ? response
        : (response['Data'] ?? response['data'] ?? []);
    return (list as List)
        .map((e) => IndianDistrict.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

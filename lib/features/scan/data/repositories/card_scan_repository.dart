import 'dart:convert';
import 'dart:io';

import '../../../../core/config/api_constants.dart';
import '../../../../core/network/api_base_helper.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../../domain/entities/lookup_models.dart';
import '../../domain/entities/ocr_result.dart';

/// Mirrors the Android project's AuthRepository methods for domestic card scanning.
class CardScanRepository {
  final ApiBaseHelper _api;
  final SharedPreferencesProvider _prefs;

  CardScanRepository({ApiBaseHelper? api, SharedPreferencesProvider? prefs})
    : _api = api ?? ApiBaseHelper(),
      _prefs = prefs ?? SharedPreferencesProvider();

  Future<Map<String, String>> get _authHeaders async {
    final token = await _prefs.getAccessToken();
    final apiKey = await _prefs.getApiKey();
    return {'Authorization': 'Bearer $token', 'IntelliKey': apiKey};
  }

  // ── OCR Extract ───────────────────────────────────────────────────────────
  Future<OcrResult> extract({
    required String frontBase64,
    String? backBase64,
    required String cardType,
  }) async {
    final url = await _prefs.getBaseUrl();
    final response = await _api.post(
      _ocrEndpoint(cardType),
      baseUrl: url,
      body: {
        'idfrontbase64': frontBase64,
        if (backBase64 != null && backBase64.isNotEmpty)
          'idbackbase64': backBase64,
      },
      headers: await _authHeaders,
    );
    return OcrResult.fromJson(response as Map<String, dynamic>);
  }

  // ── Verify Document ───────────────────────────────────────────────────────
  /// Calls the appropriate verify endpoint for the card type.
  /// Returns the raw response map on success (code 200), throws on failure.
  Future<Map<String, dynamic>> verifyDocument({
    required Map<String, dynamic> body,
    required String cardType,
  }) async {
    final url = await _prefs.getBaseUrl();
    final response =
        await _api.post(
              _verifyEndpoint(cardType),
              baseUrl: url,
              body: body,
              headers: await _authHeaders,
            )
            as Map<String, dynamic>;
    return response;
  }

  // ── Save Indian Card ──────────────────────────────────────────────────────
  Future<bool> saveIndianCard(Map<String, dynamic> body) async {
    final url = await _prefs.getBaseUrl();
    final response =
        await _api.post(
              ApiConstants.saveIndianCard,
              baseUrl: url,
              body: body,
              headers: await _authHeaders,
            )
            as Map<String, dynamic>;
    final status =
        response['status'] as int? ?? response['Status'] as int? ?? 0;
    return status == 1;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _ocrEndpoint(String cardType) {
    switch (cardType) {
      case 'Driving License':
        return ApiConstants.extractDL;
      case 'Aadhar':
        return ApiConstants.extractAadhaar;
      case 'Voters ID':
        return ApiConstants.extractVoterId;
      case 'PAN Card':
        return ApiConstants.extractPan;
      default:
        return ApiConstants.extractDL;
    }
  }

  String _verifyEndpoint(String cardType) {
    switch (cardType) {
      case 'Driving License':
        return ApiConstants.verifyDL;
      case 'Aadhar':
        return ApiConstants.verifyAadhaar;
      case 'Voters ID':
        return ApiConstants.verifyVoterId;
      case 'PAN Card':
        return ApiConstants.verifyPan;
      default:
        return ApiConstants.verifyDL;
    }
  }

  static Future<String> toBase64(String path) async {
    final bytes = await File(path).readAsBytes();
    return base64Encode(bytes);
  }

  // ── Duplicate guest check ─────────────────────────────────────────────────
  /// Returns true if a guest with [documentNo] and [cardType] already exists.
  /// [cardType] must be one of: Driving Licence, Aadhaar, PAN Card, Voters ID,
  /// Indian Passport, Passport, Other ID
  Future<bool> checkDuplicateGuest({
    required String documentNo,
    required String cardType,
  }) async {
    try {
      final url = await _prefs.getBaseUrl();
      final response =
          await _api.post(
                ApiConstants.checkDuplicateGuest,
                baseUrl: url,
                body: {
                  'Guest_DocumentNo': documentNo,
                  'Guest_CardType': cardType,
                },
                headers: await _authHeaders,
              )
              as Map<String, dynamic>;
      final status =
          response['Status'] as int? ?? response['status'] as int? ?? 0;
      return status == 1; // 1 = duplicate exists
    } catch (_) {
      return false; // on error, allow the user to proceed
    }
  }

  // ── Vehicle Types ─────────────────────────────────────────────────────────
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
}

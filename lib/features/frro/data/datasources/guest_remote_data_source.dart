import '../../../../core/config/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_base_helper.dart';
import '../../../../core/network/shared_preferences_provider.dart';
import '../models/guest_model.dart';

/// Remote data source for guest API operations
abstract class GuestRemoteDataSource {
  Future<List<GuestModel>> getGuestList({
    required int branchId,
    int userId = 0,
    int btnStatusOfCheckINOUT = 0,
  });

  Future<bool> checkIn({
    required int guestdataId,
    required int branchId,
    required String applicationId,
    int userId = 0,
  });

  Future<bool> checkOut({
    required int guestdataId,
    required int branchId,
    int userId = 0,
  });

  Future<bool> updateFrroSubmissionStatus({required int guestdataId});
}

class GuestRemoteDataSourceImpl implements GuestRemoteDataSource {
  final ApiBaseHelper apiHelper;
  final SharedPreferencesProvider prefs;

  GuestRemoteDataSourceImpl({required this.apiHelper, required this.prefs});

  Future<String> get _baseUrl => prefs.getBaseUrl();
  Future<String> get _token => prefs.getAccessToken();

  @override
  Future<List<GuestModel>> getGuestList({
    required int branchId,
    int userId = 0,
    int btnStatusOfCheckINOUT = 0,
  }) async {
    try {
      final url = await _baseUrl;
      final token = await _token;
      final response = await apiHelper.post(
        ApiConstants.getGuestData,
        baseUrl: url,
        body: {
          'Guestdata_id': 0,
          'btnStatusOfCheckINOUT': btnStatusOfCheckINOUT,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      // null = empty body (200 with no content) → treat as empty list
      if (response == null) return [];

      if (response is List) {
        return response
            .map((json) => GuestModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Any other shape (e.g. a Map with a message) → empty list
      return [];
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('Failed to fetch guest list: $e');
    }
  }

  @override
  Future<bool> checkIn({
    required int guestdataId,
    required int branchId,
    required String applicationId,
    int userId = 0,
  }) async {
    try {
      final url = await _baseUrl;
      final token = await _token;
      final response =
          await apiHelper.post(
                ApiConstants.updateCheckInStatus,
                baseUrl: url,
                body: {
                  'Guestdata_id': guestdataId,
                  'Branch_ID': branchId,
                  'guest_FrroChellan': applicationId,
                  'User_ID': userId,
                },
                headers: {'Authorization': 'Bearer $token'},
              )
              as Map<String, dynamic>;

      final status =
          response['Status'] as int? ?? response['status'] as int? ?? 0;
      return status == 1;
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('Check-in failed: $e');
    }
  }

  @override
  Future<bool> checkOut({
    required int guestdataId,
    required int branchId,
    int userId = 0,
  }) async {
    try {
      final url = await _baseUrl;
      final token = await _token;
      final response =
          await apiHelper.post(
                ApiConstants.updateCheckOutStatus,
                baseUrl: url,
                body: {
                  'Guestdata_id': guestdataId,
                  'Branch_ID': branchId,
                  'User_ID': userId,
                },
                headers: {'Authorization': 'Bearer $token'},
              )
              as Map<String, dynamic>;

      final status =
          response['Status'] as int? ?? response['status'] as int? ?? 0;
      return status == 1;
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('Check-out failed: $e');
    }
  }

  @override
  Future<bool> updateFrroSubmissionStatus({required int guestdataId}) async {
    try {
      final url = await _baseUrl;
      final token = await _token;
      final response =
          await apiHelper.post(
                ApiConstants.updateFrroBeforeCheckInStatus,
                baseUrl: url,
                body: {'Guestdata_id': guestdataId},
                headers: {'Authorization': 'Bearer $token'},
              )
              as Map<String, dynamic>;

      final status =
          response['Status'] as int? ?? response['status'] as int? ?? 0;
      return status == 1;
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('FRRO submission status update failed: $e');
    }
  }
}

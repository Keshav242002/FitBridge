import 'api_client.dart';

class ScheduleService {
  ScheduleService({required this.api});

  final ApiClient api;

  Future<ApiResponse> createRequest({
    required String memberId,
    required String trainerId,
    required DateTime scheduledFor,
    required String note,
  }) =>
      api.post('/call-requests', body: {
        'memberId': memberId,
        'trainerId': trainerId,
        'scheduledFor': scheduledFor.toIso8601String(),
        'note': note,
      });

  Future<ApiResponse> getRequests(String userId) =>
      api.get('/call-requests', query: {'userId': userId});

  Future<ApiResponse> approveRequest(String id) =>
      api.patch('/call-requests/$id', body: {'status': 'approved'});

  Future<ApiResponse> declineRequest(String id, {required String reason}) =>
      api.patch('/call-requests/$id', body: {
        'status': 'declined',
        'declineReason': reason,
      });
}

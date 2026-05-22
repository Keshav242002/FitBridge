import 'api_client.dart';

class SessionService {
  SessionService({required this.api});

  final ApiClient api;

  Future<ApiResponse> getSessions(String userId) =>
      api.get('/session-logs', query: {'userId': userId});
}

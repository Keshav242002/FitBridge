import 'package:wtf_shared/wtf_shared.dart';

const _kDefaultBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8787',
);

final apiClient = ApiClient(baseUrl: _kDefaultBase);

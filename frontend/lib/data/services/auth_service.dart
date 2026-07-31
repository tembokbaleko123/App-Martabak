import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<LoginResponse> login(String username, String pin) async {
    final response = await _client.post(
      ApiEndpoints.pinLogin,
      data: {
        'username': username,
        'pin': pin,
      },
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    await _client.setTokens(loginResponse.access, loginResponse.refresh);
    return loginResponse;
  }

  Future<void> changePin(String oldPin, String newPin) async {
    await _client.post(
      ApiEndpoints.changePin,
      data: {
        'old_pin': oldPin,
        'new_pin': newPin,
      },
    );
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _client.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    await _client.clearTokens();
  }

  Future<bool> hasValidToken() async {
    final token = await _client.getAccessToken();
    return token != null;
  }
}

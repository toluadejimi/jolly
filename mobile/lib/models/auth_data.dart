/// Auth response from login/register API.
class AuthData {
  AuthData({
    required this.apiKey,
    required this.user,
  });

  final String apiKey;
  final AuthUser user;

  factory AuthData.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return AuthData(
      apiKey: json['api_key'] as String? ?? '',
      user: userMap != null ? AuthUser.fromJson(userMap) : AuthUser(id: 0, email: '', firstname: '', lastname: ''),
    );
  }
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
  });

  final int id;
  final String email;
  final String firstname;
  final String lastname;

  String get displayName {
    final n = '${firstname.trim()} ${lastname.trim()}'.trim();
    return n.isEmpty ? email : n;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
    );
  }
}

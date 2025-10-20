class User {
  final String userId;
  final String email;
  final String username;
  final String? fullName;
  final String? profilePicture;
  final String role;
  final bool bioAuthEnabled;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.email,
    required this.username,
    this.fullName,
    this.profilePicture,
    required this.role,
    this.bioAuthEnabled = false,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'] ?? json['userId'] ?? '',
      email: json['email'] ?? '',
      username: json['displayName'] ?? json['username'] ?? '',
      fullName: json['displayName'] ?? json['fullName'],
      profilePicture: json['profilePicture'],
      role: json['role'] ?? 'User',
      bioAuthEnabled: json['bioAuthEnabled'] ?? false,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'role': role,
      'bioAuthEnabled': bioAuthEnabled,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String username;
  final String? fullName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.username,
    this.fullName,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'displayName': fullName,
    };
  }
}

class AuthResponse {
  final String token;
  final User user;
  final String message;

  AuthResponse({
    required this.token,
    required this.user,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      message: json['message'] ?? 'Success',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'message': message,
    };
  }
}
import 'user.dart';

class Token {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiry;
  final DateTime? refreshTokenExpiry;

  Token({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      accessTokenExpiry: json['accessTokenExpiry'] != null
          ? DateTime.parse(json['accessTokenExpiry'])
          : null,
      refreshTokenExpiry: json['refreshTokenExpiry'] != null
          ? DateTime.parse(json['refreshTokenExpiry'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiry': accessTokenExpiry?.toIso8601String(),
      'refreshTokenExpiry': refreshTokenExpiry?.toIso8601String(),
    };
  }

  bool get isAccessTokenExpired {
    if (accessTokenExpiry == null) return false;
    return DateTime.now().isAfter(accessTokenExpiry!);
  }

  bool get isRefreshTokenExpired {
    if (refreshTokenExpiry == null) return false;
    return DateTime.now().isAfter(refreshTokenExpiry!);
  }
}

class AuthResponse {
  final bool success;
  final String? message;
  final Token? tokens;
  final User? user;

  AuthResponse({
    required this.success,
    this.message,
    this.tokens,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      tokens: json['data']?['tokens'] != null
          ? Token.fromJson(json['data']['tokens'])
          : null,
      user: json['data']?['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
    );
  }
}

// Import statement for User model - this will be added at the top when this model is used
// import 'user.dart';

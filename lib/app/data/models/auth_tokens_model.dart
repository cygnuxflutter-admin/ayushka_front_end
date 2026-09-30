/// Model representing authentication tokens returned by login and refresh-token endpoints.
class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String expiresIn;
  final String? refreshTokenExpiresIn;

  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = '1h',
    this.refreshTokenExpiresIn,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: (json['accessToken'] ?? json['token']) as String? ?? '',
      refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as String? ?? '1h',
      refreshTokenExpiresIn: json['refreshTokenExpiresIn'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      if (refreshTokenExpiresIn != null) 'refreshTokenExpiresIn': refreshTokenExpiresIn,
    };
  }
}

/// Model representing an authenticated user or a system user in the Ayushka portal.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // e.g. 'Admin', 'Doctor', 'Staff', 'Farm Manager'
  final String? roleId;
  final String? token;
  final String? refreshToken;
  final String? avatarUrl;
  final String? username;
  final String? gaushalaId;
  final String? gaushalaName;
  final bool isActive;
  final bool isDeleted;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleId,
    this.token,
    this.refreshToken,
    this.avatarUrl,
    this.username,
    this.gaushalaId,
    this.gaushalaName,
    this.isActive = true,
    this.isDeleted = false,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true if this user has Administrator privileges.
  bool get isAdmin {
    final r = role.toLowerCase().trim();
    if (r == 'admin' || r == 'super admin' || r == 'superadmin' || r.contains('admin')) {
      return true;
    }
    if (username?.toLowerCase().trim() == 'admin') {
      return true;
    }
    return false;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String roleStr = 'User';
    String? rId;
    if (json['role'] is String && (json['role'] as String).trim().isNotEmpty) {
      roleStr = json['role'] as String;
    } else if (json['roleId'] is Map && json['roleId']['roleName'] != null) {
      roleStr = json['roleId']['roleName'].toString();
      rId = (json['roleId']['_id'] ?? json['roleId']['id'])?.toString();
    } else if (json['role'] is Map && json['role']['roleName'] != null) {
      roleStr = json['role']['roleName'].toString();
      rId = (json['role']['_id'] ?? json['role']['id'])?.toString();
    } else if (json['roleName'] != null && json['roleName'].toString().trim().isNotEmpty) {
      roleStr = json['roleName'].toString();
    }

    if (rId == null && json['roleId'] != null) {
      if (json['roleId'] is String) {
        rId = json['roleId'] as String;
      } else if (json['roleId'] is Map) {
        rId = (json['roleId']['_id'] ?? json['roleId']['id'])?.toString();
      }
    }

    String? gId;
    String? gName;

    final rawGaushala = json['gaushalaId'] ??
        json['gaushala_id'] ??
        json['gaushala'] ??
        json['gaushalas'] ??
        json['defaultGaushala'] ??
        json['default_gaushala'];
    if (rawGaushala is List && rawGaushala.isNotEmpty) {
      final firstG = rawGaushala.first;
      if (firstG is Map) {
        gId = (firstG['_id'] ?? firstG['id'])?.toString();
        gName = (firstG['gaushalaName'] ?? firstG['name'])?.toString();
      } else if (firstG != null) {
        gId = firstG.toString();
      }
    } else if (rawGaushala is Map) {
      gId = (rawGaushala['_id'] ?? rawGaushala['id'])?.toString();
      gName = (rawGaushala['gaushalaName'] ?? rawGaushala['name'])?.toString();
    } else if (rawGaushala != null) {
      gId = rawGaushala.toString();
    }

    if (gName == null) {
      if (json['gaushalaName'] != null) {
        gName = json['gaushalaName']?.toString();
      } else if (json['gaushala_name'] != null) {
        gName = json['gaushala_name']?.toString();
      }
    }

    final bool active = json['isActive'] != null
        ? (json['isActive'] == true || json['isActive'] == 1 || json['isActive'].toString() == 'true')
        : true;
    final bool deleted = json['isDeleted'] == true || json['isDeleted'] == 1 || json['isDeleted'].toString() == 'true';

    return UserModel(
      id: (json['id'] ?? json['_id']) as String? ?? '',
      name: json['name'] as String? ?? '',
      email: (json['email'] ?? json['emailId']) as String? ?? '',
      role: roleStr,
      roleId: rId,
      token: (json['token'] ?? json['accessToken']) as String?,
      refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      username: json['username'] as String?,
      gaushalaId: gId,
      gaushalaName: gName,
      isActive: active,
      isDeleted: deleted,
      fcmToken: json['fcmToken']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'email': email,
      'emailId': email,
      'role': role,
      'roleId': roleId,
      'token': token,
      'refreshToken': refreshToken,
      'avatar_url': avatarUrl,
      'username': username,
      'gaushalaId': gaushalaId,
      'gaushalaName': gaushalaName,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? roleId,
    String? token,
    String? refreshToken,
    String? avatarUrl,
    String? username,
    String? gaushalaId,
    String? gaushalaName,
    bool? isActive,
    bool? isDeleted,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      gaushalaId: gaushalaId ?? this.gaushalaId,
      gaushalaName: gaushalaName ?? this.gaushalaName,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

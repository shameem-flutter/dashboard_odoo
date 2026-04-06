import 'dart:convert';

class AuthModel {
  final int uid;
  final String name;
  final String username;
  final int companyId;
  final int partnerId;
  final String sessionId;
  final String db;
  final String? lang;
  final String? tz;

  AuthModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.companyId,
    required this.partnerId,
    required this.sessionId,
    required this.db,
    this.lang,
    this.tz,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Check if it's the full response or just the 'result' object
    final result = json['result'] ?? json;
    
    final userContext = result['user_context'] ?? {};

    return AuthModel(
      uid: result['uid'] ?? 0,
      name: result['name'] ?? '',
      username: result['username'] ?? '',
      companyId: result['company_id'] ?? 0,
      partnerId: result['partner_id'] ?? 0,
      sessionId: result['session_id'] ?? '',
      db: result['db'] ?? '',
      lang: userContext['lang'],
      tz: userContext['tz'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'company_id': companyId,
      'partner_id': partnerId,
      'session_id': sessionId,
      'db': db,
      'user_context': {
        'lang': lang,
        'tz': tz,
      },
    };
  }

  String encode() => json.encode(toJson());

  factory AuthModel.decode(String str) => AuthModel.fromJson(json.decode(str));
}

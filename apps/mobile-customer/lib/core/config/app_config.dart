class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '31f90299731945e19630e2b96ee78154',
  );
}

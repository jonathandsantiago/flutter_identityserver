class Secrets {
  static const String AUTH_CLIENT_ID = 'seu client id';
  static const String AUTH_DOMAIN = 'dominio do seu SSO sem HTTP ou HTTPS';
  static const String AUTH_REDIRECT_URI =
      'nome da aplicação cadastrada no SSO e aplicada na configuração do `android` e `ios`:/oauthredirect';
  static const String AUTH_ISSUER = 'https://$AUTH_DOMAIN';
  static const String AUTH_SECRET = 'seu secrete';
}

# flutter_identityserver

Projeto mobile com autenticação em Identity Server 4
* Clonar projeto: `git clone https://github.com/jonathandsantiago/flutter_identityserver.git`

# Bibliotecas
* flutter_appauth `flutter pub add flutter_appauth`
* http `flutter pub add http`
* flutter_secure_storage `flutter pub add flutter_secure_storage`

### Arquitetura projeto
A arquitetura do projeto esta organizada no seguinte formato:
```
    lib
        src
            models
            services
            ui
        app.dart
        secrets.dart --Este arquivo não esta disponível no código o mesmo devera ser criado.
    main.dart
```
* Em `services` está o `usuario_service.dart` serviço responsável por se comunicar com o nosso SSO Contendo:
    * `login` método responsável por logar o usuário;
    * `getUserInfo` método responsável por obter as informações do usuário logado;
    * `logout` método responsável por deslogar o usuário;
    * `init` método responsável por validar se o token do usuário ainda é valido batendo no endpoint `refresh_token` do SSO, caso for um token expirado será deslogado o usuário;
* A classe `secrets.dart` Armazena as variaveis de conexão com o SSO.
    * `AUTH_CLIENT_ID` Cliente Id;
    * `AUTH_DOMAIN` domínio da aplicação SSO sem o protocolo https ou http ex: `sso.com.br`;
    * `AUTH_REDIRECT_URI` nome da aplicação cadastrada no SSO e aplicada na configuração do `android` e `ios`;
    * `AUTH_ISSUER` domínio da aplicação SSO com o protocolo https ou http ex: `https://$AUTH_CLIENT_ID`;
    * `AUTH_SECRET` secret da aplicação cadastrada no SSO
    
### Configuração Android
* <b>Build</b>: Em `android -> app -> build.gradle`
    * Insira o id da aplicação em `applicationId` no meu caso coloquei o nome `appflutteridentityserver.com`, lembrando que o mesmo deverá estar cadastrada na aplicação identity server com o mesmo nome.
    * Caso for testar em uma versão mais antiga do android altere o `minSdkVersion`
    no meu caso alterei para `18`;
    * Insira o 
    ```
    manifestPlaceholders += [
                    'appAuthRedirectScheme': 'appflutteridentityserver.com'
            ]
    ```
    com o mesmo nome informado no `applicationId`;
* <b>AndroidManifest</b>: Em `android -> app -> src -> main -> AndroidManifest.xml` adicione o seguinte treixo em `application`: 
    ```
        <queries>
            <intent>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" />
            </intent>
            <intent>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.APP_BROWSER" />
                <data android:scheme="https" />
            </intent>
        </queries>
    ```
import 'package:flutter_identityserver/src/services/usuario_service.dart';
import 'package:flutter_identityserver/src/ui/home.dart';
import 'package:flutter_identityserver/src/ui/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final UsuarioService _usuarioService = UsuarioService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool isBusy = false;
  bool isLoggedIn = false;
  late String errorMessage = '';
  late String name = '';
  late String picture = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login IdentityServer',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Login IdentityServer'),
        ),
        body: Center(
          child: isBusy
              ? const CircularProgressIndicator()
              : isLoggedIn
                  ? Home(logoutAction, name, picture)
                  : Login(loginAction, errorMessage),
        ),
      ),
    );
  }

  @override
  void initState() {
    initAction();
    super.initState();
  }

  Future<void> loginAction() async {
    setState(() {
      isBusy = true;
      errorMessage = '';
    });

    try {
      final user = await _usuarioService.login();

      if (user != null) {
        setState(() {
          isBusy = false;
          isLoggedIn = true;
          name = user.profile!['name'] as String;
        });
      }
    } on Exception catch (e, s) {
      debugPrint('login error: $e - stack: $s');

      setState(() {
        isBusy = false;
        isLoggedIn = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> initAction() async {
    final String? storedRefreshToken =
        await secureStorage.read(key: 'refresh_token');
    if (storedRefreshToken == null) return;

    setState(() {
      isBusy = true;
    });

    try {
      final user = await _usuarioService.init(storedRefreshToken);
      if (user != null) {
        setState(() {
          isBusy = false;
          isLoggedIn = true;
          name = user.profile!['name'] as String;
        });
      }
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
      await _usuarioService.logout();
      setState(() {
        isLoggedIn = false;
        isBusy = false;
      });
    }
  }

  Future<void> logoutAction() async {
    await _usuarioService.logout();
    setState(() {
      isLoggedIn = false;
      isBusy = false;
    });
  }
}

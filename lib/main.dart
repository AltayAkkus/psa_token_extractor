// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///////////////////////////////////////////////////////////////////////////////
/// Please make sure to follow the setup instructions below
///
/// Please take a look at:
/// - example/android/app/main/AndroidManifest.xml for Android.
///
/// - example/ios/Runner/Runner.entitlements for Universal Link sample.
/// - example/ios/Runner/Info.plist for Custom URL scheme sample.
///
/// You can launch an intent on an Android Emulator like this:
///    adb shell am start -a android.intent.action.VIEW \
///     -d "sample://open.my.app/#/book/hello-world"
///
///
/// On windows & macOS:
///   The simpliest way to test it is by
///   opening your browser and type: sample://foo/#/book/hello-world2
///////////////////////////////////////////////////////////////////////////////


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();

    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      print('getInitialAppLink: $appLink');
      openAppLink(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('onAppLink: $uri');
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) {
    print("called " + (uri.queryParameters['code'] ?? "No Code provided"));
    _navigatorKey.currentState?.pushNamed(uri.queryParameters['code'] ?? "No Code provided");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      initialRoute: "/",
      debugShowCheckedModeBanner : false,
      onGenerateRoute: (RouteSettings settings) {
        Widget routeWidget = defaultScreen();

        // Mimic web routing
        final token = settings.name;
        if (token != "/") {
          routeWidget = customScreen(token ?? "No Code provided");
        }
        return MaterialPageRoute(
          builder: (context) => routeWidget,
          settings: settings,
          fullscreenDialog: true,
        );
      },
    );
  }

  Widget defaultScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to PSA Token Extractor')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('''
            Use the appropriate PSA app (e.g. MyOpel) to login.
            You should get the option, to open the link with PSA Token Extractor, choose that option.
            If you don't, try to open the link in a browser and then choose the PSA Token Extractor app.
            '''),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget customScreen(String token) {
    return Scaffold(
      appBar: AppBar(title: const Text('Got token')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Token: $token'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Token copied to clipboard')),
                );
              },
              child: Text('Copy Token'),
            ),
          ],
        ),
      ),
    );
  }
}
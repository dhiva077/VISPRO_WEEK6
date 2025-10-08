import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'details_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;
  String _status = 'Waiting for link...';
  String? _latestLink;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // 1) handle cold start
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleLink(initialLink);
    } catch (e) {
      setState(() => _status = 'Failed to get initial link: $e');
    }

    // 2) handle links while app is running
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      if (uri != null) _handleLink(uri);
    }, onError: (err) {
      setState(() => _status = 'Link stream error: $err');
    });
  }

  void _handleLink(Uri uri) {
    final linkStr = uri.toString();
    setState(() {
      _latestLink = linkStr;
      _status = 'Received link: $linkStr';
    });

    // Support both forms:
    //  - myapp://details/42  (host = 'details', pathSegments = ['42'])
    //  - myapp://example/details/42 (host != 'details', pathSegments may include 'details')
    final host = uri.host;
    final segments = uri.pathSegments;

    String? itemId;

    if (host == 'details' && segments.isNotEmpty) {
      itemId = segments[0];
    } else if (segments.isNotEmpty && segments[0] == 'details' && segments.length > 1) {
      itemId = segments[1];
    }

    if (itemId != null) {
      // gunakan navigatorKey untuk menghindari masalah context
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => DetailsPage(itemId: itemId!)),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Links Demo',
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Text(
            _latestLink != null ? _status : 'Waiting for link...',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
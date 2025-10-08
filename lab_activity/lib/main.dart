import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  String _status = 'Waiting for link...';

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle link ketika app pertama kali dibuka
    final Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _handleLink(initialLink);

    // Dengarkan link baru saat app masih hidup
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    setState(() => _status = 'Received link: $uri');

    if (uri.host == 'details') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'unknown';
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(id: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Links Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Text(_status),
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(child: Text('You opened item ID: $id')),
    );
  }
}

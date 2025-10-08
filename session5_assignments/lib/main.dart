import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  runApp(MyApp());
}

/// Simple product model
class Product {
  final int id;
  final String name;
  final String description;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}

/// A tiny in-memory repository for demo products.
class ProductRepository {
  ProductRepository._privateConstructor();
  static final ProductRepository instance = ProductRepository._privateConstructor();

  final List<Product> _products = List.generate(
    8,
    (i) => Product(
      id: i + 1,
      name: 'Product ${(i + 1)}',
      description: 'Deskripsi singkat untuk product ${(i + 1)}.',
      price: 10.0 + (i * 5),
    ),
  );

  Product? getById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> get allProducts => List.unmodifiable(_products);
}

/// Very small cart model (singleton)
class CartModel {
  CartModel._private();
  static final CartModel instance = CartModel._private();

  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);
  void add(Product p) => _items.add(p);
  void remove(Product p) => _items.remove(p);
  void clear() => _items.clear();
}

/// MyApp handles deep links via a navigatorKey to navigate from outside the widget tree.
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    _handleInitialUri();
    _handleIncomingLinks();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        _navigateToUri(uri);
      }
    } on FormatException {
      // ignore malformed
    }
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _navigateToUri(uri);
      }
    }, onError: (err) {
      // optionally log
    });
  }

  void _navigateToUri(Uri uri) {
    // Expected: shopmate://product/{id}
    if (uri.scheme == 'shopmate' && uri.host == 'product') {
      final idSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      if (idSegment != null) {
        final int? id = int.tryParse(idSegment);
        if (id == null) {
          navigatorKey.currentState?.pushNamed('/error', arguments: 'Invalid product id: $idSegment');
          return;
        }
        final prod = ProductRepository.instance.getById(id);
        if (prod == null) {
          navigatorKey.currentState?.pushNamed('/error', arguments: 'Product with id $id not found');
          return;
        }
        // Navigate to product details (push so user can back to home)
        navigatorKey.currentState?.pushNamed('/product', arguments: id);
        return;
      }
    }
    // if not handled:
    navigatorKey.currentState?.pushNamed('/error', arguments: 'Unsupported deep link: $uri');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopMate',
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => MainScreen(),
        '/product': (context) => ProductDetailScreen(),
        '/cart': (context) => CartScreen(),
        '/about': (context) => AboutScreen(),
        '/error': (context) => DeepLinkErrorScreen(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
    );
  }
}

/// MainScreen provides BottomNavigation for Home / Cart / About
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  static const _titles = ['Home', 'Cart', 'About'];

  @override
  Widget build(BuildContext context) {
    final widgets = [
      HomeScreen(),
      CartScreen(),
      AboutScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('ShopMate — ${_titles[_index]}')),
      body: IndexedStack(index: _index, children: widgets),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}

/// HomeScreen lists products and navigates using named routes + arguments
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final products = ProductRepository.instance.allProducts;
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = products[i];
        return Card(
          child: ListTile(
            title: Text(p.name),
            subtitle: Text(p.description),
            trailing: Text('\$${p.price.toStringAsFixed(2)}'),
            onTap: () {
              // pass the product id as argument
              Navigator.pushNamed(context, '/product', arguments: p.id);
            },
          ),
        );
      },
    );
  }
}

/// Product Detail screen: reads id from arguments and displays or shows not-found
class ProductDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    int? id;
    if (args is int) id = args;
    else if (args is String) id = int.tryParse(args);
    final product = (id != null) ? ProductRepository.instance.getById(id) : null;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product not found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Product not found or invalid id.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(product.description),
            const SizedBox(height: 12),
            Text('Price: \$${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                CartModel.instance.add(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} ditambahkan ke cart')),
                );
              },
              child: const Text('Add to Cart'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// CartScreen: shows items in the cart
class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = CartModel.instance.items;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (items.isEmpty) ...[
            const Text('Cart kosong. Tambahkan produk dari Home.'),
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final p = items[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        CartModel.instance.remove(p);
                        _refresh();
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                CartModel.instance.clear();
                _refresh();
              },
              child: const Text('Clear Cart'),
            ),
          ],
        ],
      ),
    );
  }
}

/// About screen
class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text('ShopMate — contoh integrasi navigation + deep linking\n\nDibuat untuk tugas Visual Programming.'),
      ),
    );
  }
}

/// Error screen for bad deep links
class DeepLinkErrorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final msg = ModalRoute.of(context)!.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Link Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg ?? 'Invalid or unsupported deep link'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

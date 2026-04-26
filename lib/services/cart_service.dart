import '../models/cart_item.dart';
import '../models/product.dart';

// Simple in-memory cart — lives for the duration of the app session
class CartService {
  // Singleton so the same cart is accessible from any screen
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  // Add product — if already in cart, increase quantity
  void addProduct(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
  }

  void increaseQuantity(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) _items[index].quantity++;
  }

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }
  }

  void removeProduct(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
  }

  void clear() => _items.clear();
}
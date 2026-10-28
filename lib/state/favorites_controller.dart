import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/core/api/api.dart';
import 'package:studentos/core/api/api_client.dart';

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String id) {
    final next = <String>{...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = Set<String>.unmodifiable(next);
  }
}

final cartProvider = NotifierProvider<CartController, Map<String, int>>(
  CartController.new,
);

class CartController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => <String, int>{};

  void add(String id, [int quantity = 1]) {
    state = <String, int>{...state, id: (state[id] ?? 0) + quantity};
  }

  Future<String?> addProduct(String productId, [int quantity = 1]) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      Api.addToCart,
      data: <String, dynamic>{
        'source': 'app',
        'id': productId,
        'quantity': quantity,
        'is_preorder': '0',
      },
    );
    final body = response.data;
    if (response.isSuccess &&
        body is Map<String, dynamic> &&
        body['result'] == true) {
      add(productId, quantity);
      return null;
    }

    return body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'Add to cart failed.'
        : response.message ?? 'Add to cart failed.';
  }

  void setQuantity(String id, int quantity) {
    final next = <String, int>{...state};
    if (quantity <= 0) {
      next.remove(id);
    } else {
      next[id] = quantity;
    }
    state = Map<String, int>.unmodifiable(next);
  }

  void remove(String id) {
    final next = <String, int>{...state};
    final quantity = next[id] ?? 0;
    if (quantity <= 1) {
      next.remove(id);
    } else {
      next[id] = quantity - 1;
    }
    state = Map<String, int>.unmodifiable(next);
  }

  int get totalItems => state.values.fold(0, (sum, value) => sum + value);

  void clear() {
    state = const <String, int>{};
  }
}

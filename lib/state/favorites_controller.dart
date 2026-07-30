import 'package:flutter_riverpod/flutter_riverpod.dart';

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

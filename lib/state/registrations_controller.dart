import 'package:flutter_riverpod/flutter_riverpod.dart';

final registrationsProvider = NotifierProvider<RegistrationsController, Set<String>>(RegistrationsController.new);

class RegistrationsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void register(String eventId) => state = Set<String>.unmodifiable(<String>{...state, eventId});
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studentos/data/demo_data.dart';
import 'package:studentos/data/models.dart';

final notesProvider = NotifierProvider<NotesController, List<NoteItem>>(NotesController.new);

class NotesController extends Notifier<List<NoteItem>> {
  @override
  List<NoteItem> build() => List<NoteItem>.unmodifiable(initialNotes);

  void add({required String title, required String body, required Color color}) {
    if (title.trim().isEmpty && body.trim().isEmpty) return;
    final nextId = state.isEmpty ? 1 : state.map((item) => item.id).reduce((a, b) => a > b ? a : b) + 1;
    state = List<NoteItem>.unmodifiable(<NoteItem>[
      NoteItem(
        id: nextId,
        title: title.trim().isEmpty ? 'Untitled Note' : title.trim(),
        body: body.trim(),
        color: color,
        date: 'Today',
      ),
      ...state,
    ]);
  }

  void remove(int id) {
    state = state.where((note) => note.id != id).toList(growable: false);
  }
}

import 'package:flutter/widgets.dart';

class NotifierList<T> extends ValueNotifier<List<T>> {
  NotifierList() : super([]);

  void add(T value) {
    this.value = [...this.value, value];  
  }

  void remove(T value) {
    final currentItems = List<T>.from(this.value);
    currentItems.remove(value);
    this.value = currentItems;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

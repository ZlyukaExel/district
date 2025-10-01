import 'package:flutter/widgets.dart';

class NotifierList<T> with ChangeNotifier {
  final ValueNotifier<List<T>> list = ValueNotifier<List<T>>([]);

  void add(T value) {
    list.value = [...list.value, value];
  }

  void remove(T value) {
    final currentItems = list.value;
    currentItems.remove(value);
    list.value = [...currentItems];
  }
}

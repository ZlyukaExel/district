import 'package:district/structures/linked_list/node.dart';

class LinkedList<T> {
  Node<T>? _head;
  int _length = 0;
  int get length => _length;

  // Добавление в конец списка
  void add(T value) {
    // Если головы нет, устанавливаем её
    if (_head == null) {
      _head = Node(value);
      return;
    }

    // Идем в конец списка
    Node<T> current = _head!;
    while (current.next != null) {
      current = current.next!;
    }
    current.next = Node(value);

    _length++;
  }

  // Удаление первого по значению
  void remove(T value) {
    if (_head == null) {
      return;
    }

    // Проверка первого элемента отдельно
    if (_head!.value == value) {
      _head = _head!.next;
      return;
    }

    // Проходим по всему списку
    Node<T> current = _head!;
    while (current.next != null) {
      if (current.next!.value == value) {
        // При совпадении меняем ссылку на след. элемент
        current.next = current.next!.next;
        return;
      }
      current = current.next!;
    }

    _length--;
  }

  bool contains(T value) {
    if (_head == null) {
      return false;
    }

    // Проверка первого элемента отдельно
    if (_head!.value == value) {
      _head = _head!.next;
      return true;
    }

    // Проходим по всему списку
    Node<T> current = _head!;
    while (current.next != null) {
      if (current.next!.value == value) {
        return true;
      }
      current = current.next!;
    }

    return false;
  }

  T? get(int id) {
    if (id < 0 || id >= _length) {
      throw RangeError.index(
        id,
        this,
        'index',
        'Индекс $id за переделами длины $_length',
      );
    }

    if (_head == null) {
      return null;
    }

    if (id == 0) {
      return _head!.value;
    }

    int i = 0;
    Node<T>? current = _head;
    while (current!.next != null) {
      if (id == i) {
        return current.value;
      }
      i++;
    }

    return null;
  }
}

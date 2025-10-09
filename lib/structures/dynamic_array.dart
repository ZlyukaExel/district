class DynamicArray<T> {
  List<T?> _data;

  int _length = 0;
  int get _maxLength => _data.length;
  int get length => _length;

  DynamicArray([int capacity = 4]) : _data = List.filled(capacity, null);

  // Добавление в конец
  void add(T element) {
    if (_length == _maxLength) {
      _resize();
    }
    _data[_length] = element;
    _length++;
  }

  // Достаем элемент по индексу
  T get(int id) {
    if (id < 0 || id >= _length) {
      throw RangeError.index(
        id,
        this,
        'index',
        'Индекс $id за переделами длины $_length',
      );
    }
    return _data[id]!;
  }

  // Меняем значение элемента
  void set(int id, T element) {
    if (id < 0 || id >= _length) {
      throw RangeError.index(
        id,
        this,
        'index',
        'Индекс $id за переделами длины $_length',
      );
    }
    _data[id] = element;
  }

  // Удаляем элемент по индексу
  void remove(int id) {
    if (id < 0 || id >= _length) {
      throw RangeError.index(
        id,
        this,
        'index',
        'Индекс $id за переделами длины $_length',
      );
    }

    // Перемещаем все элементы справа влево
    for (int i = id; i < _length - 1; i++) {
      _data[i] = _data[i + 1];
    }

    _length--;
    _data[_length] = null;
  }

  // Увеличиваем размер массива в два раза
  void _resize() {
    int newCapacity = _maxLength * 2;
    List<T?> newData = List.filled(newCapacity, null);
    for (int i = 0; i < _length; i++) {
      newData[i] = _data[i];
    }
    _data = newData;
  }
}

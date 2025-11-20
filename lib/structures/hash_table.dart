class HashTable<K, V> {
  static const int _initialCapacity = 16;
  static const double _loadFactor = 0.75;

  late List<List<MapEntry<K, V>>> _buckets;
  int _size = 0;

  HashTable() {
    _buckets = List.generate(_initialCapacity, (_) => []);
  }

  int _hash(K key) {
    return (key.hashCode & 0x7fffffff) % _buckets.length;
  }

  void put(K key, V value) {
    if (_size / _buckets.length > _loadFactor) {
      _resize();
    }

    int index = _hash(key);
    List<MapEntry<K, V>> bucket = _buckets[index];

    for (int i = 0; i < bucket.length; i++) {
      if (bucket[i].key == key) {
        bucket[i] = MapEntry(key, value);
        return;
      }
    }

    bucket.add(MapEntry(key, value));
    _size++;
  }

  V? get(K key) {
    int index = _hash(key);
    List<MapEntry<K, V>> bucket = _buckets[index];

    for (final entry in bucket) {
      if (entry.key == key) {
        return entry.value;
      }
    }
    return null;
  }

  bool remove(K key) {
    int index = _hash(key);
    List<MapEntry<K, V>> bucket = _buckets[index];

    for (int i = 0; i < bucket.length; i++) {
      if (bucket[i].key == key) {
        bucket.removeAt(i);
        _size--;
        return true;
      }
    }
    return false;
  }

  bool containsKey(K key) {
    return get(key) != null;
  }

  void _resize() {
    List<MapEntry<K, V>> allEntries = [];
    for (final bucket in _buckets) {
      allEntries.addAll(bucket);
    }

    _buckets = List.generate(_buckets.length * 2, (_) => []);
    _size = 0;

    for (final entry in allEntries) {
      put(entry.key, entry.value);
    }
  }

  int get size => _size;

  List<V> getValues() {
    List<V> values = [];
    for (final bucket in _buckets) {
      for (final entry in bucket) {
        values.add(entry.value);
      }
    }
    return values;
  }

  List<K> getKeys() {
    List<K> keys = [];
    for (final bucket in _buckets) {
      for (final entry in bucket) {
        keys.add(entry.key);
      }
    }
    return keys;
  }
}
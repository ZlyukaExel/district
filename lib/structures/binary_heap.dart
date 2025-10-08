class BinaryHeap {
  final List<int> _heap = [];
  
  void add(int value) {
    _heap.add(value);
    _bubbleUp(_heap.length - 1);
  }
  
  int? removeMin() {
    if (_heap.isEmpty) return null;
    
    int min = _heap[0];
    int last = _heap.removeLast();
    
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    
    return min;
  }
  
  int? get min => _heap.isEmpty ? null : _heap[0];
  
  bool get isEmpty => _heap.isEmpty;
  
  void _bubbleUp(int index) {
    while (index > 0) {
      int parent = (index - 1) ~/ 2;
      if (_heap[index] >= _heap[parent]) break;
      
      _swap(index, parent);
      index = parent;
    }
  }
  
  void _bubbleDown(int index) {
    while (true) {
      int left = 2 * index + 1;
      int right = 2 * index + 2;
      int smallest = index;
      
      if (left < _heap.length && _heap[left] < _heap[smallest]) {
        smallest = left;
      }
      
      if (right < _heap.length && _heap[right] < _heap[smallest]) {
        smallest = right;
      }
      
      if (smallest == index) break;
      
      _swap(index, smallest);
      index = smallest;
    }
  }
  
  void _swap(int i, int j) {
    int temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}

// lib/structures/avl_tree.dart


class AVLTree {
  AVLNode? _root;

  void insert(int value) {
    _root = _insertNode(_root, value);
  }

  AVLNode? _insertNode(AVLNode? node, int value) {
    if (node == null) {
      return AVLNode(value);
    }

    if (value < node.value) {
      node.left = _insertNode(node.left, value);
    } else if (value > node.value) {
      node.right = _insertNode(node.right, value);
    } else {
      return node; 
    }

    node.height = 1 + (max(node.left?.height ?? 0, node.right?.height ?? 0));
    int balance = _getBalance(node);

    // Left-Left case
    if (balance > 1 && value < node.left!.value) {
      return _rotateRight(node);
    }

    // Right-Right case
    if (balance < -1 && value > node.right!.value) {
      return _rotateLeft(node);
    }

    // Left-Right case
    if (balance > 1 && value > node.left!.value) {
      node.left = _rotateLeft(node.left!);
      return _rotateRight(node);
    }

    // Right-Left case
    if (balance < -1 && value < node.right!.value) {
      node.right = _rotateRight(node.right!);
      return _rotateLeft(node);
    }

    return node;
  }

  bool search(int value) {
    return _searchNode(_root, value);
  }

  bool _searchNode(AVLNode? node, int value) {
    if (node == null) return false;

    if (value == node.value) return true;
    if (value < node.value) return _searchNode(node.left, value);
    return _searchNode(node.right, value);
  }

  AVLNode _rotateRight(AVLNode node) {
    AVLNode temp = node.left!;
    node.left = temp.right;
    temp.right = node;

    node.height = 1 + max(node.left?.height ?? 0, node.right?.height ?? 0);
    temp.height = 1 + max(temp.left?.height ?? 0, temp.right?.height ?? 0);

    return temp;
  }

  AVLNode _rotateLeft(AVLNode node) {
    AVLNode temp = node.right!;
    node.right = temp.left;
    temp.left = node;

    node.height = 1 + max(node.left?.height ?? 0, node.right?.height ?? 0);
    temp.height = 1 + max(temp.left?.height ?? 0, temp.right?.height ?? 0);

    return temp;
  }

  int _getBalance(AVLNode? node) {
    if (node == null) return 0;
    return (node.left?.height ?? 0) - (node.right?.height ?? 0);
  }

  List<int> inOrder() {
    List<int> result = [];
    _inOrderTraversal(_root, result);
    return result;
  }

  void _inOrderTraversal(AVLNode? node, List<int> result) {
    if (node == null) return;
    _inOrderTraversal(node.left, result);
    result.add(node.value);
    _inOrderTraversal(node.right, result);
  }
}

class AVLNode {
  int value;
  AVLNode? left;
  AVLNode? right;
  int height = 1;

  AVLNode(this.value);
}

int max(int a, int b) => a > b ? a : b;
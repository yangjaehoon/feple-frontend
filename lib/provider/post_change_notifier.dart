import 'package:flutter/foundation.dart';

class PostChangeNotifier extends ChangeNotifier {
  void notifyPostChanged() {
    notifyListeners();
  }
}

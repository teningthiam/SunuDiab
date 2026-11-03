import 'package:flutter/foundation.dart';

/// Onglet courant de la barre de navigation (permet aux écrans de changer d'onglet).
class ShellNav extends ChangeNotifier {
  int index = 0;
  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}

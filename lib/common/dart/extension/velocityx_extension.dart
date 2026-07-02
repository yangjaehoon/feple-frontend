import 'package:flutter/material.dart';

import '../../common.dart';

extension VxTextBuilderExtension on VxTextBuilder {
  Widget makeWithDefaultFont({Key? key}) {
    return make(key: key);
  }
}

extension VxSelectableTextBuilderExtension on VxSelectableTextBuilder {
  Widget makeWithDefaultFont({Key? key}) {
    return make(key: key);
  }
}

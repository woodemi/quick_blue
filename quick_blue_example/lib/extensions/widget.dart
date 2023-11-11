import 'package:flutter/material.dart';

extension ListExtension on Iterable<Widget> {
  List<Widget> spaced() => map((e) => Expanded(child: e)).toList();

  List<Widget> spacedWith({double spacing = 8}) => map((e) =>
          Expanded(child: Padding(padding: EdgeInsets.all(spacing), child: e)))
      .toList();

  List<Widget> padded({EdgeInsets padding = const EdgeInsets.all(8)}) =>
      map((e) => Padding(padding: padding, child: e)).toList();
}

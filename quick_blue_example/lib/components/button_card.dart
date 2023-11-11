import 'package:flutter/material.dart';

class ButtonCard extends StatelessWidget {
  final Widget child;
  final void Function() onTap;

  ButtonCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 10,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: child,
        ),
      );
}

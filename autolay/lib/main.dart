import 'package:cassowary/base.dart';
import 'package:cassowary/impl.dart';
import 'package:flutter/material.dart';

import 'autolayout.dart';

void main() => runApp(
      const MaterialApp(
        home: ColoredBoxes(),
      ),
    );

class ColoredBoxes extends StatefulWidget {
  const ColoredBoxes();

  @override
  _ColoredBoxesState createState() => _ColoredBoxesState();
}

class _ColoredBoxesState extends State<ColoredBoxes> {
  final _MyAutoLayoutDelegate delegate = _MyAutoLayoutDelegate();

  _ColoredBoxesState();

  @override
  Widget build(
    final BuildContext context,
  ) =>
      AutoLayout(
        delegate: delegate,
        children: <Widget>[
          AutoLayoutChild(
            rect: delegate.p1,
            child: ElevatedButton(
              child: const Text("Left"),
              onPressed: () => print("Left"),
            ),
          ),
          AutoLayoutChild(
            rect: delegate.p2,
            child: ElevatedButton(
              child: const Text("Center"),
              onPressed: () => print("Center"),
            ),
          ),
          AutoLayoutChild(
            rect: delegate.p3,
            child: ElevatedButton(
              child: const Text("Right"),
              onPressed: () => print("Right"),
            ),
          ),
          AutoLayoutChild(
            rect: delegate.p4,
            child: ElevatedButton(
              child: const Text("Hi"),
              onPressed: () => print("Hi"),
            ),
          ),
        ],
      );
}

class _MyAutoLayoutDelegate extends AutoLayoutDelegate<_MyAutoLayoutDelegate> {
  AutoLayoutRect p1 = AutoLayoutRect();
  AutoLayoutRect p2 = AutoLayoutRect();
  AutoLayoutRect p3 = AutoLayoutRect();
  AutoLayoutRect p4 = AutoLayoutRect();

  _MyAutoLayoutDelegate();

  @override
  List<Constraint> getConstraints(
    final AutoLayoutRect parent,
  ) =>
      <Constraint>[
        // Sum of widths of each box must be equal to that of the container
        parent.width.equals(p1.width + p2.width + p3.width),
        // The boxes must be stacked left to right
        p1.right <= p2.left,
        p2.right <= p3.left,
        // The widths of the first and the third boxes should be equal
        p1.width.equals(p3.width),
        // The width of the first box should be twice as much as that of the second
        p1.width.equals(p2.width * const ConstantMemberImpl(2.0)),
        // The height of the three boxes should be equal to that of the container
        p1.height.equals(p2.height),
        p2.height.equals(p3.height),
        p3.height.equals(parent.height),
        // The fourth box should be half as wide as the second and must be attached
        // to the right edge of the same (by its center)
        p4.width.equals(p2.width / const ConstantMemberImpl(2.0)),
        p4.height.equals(const ConstantMemberImpl(50.0)),
        p4.horizontalCenter.equals(p2.right),
        p4.verticalCenter.equals(p2.height / const ConstantMemberImpl(2.0)),
      ];

  @override
  bool shouldUpdateConstraints(
    final _MyAutoLayoutDelegate oldDelegate,
  ) =>
      true;
}

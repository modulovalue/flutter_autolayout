//import 'dart:math' as math;
//import 'dart:ui';
//
//import 'package:cassowary/cassowary.dart';
//import 'package:flutter/material.dart';
//
//double roundOffset(double x) => (x * window.devicePixelRatio).roundToDouble() / window.devicePixelRatio;
//
//// ignore: must_be_immutable
//class Box extends StatelessWidget {
//
//    final Widget Function(Box) child;
//    final Variable x = Variable(0);
//    final Variable y = Variable(0);
//    final Variable right = Variable(100.0);
//    final Variable bottom = Variable(100.0);
//
//    double _lastX;
//    double _lastY;
//    double _lastWidth;
//    double _lastHeight;
//
//    Box(this.child) {
//        update();
//    }
//
//    void update({double px, double py}) {
//        var x = this.x.value;
//        var y = this.y.value;
//        final right = this.right.value;
//        final bottom = this.bottom.value;
//
//        var w = math.max(0, right - x).toDouble();
//        var h = math.max(0, bottom - y).toDouble();
//
//        px ??= 0;
//        py ??= 0;
//        x -= px;
//        y -= py;
//
//        x = roundOffset(x);
//        y = roundOffset(y);
//        w = roundOffset(w);
//        h = roundOffset(h);
//
//        if (w != this._lastWidth)
//            this._lastWidth = w;
//
//        if (h != this._lastHeight)
//            this._lastHeight = h;
//
//        if (x == this._lastX && y == this._lastY)
//            return;
//
//        this._lastX = x;
//        this._lastY = y;
//    }
//
//    @override
//    Widget build(BuildContext context) {
//        return Positioned(
//            left: _lastX,
//            top: _lastY,
//            width: _lastWidth,
//            height: _lastHeight,
//            child: child(this),
//        );
//    }
//}
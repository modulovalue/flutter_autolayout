//import 'package:cassowary/cassowary.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/physics.dart';
//
//class MotionConstraint {
//
//    final Variable variable;
//    final double Function(double a, double b, double naturalEndPosition, double gestureStartPosition) op;
//    final double value;
//    final double overdragCoefficient;
//    final Simulation Function(double start, double end, double velocity) simulation;
//    final bool captive;
//
//    MotionConstraint({
//        @required this.simulation,
//        @required this.variable,
//        @required String op,
//        @required this.value,
//        this.overdragCoefficient = 0.75,
//        this.captive = false,
//    }) : this.op = (() {
//        switch (op) {
//            case '==':
//                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
//                    return b - a;
//                };
//            case '>=':
//                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
//                    if (a >= b)
//                        return 0.0;
//                    return b - a;
//                };
//            case '<=':
//                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
//                    if (a <= b)
//                        return 0.0;
//                    return b - a;
//                };
//            case '<':
//                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
//                    if (a < b)
//                        return 0.0;
//                    return b - a;
//                };
//            case '>':
//                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
//                    if (a > b)
//                        return 0.0;
//                    return b - a;
//                };
//
//            case '%':
//                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
//                    final nearest = b * (naturalEndPosition / b).roundToDouble();
//                    return nearest - a;
//                };
////            case '||':
////                return (double a, double b, double naturalEndPosition, double gestureStartPosition) {
////                    // From ES6, not in Safari yet.
////                    var MAX_SAFE_INTEGER = 9007199254740991;
////                    // Like modulo, but just finds the nearest in the array b.
////                    if (!Array.isArray(b)) return 0;
////                    var distance = MAX_SAFE_INTEGER;
////                    var nearest = naturalEndPosition;
////                    for (var i = 0; i < b.length; i++) {
////                        var dist = Math.abs(b[i] - naturalEndPosition);
////                        if (dist > distance) continue;
////                        distance = dist;
////                        nearest = b[i];
////                    }
////                    return nearest - a;
////                };
//        //          // Like modulo, but only snaps to the current or adjacent values. Really good for pagers.
//        //          adjacentModulo: function(a, b, naturalEndPosition, gestureStartPosition) {
//        //              if (gestureStartPosition === undefined) return ops.modulo(a, b, naturalEndPosition);
//        //
//        //              var startNearest = Math.round(gestureStartPosition/b);
//        //              var endNearest = Math.round(naturalEndPosition/b);
//        //
//        //              var difference = endNearest - startNearest;
//        //
//        //              // Make the difference at most 1, so that we're only going to adjacent snap points.
//        //              if (difference) difference /= Math.abs(difference);
//        //
//        //              var nearest = (startNearest + difference) * b;
//        //
//        //              return nearest - a;
//        //          },
//        }
//        throw Exception("Invalid operation for MotionConstraint '$op'");
//    }());
//
//    double delta({double naturalEndPosition, double gestureStartPosition}) {
//        naturalEndPosition ??= variable.value;
//
//        return this.op(variable.value, value, naturalEndPosition, gestureStartPosition);
//    }
//
//    Simulation createMotion(double start, double end, double velocity) {
//        return simulation(start, end, velocity);
//    }
////
////// Some random physics models to use in options. Not sure these belong here.
////MotionConstraint.underDamped = function() { return new Gravitas.Spring(1, 200, 20); }
////MotionConstraint.criticallyDamped = function() { return new Gravitas.Spring(1, 200, Math.sqrt(4 * 1 * 200)); }
////MotionConstraint.prototype.createMotion = function(startPosition) {
////    var motion = this.physicsModel ? this.physicsModel() : new Gravitas.Spring(1, 200, 20);//Math.sqrt(200 * 4));
////    motion.snap(startPosition);
////    return motion;
////}
//}
//

//import 'package:Neptune/modules/base/routes/flalom/motion_context.dart';
//import 'package:Neptune/modules/base/routes/flalom/multi_edit_solver.dart';
//import 'package:cassowary/cassowary.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/physics.dart';
//
//import 'motion_constraint.dart';
//
//// ignore_for_file: cascade_invocations
//
//class Manipulator {
//
//    Variable variable;
//    MultiEditSolver solver;
//    Axis axis;
//    MotionContext _motionContext;
//    dynamic motion;
//    dynamic animation;
//    String name;
//    MotionConstraint hitConstraint;
//    double constraintCoefficient = 1;
//    MotionState motionState;
//
//    Manipulator({@required this.variable, @required this.axis});
//
//    void onPanStart(DragStartDetails details) {
//        _motionContext.stopOthers(variable);
//        motionState.dragging = true;
//        motionState.dragStart = variable.value;
//        motionState.dragDelta = 0;
//        motionState.dragTriggerDelta = 0;
//        _update();
//    }
//
//    void onPanUpdate(DragUpdateDetails details) {
//        final delta = axis == Axis.horizontal ? details.delta.dx : details.delta.dy;
//        motionState.dragDelta = delta - this.motionState.dragTriggerDelta;
//        _update();
//    }
//
//    void onPanEnd(DragEndDetails details, TickerProvider vsync, Duration animationDuration) {
//        final velocity = axis == Axis.horizontal
//                         ? details.velocity.pixelsPerSecond.dx
//                         : details.velocity.pixelsPerSecond.dy;
//        motionState.dragging = false;
//        motionState.trialAnimation = true;
//        if (_motionContext != null)
//            _motionContext.update();
//        _createAnimation(velocity, vsync, animationDuration);
//        motionState.trialAnimation = false;
//    }
//
//    void setMotionContext(MotionContext motionContext) {
//        this._motionContext = motionContext;
//        this.solver = motionContext.solver();
//        this.solver.addConstraint(stayConstraint(variable));
//    }
//
//    Simulation createMotion(double x, double v) {
//        return FrictionSimulation(0.001, x, v);
//    }
//
//    void _update() {
//        // What state are we in?
//        //  1. Dragging -- we set the variable to the value specified and apply some
//        //     damping if we're in violation of a constraint.
//        //  2. Animating -- we have some momentum from a drag, and we're applying the
//        //     values of an animation to the variable. We need to react if we violate
//        //     a constraint.
//        //  3. Constraint animating -- we already violated a constraint and now we're
//        //     animating back to a non-violating position.
//        //  4. Nothing is going on, we shouldn't be editing.
//        void beginEdit() {
//            if (motionState.editing)
//                return;
//            solver.beginEdit(variable, Priority.strong);
//            motionState.editing = true;
//        }
//        if (motionState.dragging) {
//            // 1. Dragging.
//            // Kill any animations we already have.
//            motionState.cancelVelocityAnimation();
//            motionState.cancelConstraintAnimation();
//
//            this.motionState.velocityAnimationVelocity = 0;
//            this.motionState.constraintAnimationVelocity = 0;
//
//            var position = motionState.dragStart + motionState.dragDelta;
//            if (hitConstraint != null) {
//                solver.suggestValue(variable, position);
//
//                final violationDelta = this.hitConstraint.delta() / this.constraintCoefficient;
//
//                position += violationDelta * hitConstraint.overdragCoefficient;
//            }
//
//            this.solver.suggestValue(variable, position);
//        } else if (motionState.constraintAnimation != null) {
//            motionState.cancelVelocityAnimation();
//            beginEdit();
//            final position = motionState.constraintAnimationPosition;
//            solver.suggestValue(variable, position);
//            // If we're no longer in violation then we can kill the constraint animation and
//            // create a new velocity animation unless our constraint is captive (in which case
//            // we remain captured).
//            if (motionState.constraintAnimationConstraint.captive && motionState.constraintAnimationConstraint.delta() == 0) {
////                final velocity = motionState.constraintAnimationVelocity;
//                /// TODO
//                ///                this._createAnimation(velocity);
//            }
//        } else if (motionState.velocityAnimation != null) {
//            beginEdit();
//            final position = motionState.velocityAnimationPosition;
//            // We don't consider constraints here; we deal with them in didHitConstraint.
//            solver.suggestValue(variable, position);
//        } else {
//            if (motionState.editing)
//                return;
//            solver.endEdit(variable);
//            motionState.editing = false;
//            motionState.velocityAnimationVelocity = 0;
//            motionState.constraintAnimationVelocity = 0;
//        }
//        if (this._motionContext != null)
//            _motionContext.update();
//    }
//
//    void _createAnimation(double velocity, TickerProvider provider, Duration duration) {
//        if (this.motionState.dragging)
//            return;
//
//        // Create an animation from where we are. This is either just a regular motion or we're
//        // violating a constraint and we need to animate out of violation.
//        if (this.hitConstraint != null) {
//// Don't interrupt an animation caused by a constraint to enforce the same constraint.
//            // This can happen if the constraint is enforced by an underdamped spring, for example.
//            if (this.motionState.constraintAnimation != null) {
//                if (this.motionState.constraintAnimationConstraint == this.hitConstraint || this.motionState
//                    .constraintAnimationConstraint.captive)
//                    return;
//                this.motionState.cancelConstraintAnimation();
//            }
//
//            this.motionState.constraintAnimationConstraint = this.hitConstraint;
//
//            // Determine the current velocity and end point if no constraint had been hit. Some
//            // discontinuous constraint ops use this to determine which point they're going to snap to.
//            // ignore: parameter_assignments
//            velocity = motionState.velocityAnimation != null ? motionState.velocityAnimationVelocity : velocity;
//            var endPosition = variable.value;
//            if (motionState.velocityAnimation != null) {
//                /// TODO
//                ///                endPosition = motionState.velocityAnimation.value + 60;
//            } else if (velocity != null) {
//                final motion = createMotion(variable.value, velocity);
//                endPosition = motion.x(60);
//            }
//            var startPosition = motionState.dragStart;
//            // If the constraint isn't relative to our variable then we need to use the solver to
//            // get the appropriate startPosition and endPosition.
//            if (variable != hitConstraint.variable) {
//                final original = variable.value;
//                if (motionState.editing) {
//                    solver.suggestValue(variable, startPosition);
//                    solver.solve();
//                    startPosition = hitConstraint.variable.value;
//
//                    solver.suggestValue(variable, endPosition);
//                    solver.solve();
//                    endPosition = hitConstraint.variable.value;
//
//                    solver.suggestValue(variable, original);
//                    solver.solve();
//                } else {
//                    // XXX: Should start a temporary edit to avoid this...
//                    print('not editing; cannot figure out correct start/end positions for motion constraint');
//                }
//            }
//
//            // We pass through the "natural" end point and the start position. MotionConstraints
//            // shouldn't need velocity, so we don't pass that through. (Perhaps there's a constraint
//            // that does need it, then I'll put it back; haven't found that constraint yet).
//            final delta = this.hitConstraint.delta(naturalEndPosition: endPosition, gestureStartPosition: startPosition);
//
//            // Figure out how far we have to go to be out of violation. Because we use a linear
//            // constraint solver to surface violations we only need to remember the coefficient
//            // of a given violation.
//            final violationDelta = delta / this.constraintCoefficient;
//
//            // We always do the constraint animation when we've hit a constraint. If the constraint
//            // isn't captive then we'll fall out of it and into a regular velocity animation later
//            // on (this is how the ends of scroll springs work).
//            this.motionState.cancelConstraintAnimation();
//            this.motionState.cancelVelocityAnimation();
//            // ignore: unused_local_variable
//            final motion = this.hitConstraint.createMotion(variable.value, variable.value + violationDelta, velocity);
//
//            /// TODO
//            ///            this.motionState.constraintAnimation = Gravitas.createAnimation(motion,
//            ///                function() {
//            ///                self._motionState.constraintAnimationPosition = motion.x();
//            ///                self._motionState.constraintAnimationVelocity = motion.dx(); // unused.
//            ///                self._update();
//            ///
//            ///                if (motion.done()) {
//            ///                self._cancelAnimation('constraintAnimation');
//            ///                self._motionState.constraintAnimationConstraint = null;
//            ///                self._update();
//            ///                }
//            ///                });
//            return;
//        }
//    }
//
//    void fnHitConstraint(MotionConstraint constraint, double coefficient, double delta) {
//        if (constraint == this.hitConstraint) {
//            return;
//        }
//        this.hitConstraint = constraint;
//        this.constraintCoefficient = coefficient;
//
//        if (this.motionState.dragging) {
//            this._update();
//            return;
//        }
//
//        if (this.motionState.trialAnimation)
//            return;
//
//        /// TODO
////        this._createAnimation(null);
//    }
//
//    void hitConstraints(List<ViolationRecord> violations) {
//        if (violations.isEmpty) {
//            this.hitConstraint = null;
//            this.constraintCoefficient = 1;
//            return;
//        }
//
//        violations.sort((a, b) {
//            final amc = a.motionConstraint;
//            final bmc = b.motionConstraint;
//            // Non animation-only constraints are less important than animation only ones;
//            // we should also sort on overdrag coefficient so that we get the tightest
//            // constraints to the top.
//            /// TODO should not quantize to ints, sorting is probably be wrong
//            if (amc.overdragCoefficient == bmc.overdragCoefficient)
//                return (b.delta.abs() - a.delta.abs()).toInt();
//            return (bmc.overdragCoefficient - amc.overdragCoefficient).toInt();
//        });
//        this.fnHitConstraint(violations.first.motionConstraint, violations.first.coefficient, violations.first.delta);
//    }
//
//    bool animating() {
//        if (motionState.dragging)
//            return false;
//        return motionState.velocityAnimation != null || motionState.trialAnimation;
//    }
//
//    void cancelAnimations() {
//        motionState.cancelVelocityAnimation();
//        motionState.cancelConstraintAnimation();
//        // XXX: Hacky -- want to prevent starting a new constraint animation in update; just want it to end the edit.
//        this.hitConstraint = null;
//        this._update();
//    }
//}
//
///// TODO could be wrong
//Constraint stayConstraint(Variable variable) {
//    return Term(variable, 1.0).equals(Term(variable, 1.0))
//        ..priority = Priority.medium;
//}
//
//class MotionState {
//    bool editing = false;
//    bool dragging = false;
//    double dragStart = 0;
//    double dragDelta = 0;
//    double dragTriggerDelta = 0;
//    AnimationController velocityAnimation;
//    double velocityAnimationPosition = 0;
//    double velocityAnimationVelocity = 0;
//    AnimationController constraintAnimation;
//    double constraintAnimationPosition = 0;
//    double constraintAnimationVelocity = 0;
//    MotionConstraint constraintAnimationConstraint;
//    bool trialAnimation;
//
//    void cancelVelocityAnimation() {
//        velocityAnimation?.dispose();
//        velocityAnimation = null;
//    }
//
//    void cancelConstraintAnimation() {
//        constraintAnimation?.dispose();
//        constraintAnimation = null;
//    }
//}
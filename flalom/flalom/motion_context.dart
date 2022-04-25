//import 'package:cassowary/cassowary.dart';
//
//import 'box.dart';
//import 'manipulator.dart';
//import 'motion_constraint.dart';
//import 'multi_edit_solver.dart';
//
//class MotionContext {
//    MultiEditSolver _solver;
//    List<Box> _boxes;
//    List<MotionConstraint> _motionConstraints;
//    List<Manipulator> _manipulators;
//    bool _updating;
//
//    MotionContext() {
//        this._solver = MultiEditSolver(Solver());
//        this._boxes = [];
//        this._motionConstraints = [];
//        this._manipulators = [];
//        this._updating = false;
//    }
//
//    MultiEditSolver solver() => _solver;
//
//    Box addBox(Box box) {
//      _boxes.add(box);
//      return box;
//    }
//
//    List<Box> boxes() => _boxes;
//
//    void addMotionConstraint(MotionConstraint constraint) {
//        this._motionConstraints.add(constraint);
//    }
//
//    Manipulator addManipulator(Manipulator manipulator) {
//        this._manipulators.add(manipulator);
//        manipulator.setMotionContext(this);
//        update(); // XXX: Remove -- constructing a Manipulator used to do this, moved it here but it should go.
//        return manipulator;
//    }
//
//    void update() {
//        if (_updating)
//            return;
//        this._updating = true;
//        this._resolveMotionConstraints();
//        boxes().forEach((box) => box.update());
//        this._updating = false;
//    }
//
//    double _coefficient(Manipulator manipulator, Variable variable) {
//        final solver = this.solver();
//        final v = manipulator.variable;
//        // Iterate the edit variables in the solver. XXX: these are private and we need a real interface soon.
//        final editVarInfo = solver.solver.editInfoFor(v);
//        // No edit variable? No contribution to the current violation.
//        if (editVarInfo == null)
//            return 0;
//        // Now we can ask the coefficient of the edit's minus variable to the manipulator's variable. This
//        // is what the solver does in suggestValue.
//        final editMinus = editVarInfo.tag.other;
//        // Get the expression that corresponds to the motion constraint's violated variable.
//        // This is probably an "external variable" in cassowary.
//        final expr = solver.solver.rowFor(variable);
//        if (expr == null)
//            return 0;
//        // Finally we can compute the value.
//        return expr.coefficientForSymbol(editMinus);
//    }
//
//    void _resolveMotionConstraints() {
//        final allViolations = <String, Violations>{};
//
//        // We want to call all manipulators so that those that previously were violating but now
//        // are not get those violations removed.
//        for (var i = 0; i < this._manipulators.length; i++) {
//            final manipulator = this._manipulators[i];
//            allViolations[manipulator.name] = Violations(manipulator, []);
//        }
//
//        void addViolation(Manipulator manipulator, MotionConstraint motionConstraint, double coefficient, double delta) {
//            final record = ViolationRecord(motionConstraint, coefficient, delta);
//            final name = manipulator.name;
//            if (!allViolations.containsKey(name)) {
//                allViolations[name] = Violations(manipulator, [record]);
//            } else {
//                allViolations[name].violations.add(record);
//            }
//        }
//        void dispatchViolations() {
//            for (final k in allViolations.keys) {
//                final info = allViolations[k];
//                info.manipulator.hitConstraints(info.violations);
//            }
//        }
//
//        for (var i = 0; i < this._motionConstraints.length; i++) {
//            final pc = this._motionConstraints[i];
//            final delta = pc.delta();
//            if (delta == 0)
//                continue;
//
//            // Notify the manipulators that contributed to this violation.
//            for (var j = 0; j < this._manipulators.length; j++) {
//                final manipulator = this._manipulators[j];
//
//                // If there's no delta and the manipulator isn't animating then it isn't a violation we want to deal
//                // with now.
////                if (delta == 0) continue;
//
//                final c = this._coefficient(manipulator, pc.variable);
//
//                // Do nothing if they're unrelated (i.e.: the coefficient is zero; this manipulator doesn't contribute).
//                if (c == 0)
//                    continue;
//
//                // We found a violation and the manipulator that contributed. Remember it and we'll
//                // tell the manipulator about all the violations it contributed to at once afterwards
//                // and it can decide what it's going to do about it...
//                addViolation(manipulator, pc, c, delta);
//            }
//            // XXX: We should find ONE manipulator, or figure out which manipulator to target in the
//            //      case of multiple. If we have one doing an animation, and one doing a touch drag
//            //      then maybe we want to constrain the animating manipulator and let the touch one
//            //      ride?
//        }
//        // Tell all the manipulators that we're done constraining.
//        dispatchViolations();
//    }
//
//    void stopOthers(Variable variable) {
//        // Kill all the manipulators that are animating this variable. There's a new touch point
//        // that's now dominant.
//        for (var i = 0; i < this._manipulators.length; i++) {
//            final manipulator = this._manipulators[i];
//            if (this._coefficient(manipulator, variable) != 0)
//                manipulator.cancelAnimations();
//        }
//    }
//}
//
//class Violations {
//    Manipulator manipulator;
//    List<ViolationRecord> violations;
//
//    Violations(this.manipulator, this.violations);
//}
//
//class ViolationRecord {
//    MotionConstraint motionConstraint;
//    double coefficient;
//    double delta;
//
//    ViolationRecord(this.motionConstraint, this.coefficient, this.delta);
//}
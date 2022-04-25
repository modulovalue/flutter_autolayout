//import 'package:cassowary/cassowary.dart';
//import 'package:meta/meta.dart';
//
//class MultiEditSolver {
//
//    final Solver solver;
//    bool _editing = false;
//    final List<_EditVar> _editVars = [];
//    double _priotity = 0;
//
//    MultiEditSolver(this.solver);
//
////    this.add = this._solver.add.bind(this._solver);
//
//    void solve() => this.solver.flushUpdates();
//
//    void resolve() => this.solver.flushUpdates();
//
//    void addConstraint(Constraint constraint) => this.solver.addConstraint(constraint);
//
//    void removeConstraint(Constraint constraint) => this.solver.removeConstraint(constraint);
//
//    void beginEdit(Variable variable, double strength) {
//        final idx = this._find(variable);
//        if (idx != -1) {
//            this._editVars[idx].count++;
//            print('multiple edit sessions on ' + variable.name);
//            return;
//        }
//        this._editVars.add(_EditVar(
//            edit: variable,
//            strength: strength,
//            priority: this._priotity++,
//            suggest: null,
//            count: 1,
//        ));
//        this._reedit();
//    }
//
//    int _find(Variable variable) {
//        for (var i = 0; i < this._editVars.length; i++) {
//            if (identical(this._editVars[i].edit, variable)) {
//                return i;
//            }
//        }
//        return -1;
//    }
//
//    void endEdit(Variable variable) {
//        final  idx = this._find(variable);
//        if (idx == -1) {
//            print('cannot end edit on variable that is not being edited');
//            return;
//        }
//        this._editVars[idx].count--;
//        if (this._editVars[idx].count == 0) {
//            this._editVars.removeAt(idx);
//            this._reedit();
//        }
//    }
//
//    void suggestValue(Variable variable, double value) {
//        if (!this._editing) {
//            print('cannot suggest value when not editing');
//            return;
//        }
//        final idx = this._find(variable);
//        if (idx == -1) {
//            print('cannot suggest value for variable that we are not editing');
//            return;
//        }
//        this._editVars[idx].suggest = value;
//        this.solver.suggestValueForVariable(variable, value);
//        this.solver.flushUpdates();
//    }
//
//    void _reedit() {
//        if (this._editing) {
////            this.solver.endEdit();
//            this.solver.removeEditVariables(_editVars.map((a) => a.edit).toList());
//        }
//        this._editing = false;
//
//        if (this._editVars.isEmpty) {
//            this.solver.flushUpdates();
//            return;
//        }
//
//        for (var i = 0; i < this._editVars.length; i++) {
//            final v = this._editVars[i];
//
//            this.solver.addEditVariable(v.edit, v.priority * v.strength);
//        }
//
////        this._solver.beginEdit();
//
//        // Now suggest all of the previous values again. Not sure if doing them
//        // in a different order will cause a different outcome...
//        for (var i = 0; i < this._editVars.length; i++) {
//            final v = this._editVars[i];
//
//            if (v.suggest == null)
//                continue;
//
//            this.solver.suggestValueForVariable(v.edit, v.suggest);
//        }
//
//        // Finally resolve.
//        this.solver.flushUpdates();
//        this._editing = true;
//    }
//}
//
//class _EditVar {
//    final Variable edit;
//    final double strength;
//    final double priority;
//    double suggest;
//    double count;
//
//    _EditVar({
//        @required this.edit,
//        @required this.strength,
//        @required this.priority,
//        @required this.suggest,
//        @required this.count,
//    });
//}
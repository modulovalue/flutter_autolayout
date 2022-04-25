/// An implementation of the Cassowary constraint solving algorithm in Dart.
///
/// See also:
///
/// * <https://en.wikipedia.org/wiki/Cassowary_(software)>
/// * <https://constraints.cs.washington.edu/solvers/cassowary-tochi.pdf>
library cassowary;

import 'dart:collection';
import 'dart:math';

import 'base.dart';
import 'impl.dart';

class SolverImpl implements Solver {
  final Map<Constraint, _Tag> _constraints = {};
  final Map<_Symbol, _Row> _rows = {};
  final Map<Variable, _Symbol> _vars = {};
  final Map<Variable, _EditInfo> _edits = {};
  final List<_Symbol> _infeasibleRows = [];
  final _Row _objective = _Row._(0, {});

  _Row _artificial = _Row._(0, {});

  SolverImpl();

  @override
  Result addConstraints(
    final List<Constraint> constraints,
  ) {
    Result _applier(final Constraint c) => addConstraint(c);
    Result _undoer(final Constraint c) => removeConstraint(c);
    return _bulkEdit(constraints, _applier, _undoer);
  }

  @override
  Result addConstraint(
    final Constraint constraint,
  ) {
    if (_constraints.containsKey(constraint)) {
      return resultDuplicateConstraint;
    } else {
      final tag = _Tag(
        _Symbol(_SymbolType.invalid),
        _Symbol(_SymbolType.invalid),
      );
      final row = _createRow(constraint, tag);
      var subject = _chooseSubjectForRow(row, tag);
      if (subject.type == _SymbolType.invalid && _allDummiesInRow(row)) {
        if (!_nearZero(row.constant)) {
          return resultUnsatisfiableConstraint;
        } else {
          subject = tag.marker;
        }
      }
      if (subject.type == _SymbolType.invalid) {
        if (!_addWithArtificialVariableOnRow(row)) {
          return resultUnsatisfiableConstraint;
        }
      } else {
        row.solveForSymbol(subject);
        _substitute(subject, row);
        _rows[subject] = row;
      }
      _constraints[constraint] = tag;
      return _optimizeObjectiveRow(_objective);
    }
  }

  @override
  Result removeConstraints(
    final List<Constraint> constraints,
  ) {
    Result _applier(final Constraint c) => removeConstraint(c);
    Result _undoer(final Constraint c) => addConstraint(c);
    return _bulkEdit(constraints, _applier, _undoer);
  }

  @override
  Result removeConstraint(
    final Constraint constraint,
  ) {
    var tag = _constraints[constraint];
    if (tag == null) {
      return resultUnknownConstraint;
    } else {
      tag = _tagFromTag(tag);
      _constraints.remove(constraint);
      _removeConstraintEffects(constraint, tag);
      var row = _rows[tag.marker];
      if (row != null) {
        _rows.remove(tag.marker);
      } else {
        final leaving = _leavingSymbolForMarkerSymbol(tag.marker)!;
        row = _rows.remove(leaving)!;
        row.solveForSymbols(leaving, tag.marker);
        _substitute(tag.marker, row);
      }
      return _optimizeObjectiveRow(_objective);
    }
  }

  @override
  bool hasConstraint(
    final Constraint constraint,
  ) =>
      _constraints.containsKey(constraint);

  @override
  Result addEditVariables(
    final List<Variable> variables,
    final double priority,
  ) {
    Result _applier(final Variable v) => addEditVariable(v, priority);
    Result _undoer(final Variable v) => removeEditVariable(v);
    return _bulkEdit(variables, _applier, _undoer);
  }

  @override
  Result addEditVariable(
    final Variable variable,
    final double priority,
  ) {
    if (_edits.containsKey(variable)) {
      return resultDuplicateEditVariable;
    } else if (!_isValidNonRequiredPriority(priority)) {
      return resultBadRequiredStrength;
    } else {
      final constraint = ConstraintImpl(
        expression: ExpressionImpl(
          <Term>[
            TermImpl(
              variable,
              1,
            ),
          ],
          0,
        ),
        relation: Relation.equalTo,
        priority: priority,
      );
      // ignore: unused_local_variable
      final result = addConstraint(constraint);
      // ignore: prefer_asserts_with_message
      assert(result == resultSuccess);
      final info = _EditInfo(
        tag: _constraints[constraint]!,
        constraint: constraint,
        constant: 0.0,
      );
      _edits[variable] = info;
      return resultSuccess;
    }
  }

  @override
  Result removeEditVariables(
    final List<Variable> variables,
  ) {
    Result _applier(final Variable v) => removeEditVariable(v);
    Result _undoer(final Variable v) => addEditVariable(v, _edits[v]!.constraint.priority);
    return _bulkEdit(variables, _applier, _undoer);
  }

  @override
  Result removeEditVariable(
    final Variable variable,
  ) {
    final info = _edits[variable];
    if (info == null) {
      return resultUnknownEditVariable;
    } else {
      // ignore: unused_local_variable
      final result = removeConstraint(info.constraint);
      // ignore: prefer_asserts_with_message
      assert(result == resultSuccess);
      _edits.remove(variable);
      return resultSuccess;
    }
  }

  @override
  bool hasEditVariable(
    final Variable variable,
  ) =>
      _edits.containsKey(variable);

  @override
  Result suggestValueForVariable(
    final Variable variable,
    final double value,
  ) {
    if (!_edits.containsKey(variable)) {
      return resultUnknownEditVariable;
    } else {
      _suggestValueForEditInfoWithoutDualOptimization(_edits[variable]!, value);
      return _dualOptimize();
    }
  }

  @override
  Set<Object> flushUpdates() {
    final updates = HashSet<Object>();
    for (final variable in _vars.keys) {
      final symbol = _vars[variable];
      final row = _rows[symbol];
      final updatedValue = () {
        if (row == null) {
          return 0.0;
        } else {
          return row.constant;
        }
      }();
      final _owner = variable.owner;
      if (variable.applyUpdate(updatedValue) && _owner != null) {
        final context = _owner.context;
        if (context != null) {
          updates.add(context);
        }
      }
    }
    return updates;
  }

  Result _bulkEdit<T>(
    final Iterable<T> items,
    final Result Function(T) applier,
    final Result Function(T) undoer,
  ) {
    final applied = <T>[];
    var needsCleanup = false;
    var result = resultSuccess;
    for (final item in items) {
      result = applier(item);
      if (result == resultSuccess) {
        applied.add(item);
      } else {
        needsCleanup = true;
        break;
      }
    }
    if (needsCleanup) {
      applied.reversed.forEach(undoer);
    }
    return result;
  }

  _Symbol _symbolForVariable(
    final Variable variable,
  ) {
    var symbol = _vars[variable];
    if (symbol != null) {
      return symbol;
    } else {
      symbol = _Symbol(_SymbolType.external);
      _vars[variable] = symbol;
      return symbol;
    }
  }

  _Row _createRow(
    final Constraint constraint,
    final _Tag tag,
  ) {
    final expr = expressionFromExpression(constraint.expression);
    final row = _Row._(expr.constant, {});
    for (final term in expr.terms) {
      if (!_nearZero(term.coefficient)) {
        final symbol = _symbolForVariable(term.variable);
        final foundRow = _rows[symbol];
        if (foundRow != null) {
          row.insertRow(foundRow, term.coefficient);
        } else {
          row.insertSymbol(symbol, term.coefficient);
        }
      }
    }
    switch (constraint.relation) {
      case Relation.lessThanOrEqualTo:
      case Relation.greaterThanOrEqualTo:
        final coefficient = () {
          if (constraint.relation == Relation.lessThanOrEqualTo) {
            return 1.0;
          } else {
            return -1.0;
          }
        }();
        final slack = _Symbol(_SymbolType.slack);
        tag.marker = slack;
        row.insertSymbol(slack, coefficient);
        if (constraint.priority < Priority.required) {
          final error = _Symbol(_SymbolType.error);
          tag.other = error;
          row.insertSymbol(error, -coefficient);
          _objective.insertSymbol(error, constraint.priority);
        }
        break;
      case Relation.equalTo:
        if (constraint.priority < Priority.required) {
          final errPlus = _Symbol(_SymbolType.error);
          final errMinus = _Symbol(_SymbolType.error);
          tag
            ..marker = errPlus
            ..other = errMinus;
          row
            ..insertSymbol(errPlus, -1)
            ..insertSymbol(errMinus, 1);
          _objective
            ..insertSymbol(errPlus, constraint.priority)
            ..insertSymbol(errMinus, constraint.priority);
        } else {
          final dummy = _Symbol(_SymbolType.dummy);
          tag.marker = dummy;
          row.insertSymbol(dummy);
        }
        break;
    }
    if (row.constant < 0.0) {
      row.reverseSign();
    }
    return row;
  }

  _Symbol _chooseSubjectForRow(
    final _Row row,
    final _Tag tag,
  ) {
    for (final symbol in row.cells.keys) {
      if (symbol.type == _SymbolType.external) {
        return symbol;
      }
    }
    if (tag.marker.type == _SymbolType.slack || tag.marker.type == _SymbolType.error) {
      if (row.coefficientForSymbol(tag.marker) < 0.0) {
        return tag.marker;
      }
    }
    if (tag.other.type == _SymbolType.slack || tag.other.type == _SymbolType.error) {
      if (row.coefficientForSymbol(tag.other) < 0.0) {
        return tag.other;
      }
    }
    return _Symbol(_SymbolType.invalid);
  }

  bool _allDummiesInRow(
    final _Row row,
  ) {
    for (final symbol in row.cells.keys) {
      if (symbol.type != _SymbolType.dummy) {
        return false;
      }
    }
    return true;
  }

  bool _addWithArtificialVariableOnRow(
    final _Row row,
  ) {
    final artificial = _Symbol(_SymbolType.slack);
    _rows[artificial] = _rowFromRow(row);
    _artificial = _rowFromRow(row);
    final result = _optimizeObjectiveRow(_artificial);
    if (result.isError) {
      // FIXME(csg): Propagate this up!
      return false;
    }
    final success = _nearZero(_artificial.constant);
    _artificial = _Row._(0, {});
    final foundRow = _rows[artificial];
    if (foundRow != null) {
      _rows.remove(artificial);
      if (foundRow.cells.isEmpty) {
        return success;
      }
      final entering = _anyPivotableSymbol(foundRow);
      if (entering.type == _SymbolType.invalid) {
        return false;
      }
      foundRow.solveForSymbols(artificial, entering);
      _substitute(entering, foundRow);
      _rows[entering] = foundRow;
    }
    for (final row in _rows.values) {
      row.removeSymbol(artificial);
    }
    _objective.removeSymbol(artificial);
    return success;
  }

  Result _optimizeObjectiveRow(
    final _Row objective,
  ) {
    var entering = _enteringSymbolForObjectiveRow(objective);
    while (entering.type != _SymbolType.invalid) {
      final leaving = _leavingSymbolForEnteringSymbol(entering)!;
      final row = _rows.remove(leaving)!..solveForSymbols(leaving, entering);
      _substitute(entering, row);
      _rows[entering] = row;
      entering = _enteringSymbolForObjectiveRow(objective);
    }
    return resultSuccess;
  }

  _Symbol _enteringSymbolForObjectiveRow(
    final _Row objective,
  ) {
    final cells = objective.cells;
    for (final symbol in cells.keys) {
      if (symbol.type != _SymbolType.dummy && cells[symbol]! < 0.0) {
        return symbol;
      }
    }
    return _Symbol(_SymbolType.invalid);
  }

  _Symbol? _leavingSymbolForEnteringSymbol(
    final _Symbol entering,
  ) {
    var ratio = double.maxFinite;
    _Symbol? result;
    _rows.forEach((final symbol, final row) {
      if (symbol.type != _SymbolType.external) {
        final temp = row.coefficientForSymbol(entering);
        if (temp < 0.0) {
          final tempRatio = -row.constant / temp;
          if (tempRatio < ratio) {
            ratio = tempRatio;
            result = symbol;
          }
        }
      }
    });
    return result;
  }

  void _substitute(
    final _Symbol symbol,
    final _Row row,
  ) {
    _rows.forEach((final first, final second) {
      second.substitute(symbol, row);
      if (first.type != _SymbolType.external && second.constant < 0.0) {
        _infeasibleRows.add(first);
      }
    });
    _objective.substitute(symbol, row);
    _artificial.substitute(symbol, row);
  }

  _Symbol _anyPivotableSymbol(
    final _Row row,
  ) {
    for (final symbol in row.cells.keys) {
      if (symbol.type == _SymbolType.slack || symbol.type == _SymbolType.error) {
        return symbol;
      }
    }
    return _Symbol(_SymbolType.invalid);
  }

  void _removeConstraintEffects(
    final Constraint cn,
    final _Tag tag,
  ) {
    if (tag.marker.type == _SymbolType.error) {
      _removeMarkerEffects(tag.marker, cn.priority);
    }
    if (tag.other.type == _SymbolType.error) {
      _removeMarkerEffects(tag.other, cn.priority);
    }
  }

  void _removeMarkerEffects(
    final _Symbol marker,
    final double strength,
  ) {
    final row = _rows[marker];
    if (row != null) {
      _objective.insertRow(row, -strength);
    } else {
      _objective.insertSymbol(marker, -strength);
    }
  }

  _Symbol? _leavingSymbolForMarkerSymbol(
    final _Symbol marker,
  ) {
    var r1 = double.maxFinite;
    var r2 = double.maxFinite;
    _Symbol? first;
    _Symbol? second;
    _Symbol? third;
    _rows.forEach((final symbol, final row) {
      final c = row.coefficientForSymbol(marker);
      if (c != 0.0) {
        if (symbol.type == _SymbolType.external) {
          third = symbol;
        } else if (c < 0.0) {
          final r = -row.constant / c;
          if (r < r1) {
            r1 = r;
            first = symbol;
          }
        } else {
          final r = row.constant / c;
          if (r < r2) {
            r2 = r;
            second = symbol;
          }
        }
      }
    });
    return first ?? second ?? third;
  }

  void _suggestValueForEditInfoWithoutDualOptimization(
    final _EditInfo info,
    final double value,
  ) {
    final delta = value - info.constant;
    info.constant = value;
    {
      var symbol = info.tag.marker;
      var row = _rows[info.tag.marker];
      if (row != null) {
        if (row.add(-delta) < 0.0) {
          _infeasibleRows.add(symbol);
        }
        return;
      }
      symbol = info.tag.other;
      row = _rows[info.tag.other];
      if (row != null) {
        if (row.add(delta) < 0.0) {
          _infeasibleRows.add(symbol);
        }
        return;
      }
    }
    for (final symbol in _rows.keys) {
      final row = _rows[symbol]!;
      final coeff = row.coefficientForSymbol(info.tag.marker);
      if (coeff != 0.0 && row.add(delta * coeff) < 0.0 && symbol.type != _SymbolType.external) {
        _infeasibleRows.add(symbol);
      }
    }
  }

  Result _dualOptimize() {
    while (_infeasibleRows.isNotEmpty) {
      final leaving = _infeasibleRows.removeLast();
      final row = _rows[leaving];
      if (row != null && row.constant < 0.0) {
        final entering = _dualEnteringSymbolForRow(row);
        // ignore: prefer_asserts_with_message
        assert(entering.type != _SymbolType.invalid);
        _rows.remove(leaving);
        row.solveForSymbols(leaving, entering);
        _substitute(entering, row);
        _rows[entering] = row;
      }
    }
    return resultSuccess;
  }

  _Symbol _dualEnteringSymbolForRow(
    final _Row row,
  ) {
    _Symbol? entering;
    var ratio = double.maxFinite;
    final rowCells = row.cells;
    for (final symbol in rowCells.keys) {
      final value = rowCells[symbol]!;
      if (value > 0.0 && symbol.type != _SymbolType.dummy) {
        final coeff = _objective.coefficientForSymbol(symbol);
        final r = coeff / value;
        if (r < ratio) {
          ratio = r;
          entering = symbol;
        }
      }
    }
    return entering ?? _Symbol(_SymbolType.invalid);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    const separator = '\n~~~~~~~~~';
    buffer
      // Objective
      ..writeln('$separator Objective')
      ..writeln(_objective.toString())
      // Tableau
      ..writeln('$separator Tableau');
    _rows.forEach((final symbol, final row) => buffer.writeln('$symbol | $row'));
    // Infeasible
    buffer.writeln('$separator Infeasible');
    _infeasibleRows.forEach(buffer.writeln);
    // Variables
    buffer.writeln('$separator Variables');
    _vars.forEach((final variable, final symbol) => buffer.writeln('$variable = $symbol'));
    // Edit Variables
    buffer.writeln('$separator Edit Variables');
    _edits.forEach((final variable, final editinfo) => buffer.writeln(variable));
    // Constraints
    buffer.writeln('$separator Constraints');
    _constraints.forEach((final constraint, final tag) => buffer.writeln(constraint));
    return buffer.toString();
  }
}

/// The result when the operation was successful.
const Result resultSuccess = Result._('Success', isError: false);

/// The result when the [Constraint] could not be added to the [Solver]
/// because it was already present in the solver.
const Result resultDuplicateConstraint = Result._('Duplicate constraint');

/// The result when the [Constraint] could not be added to the [Solver]
/// because it was unsatisfiable. Try lowering the [Priority] of the
/// [Constraint] and try again.
const Result resultUnsatisfiableConstraint = Result._('Unsatisfiable constraint');

/// The result when the [Constraint] could not be removed from the solver
/// because it was not present in the [Solver] to begin with.
const Result resultUnknownConstraint = Result._('Unknown constraint');

/// The result when could not add the edit [Variable] to the [Solver] because
/// it was already added to the [Solver] previously.
const Result resultDuplicateEditVariable = Result._('Duplicate edit variable');

/// The result when the [Constraint] constraint was added at an invalid
/// priority or an edit [Variable] was added at an invalid or required
/// priority.
const Result resultBadRequiredStrength = Result._('Bad required strength');

/// The result when the edit [Variable] could not be removed from the solver
/// because it was not present in the [Solver] to begin with.
const Result resultUnknownEditVariable = Result._('Unknown edit variable');

/// TODO adt.
/// Return values used by methods on the cassowary [Solver].
class Result {
  /// The human-readable string associated with this result.
  ///
  /// This message is typically brief and intended for developers to help debug
  /// erroneous expressions.
  final String message;

  /// Whether this [Result] represents an error (true) or not (false).
  final bool isError;

  const Result._(
    final this.message, {
    final this.isError = true,
  });
}

/// Utility functions for managing cassowary priorities.
///
/// Priorities in cassowary expressions are internally expressed as a number
/// between 0 and 1,000,000,000. These numbers can be created by using the
/// [Priority.create] static method.
abstract class Priority {
  /// The [Priority] level that, by convention, is the highest allowed
  /// [Priority] level (1,000,000,000).
  static final double required = create(1000, 0, 0);

  /// A [Priority] level that is below the [required] level but still near it
  /// (1,000,000).
  static final double strong = create(1, 0, 0);

  /// A [Priority] level logarithmically in the middle of [strong] and [weak]
  /// (1,000).
  static final double medium = create(0, 1, 0);

  /// A [Priority] level that, by convention, is the lowest allowed [Priority]
  /// level (1).
  static final double weak = create(0, 0, 1);

  /// Computes a [Priority] level by combining three numbers in the range
  /// 0..1000.
  ///
  /// The first number is a multiple of [strong].
  ///
  /// The second number is a multiple of [medium].
  ///
  /// The third number is a multiple of [weak].
  ///
  /// By convention, at least one of these numbers should be equal to or greater
  /// than 1.
  static double create(
    final double a,
    final double b,
    final double c,
  ) {
    var result = 0.0;
    result += max(0, min(1000, a)) * 1e6;
    result += max(0, min(1000, b)) * 1e3;
    result += max(0, min(1000, c));
    return result;
  }
}

/// Exception thrown when attempting to create a non-linear expression.
///
/// During the creation of constraints or expressions using the overloaded
/// operators, it may be possible to end up with non-linear expressions. Such
/// expressions are not suitable for [Constraint] creation because the [Solver]
/// will reject the same. A [CassowaryException] is thrown when a developer tries
/// to create such an expression.
///
/// The only cases where this is possible is when trying to multiply two
/// expressions where at least one of them is not a constant expression, or,
/// when trying to divide two expressions where the divisor is not constant.
class CassowaryException implements Exception {
  /// A detailed message describing the exception.
  final String message;

  /// The members that caused the exception.
  final List<EquationMember> members;

  /// Creates a new [CassowaryException] with a given message and a list of the
  /// offending member for debugging purposes.
  const CassowaryException(
    final this.message,
    final this.members,
  );

  @override
  String toString() => 'Error: "' + message + '" while trying to parse constraint or expression';
}

// Internal

class _Symbol {
  final _SymbolType type;

  _Symbol(
    final this.type,
  );
}

enum _SymbolType {
  invalid,
  external,
  slack,
  error,
  dummy,
}

_Tag _tagFromTag(
  final _Tag tag,
) =>
    _Tag(tag.marker, tag.other);

class _Tag {
  _Symbol marker;

  _Symbol other;

  _Tag(
    final this.marker,
    final this.other,
  );
}

class _EditInfo {
  final _Tag tag;
  final Constraint constraint;
  double constant;

  _EditInfo({
    required final this.tag,
    required final this.constraint,
    required final this.constant,
  });
}

bool _isValidNonRequiredPriority(
  final double priority,
) =>
    priority >= 0.0 && priority < Priority.required;

bool _nearZero(
  final double value,
) {
  const epsilon = 1.0e-8;
  if (value < 0.0) {
    return -value < epsilon;
  } else {
    return value < epsilon;
  }
}

_Row _rowFromRow(
  final _Row row,
) =>
    _Row._(
      row.constant,
      Map<_Symbol, double>.from(row.cells),
    );

class _Row {
  final Map<_Symbol, double> cells;
  double constant = 0;

  _Row._(
    final this.constant,
    final this.cells,
  );

  double add(
    final double value,
  ) =>
      constant += value;

  void insertSymbol(
    final _Symbol symbol, [
    final double coefficient = 1.0,
  ]) {
    final val = cells[symbol] ?? 0.0;
    if (_nearZero(val + coefficient)) {
      cells.remove(symbol);
    } else {
      cells[symbol] = val + coefficient;
    }
  }

  void insertRow(
    final _Row other, [
    final double coefficient = 1.0,
  ]) {
    constant += other.constant * coefficient;
    other.cells.forEach((final s, final v) => insertSymbol(s, v * coefficient));
  }

  void removeSymbol(
    final _Symbol symbol,
  ) =>
      cells.remove(symbol);

  void reverseSign() {
    constant = -constant;
    cells.forEach((final s, final v) => cells[s] = -v);
  }

  void solveForSymbol(
    final _Symbol symbol,
  ) {
    // ignore: prefer_asserts_with_message
    assert(cells.containsKey(symbol));
    final coefficient = -1.0 / cells[symbol]!;
    cells.remove(symbol);
    constant *= coefficient;
    cells.forEach((final s, final v) => cells[s] = v * coefficient);
  }

  void solveForSymbols(
    final _Symbol lhs,
    final _Symbol rhs,
  ) {
    insertSymbol(lhs, -1);
    solveForSymbol(rhs);
  }

  double coefficientForSymbol(
    final _Symbol symbol,
  ) =>
      cells[symbol] ?? 0.0;

  void substitute(
    final _Symbol symbol,
    final _Row row,
  ) {
    final coefficient = cells[symbol];
    if (coefficient != null) {
      cells.remove(symbol);
      insertRow(row, coefficient);
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer()..write(constant);
    cells.forEach((final symbol, final value) {
      buffer.write('${value.toString()} * ${symbol.toString()}');
    });
    return buffer.toString();
  }
}

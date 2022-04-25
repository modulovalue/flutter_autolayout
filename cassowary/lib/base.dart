// TODO solver interface and remove this import.
import 'cassowary.dart';

/// Solves cassowary constraints.
///
/// Typically clients will create a solver, [addConstraints],
/// and then call [flushUpdates] to actually solve the constraints.
abstract class Solver {
  /// Attempts to add the constraints in the list to the solver. If it cannot
  /// add any for some reason, a cleanup is attempted so that either all
  /// constraints will be added or none.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: All constraints successfully added.
  /// * [Result.duplicateConstraint]: One of the constraints in the list was
  ///   already in the solver or the same constraint was specified multiple
  ///   times in the argument list. Remove the duplicates and try again.
  /// * [Result.unsatisfiableConstraint]: One or more constraints were at
  ///   [Priority.required] but could not added because of conflicts with other
  ///   constraints at the same priority. Lower the priority of these
  ///   constraints and try again.
  Result addConstraints(
    final List<Constraint> constraints,
  );

  /// Attempts to add an individual [Constraint] to the solver.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The constraint was successfully added.
  /// * [Result.duplicateConstraint]: The constraint was already present in the
  ///   solver.
  /// * [Result.unsatisfiableConstraint]: The constraint was at
  ///   [Priority.required] but could not be added because of a conflict with
  ///   another constraint at that priority already in the solver. Try lowering
  ///   the priority of the constraint and try again.
  Result addConstraint(
    final Constraint constraint,
  );

  /// Attempts to remove a list of constraints from the solver. Either all
  /// constraints are removed or none. If more fine-grained control over the
  /// removal is required (for example, not failing on removal of constraints
  /// not already present in the solver), try removing the each [Constraint]
  /// individually and check the result on each attempt.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The constraints were successfully removed from the
  ///   solver.
  /// * [Result.unknownConstraint]: One or more constraints in the list were
  ///   not in the solver. So there was nothing to remove.
  Result removeConstraints(
    final List<Constraint> constraints,
  );

  /// Attempt to remove an individual [Constraint] from the solver.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The [Constraint] was successfully removed from the
  ///   solver.
  /// * [Result.unknownConstraint]: The [Constraint] was not in the solver so
  ///   there was nothing to remove.
  Result removeConstraint(
    final Constraint constraint,
  );

  /// Returns whether the given [Constraint] is present in the solver.
  bool hasConstraint(
    final Constraint constraint,
  );

  /// Adds a list of edit [Variable]s to the [Solver] at a given priority.
  /// Either all edit [Variable] are added or none. No edit variables may be
  /// added at `Priority.required`.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The edit variables were successfully added to [Solver]
  ///   at the specified priority.
  /// * [Result.duplicateEditVariable]: One of more edit variables were already
  ///   present in the [Solver] or the same edit variables were specified
  ///   multiple times in the list. Remove the duplicates and try again.
  /// * [Result.badRequiredStrength]: The edit variables were added at
  ///   [Priority.required]. Edit variables are used to
  ///   suggest values to the solver. Since suggestions can't be mandatory,
  ///   priorities cannot be [Priority.required]. If variable values need to be
  ///   fixed at [Priority.required], add that preference as a constraint. This
  ///   allows the solver to check for satisfiability of the constraint (w.r.t
  ///   other constraints at [Priority.required]) and check for duplicates.
  Result addEditVariables(
    final List<Variable> variables,
    final double priority,
  );

  /// Attempt to add a single edit [Variable] to the [Solver] at the given
  /// priority. No edit variables may be added to the [Solver] at
  /// `Priority.required`.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The edit variable was successfully added to [Solver]
  ///   at the specified priority.
  /// * [Result.duplicateEditVariable]: The edit variable was already present
  ///   in the [Solver].
  /// * [Result.badRequiredStrength]: The edit variable was added at
  ///   [Priority.required]. Edit variables are used to
  ///   suggest values to the solver. Since suggestions can't be mandatory,
  ///   priorities cannot be [Priority.required]. If variable values need to be
  ///   fixed at [Priority.required], add that preference as a constraint. This
  ///   allows the solver to check for satisfiability of the constraint (w.r.t
  ///   other constraints at [Priority.required]) and check for duplicates.
  Result addEditVariable(
    final Variable variable,
    final double priority,
  );

  /// Attempt the remove the list of edit [Variable] from the solver. Either
  /// all the specified edit variables are removed or none.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The edit variables were successfully removed from the
  ///   [Solver].
  /// * [Result.unknownEditVariable]: One of more edit variables were not
  ///   already present in the solver.
  Result removeEditVariables(
    final List<Variable> variables,
  );

  /// Attempt to remove the specified edit [Variable] from the solver.
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The edit variable was successfully removed from the
  ///   solver.
  /// * [Result.unknownEditVariable]: The edit variable was not present in the
  ///   solver. There was nothing to remove.
  Result removeEditVariable(
    final Variable variable,
  );

  /// Returns whether the given edit [Variable] is present in the solver.
  bool hasEditVariable(
    final Variable variable,
  );

  /// Suggest an updated value for the edit variable. The edit variable
  /// must already be added to the solver.
  ///
  /// Suggestions update values of variables within the [Solver] but take into
  /// account all the constraints already present in the [Solver]. Depending
  /// on the constraints, the value of the [Variable] may not actually be the
  /// value specified. The actual value can be read after the next
  /// `flushUpdates` call. Since these updates are merely "suggestions", they
  /// cannot be at `Priority.required`.
  ///
  ///
  /// Check the [Result] returned to make sure the operation succeeded. Any
  /// errors will be reported via the `message` property on the [Result].
  ///
  /// Possible [Result]s:
  ///
  /// * [Result.success]: The suggestion was successfully applied to the
  ///   variable within the solver.
  /// * [Result.unknownEditVariable]: The edit variable was not already present
  ///   in the [Solver]. So the suggestion could not be applied. Add this edit
  ///   variable to the solver and then apply the value again. If you have
  ///   already added the variable to the [Solver], make sure the [Result]
  ///   was `Result.success`.
  Result suggestValueForVariable(
    final Variable variable,
    final double value,
  );

  /// Flush the results of solver. The set of all `context` objects associated
  /// with variables in the [Solver] is returned. If a [Variable] does not
  /// contain an associated context, its updates are ignored.
  ///
  /// The addition and removal of constraints and edit variables to and from the
  /// [Solver] as well as the application of suggestions to the added edit
  /// variables leads to the modification of values on a lot of other variables.
  /// External entities that rely on the values of the variables within the
  /// [Solver] can read these updates in one shot by "flushing" out these
  /// updates.
  Set<Object> flushUpdates();
}

/// A member that can be used to construct an [Expression] that may be
/// used to create a constraint. This is to facilitate the easy creation of
/// constraints. The use of the operator overloads is completely optional and
/// is only meant as a convenience. The [Constraint] expressions can be created
/// by manually creating instance of [Constraint] variables, then terms and
/// combining those to create expression.
abstract class EquationMember {
  /// The representation of this member after it is hoisted to be an
  /// expression.
  Expression asExpression();

  /// Returns if this member is a constant. Constant members can be combined
  /// more easily without making the expression non-linear. This makes them
  /// easier to use with multiplication and division operators. Constant
  /// expression that have zero value may also eliminate other expressions from
  /// the solver when used with the multiplication operator.
  bool get isConstant;

  /// The current constant value of this member. After a [Solver] flush, this is
  /// value read by entities outside the [Solver].
  double get value;

  /// Creates a [Constraint] by using this member as the left hand side
  /// expression and the argument as the right hand side [Expression] of a
  /// [Constraint] with a [Relation.greaterThanOrEqualTo] relationship between
  /// the two.
  ///
  /// For example: `right - left >= cm(200.0)` would read, "the width of the
  /// object is at least 200."
  Constraint operator >=(
    final EquationMember m,
  );

  /// Creates a [Constraint] by using this member as the left hand side
  /// expression and the argument as the right hand side [Expression] of a
  /// [Constraint] with a [Relation.lessThanOrEqualTo] relationship between the
  /// two.
  ///
  /// For example: `rightEdgeOfA <= leftEdgeOfB` would read, "the entities A and
  /// B are stacked left to right."
  Constraint operator <=(
    final EquationMember m,
  );

  /// Creates a [Constraint] by using this member as the left hand side
  /// expression and the argument as the right hand side [Expression] of a
  /// [Constraint] with a [Relation.equalTo] relationship between the two.
  ///
  /// For example: `topEdgeOfBoxA + cm(10.0) == topEdgeOfBoxB` woud read,
  /// "the entities A and B have a padding on top of 10."
  Constraint equals(
    final EquationMember m,
  );

  /// Creates a [Expression] by adding this member with the argument. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// For example: `(left + right) / cm(2.0)` can be used as an [Expression]
  /// equivalent of the `midPointX` property.
  Expression operator +(
    final EquationMember m,
  );

  /// Creates a [Expression] by subtracting the argument from this member. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// For example: `right - left` can be used as an [Expression]
  /// equivalent of the `width` property.
  Expression operator -(
    final EquationMember m,
  );

  /// Creates a [Expression] by multiplying this member with the argument. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// Warning: This operation may throw a [CassowaryException] if the resulting
  /// expression is no longer linear. This is because a non-linear [Expression]
  /// may not be used to create a constraint. At least one of the [Expression]
  /// members must evaluate to a constant.
  ///
  /// For example: `((left + right) >= (cm(2.0) * mid)` declares a `midpoint`
  /// constraint. Notice that at least one the members of the right hand
  /// `Expression` is a constant.
  Expression operator *(
    final EquationMember m,
  );

  /// Creates a [Expression] by dividing this member by the argument. Both
  /// members may need to be hoisted to expressions themselves before this can
  /// occur.
  ///
  /// Warning: This operation may throw a [CassowaryException] if the resulting
  /// expression is no longer linear. This is because a non-linear [Expression]
  /// may not be used to create a constraint. The divisor (i.e. the argument)
  /// must evaluate to a constant.
  ///
  /// For example: `((left + right) / cm(2.0) >= mid` declares a `midpoint`
  /// constraint. Notice that the divisor of the left hand [Expression] is a
  /// constant.
  Expression operator /(
    final EquationMember m,
  );

  Z match<Z>({
    required final Z Function(ConstantMember) constant,
    required final Z Function(Param) param,
    required final Z Function(Expression) expression,
    required final Z Function(Term) term,
  });
}

/// A member of a [Constraint] [Expression] that represent a constant at the
/// time the [Constraint] is added to the solver.
abstract class ConstantMember implements EquationMember {}

/// A [Param] wraps a [Variable] and makes it suitable to be used in an
/// expression.
abstract class Param implements EquationMember {
  /// The [Variable] associated with this [Param].
  Variable get variable;

  /// Some object outside the [Solver] that is associated with this Param.
  /// TODO Make this generic?
  Object? get context;

  /// The name of the [Variable] associated with this [Param].
  String? get name;
}

/// The representation of a linear [Expression] that can be used to create a
/// constraint.
abstract class Expression implements EquationMember {
  /// The list of terms in this linear expression. Terms in a an [Expression]
  /// must have only one [Variable] (indeterminate) and a degree of 1.
  Iterable<Term> get terms;

  /// The constant portion of this linear expression. This is just another
  /// [Term] with no [Variable].
  double get constant;

  Expression applyMultiplicand(
    final double m,
  );
}

/// Represents a single term in an expression. This term contains a single
/// indeterminate and has degree 1.
abstract class Term implements EquationMember {
  /// The [Variable] (or indeterminate) portion of this term. Variables are
  /// usually tied to an opaque object (via its `context` property). On a
  /// [Solver] flush, these context objects of updated variables are returned by
  /// the solver. An external entity can then choose to interpret these values
  /// in what manner it sees fit.
  Variable get variable;

  /// The coefficient of this term. Before addition of the [Constraint] to the
  /// solver, terms with a zero coefficient are dropped.
  double get coefficient;
}

/// A [Variable] inside the layout [Solver]. It represents an indeterminate
/// in the [Expression] that is used to create the [Constraint]. If any entity
/// is interested in watching updates to the value of this indeterminate,
/// it can assign a watcher as the `owner`.
abstract class Variable {
  /// The current value of the variable.
  double get value;

  /// An optional name given to the variable. This is useful in debugging
  /// [Solver] state.
  String? get name;

  /// Variables represent state inside the solver. This state is usually of
  /// interest to some entity outside the solver. Such entities can (optionally)
  /// associate themselves with these variables. This means that when solver
  /// is flushed, it is easy to obtain a reference to the entity the variable
  /// is associated with.
  /// TODO it would be great if this didn't have to be mutable.
  abstract Param? owner;

  /// Used by the [Solver] to apply updates to this variable. Only updated
  /// variables show up in [Solver] flush results.
  bool applyUpdate(
    final double updated,
  );
}

/// A relationship between two expressions (represented by [Expression]) that
/// the [Solver] tries to hold true. In case of ambiguities, the [Solver] will
/// use priorities to determine [Constraint] precedence. Once a [Constraint] is
/// added to the [Solver], this [Priority] cannot be changed.
abstract class Constraint {
  /// The [Relation] between a [Constraint] [Expression] and zero.
  Relation get relation;

  /// The [Constraint] [Expression]. The [Expression] on the right hand side of
  /// constraint must be zero. If the [Expression] on the right is not zero,
  /// it must be negated from the left hand [Expression] before a [Constraint]
  /// can be created.
  Expression get expression;

  /// The [Constraint] [Priority]. The [Priority] can only be modified when the
  /// [Constraint] is being created. Once it is added to the solver,
  /// modifications to the [Constraint] [Priority] will have no effect on the
  /// how the solver evaluates the constraint.
  /// TODO it would be great if this didn't have to be mutable.
  abstract double priority;

  /// The operator `|` is overloaded as a convenience so that constraint
  /// priorities can be specified along with the [Constraint] expression.
  ///
  /// For example: `ax + by + cx <= 0 | Priority.weak`. See [Priority].
  Constraint operator |(
    final double p,
  );
}

/// Relationships between [Constraint] expressions.
///
/// A [Constraint] is created by specifying a relationship between two
/// expressions. The [Solver] tries to satisfy this relationship after the
/// [Constraint] has been added to it at a set priority.
enum Relation {
  /// The relationship between the left and right hand sides of the expression
  /// is `==`, (lhs == rhs).
  equalTo,

  /// The relationship between the left and right hand sides of the expression
  /// is `<=`, (lhs <= rhs).
  lessThanOrEqualTo,

  /// The relationship between the left and right hand sides of the expression
  /// is `>=`, (lhs => rhs).
  greaterThanOrEqualTo,
}

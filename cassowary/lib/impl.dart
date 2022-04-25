import 'base.dart';
import 'cassowary.dart';

class ConstantMemberImpl with EquationMemberMixin implements ConstantMember {
  const ConstantMemberImpl(
    final this.value,
  );

  @override
  Expression asExpression() => ExpressionImpl(<Term>[], value);

  @override
  final double value;

  @override
  bool get isConstant => true;

  @override
  Z match<Z>({
    required final Z Function(ConstantMember p1) constant,
    required final Z Function(Param p1) param,
    required final Z Function(Expression p1) expression,
    required final Z Function(Term p1) term,
  }) =>
      constant(this);
}

ParamImpl zeroParam() => ParamImpl(
      zeroVariable(),
      null,
    );

ParamImpl simpleParam(
  final double value,
) =>
    ParamImpl(
      VariableImpl(
        value,
        null,
      ),
      null,
    );

ParamImpl simpleNamedParam(
  final double value,
  final String name,
) =>
    ParamImpl(
      VariableImpl(
        value,
        name,
      ),
      null,
    );

ParamImpl paramWithContext(
  final Object? context,
  final Variable variable,
) =>
    ParamImpl(variable, context);

class ParamImpl with EquationMemberMixin implements Param {
  @override
  final Variable variable;

  @override
  Object? context;

  ParamImpl(this.variable, this.context) {
    variable.owner = this;
  }

  @override
  Expression asExpression() => ExpressionImpl(
        <Term>[
          TermImpl(
            variable,
            1,
          ),
        ],
        0,
      );

  @override
  bool get isConstant => false;

  @override
  double get value => variable.value;

  @override
  String? get name => variable.name;

  @override
  Z match<Z>({
    required final Z Function(ConstantMember p1) constant,
    required final Z Function(Param p1) param,
    required final Z Function(Expression p1) expression,
    required final Z Function(Term p1) term,
  }) =>
      param(this);
}

/// Creates a new linear [Expression] by copying the terms and constant of
/// another expression.
ExpressionImpl expressionFromExpression(
  final Expression expr,
) =>
    ExpressionImpl(
      List<Term>.from(expr.terms),
      expr.constant,
    );

class ExpressionImpl implements Expression {
  /// Creates a new linear [Expression] using the given terms and constant.
  @override
  final List<Term> terms;

  @override
  final double constant;

  ExpressionImpl(
    final this.terms,
    final this.constant,
  );

  @override
  Expression asExpression() => this;

  @override
  bool get isConstant => terms.isEmpty;

  @override
  double get value => terms.fold(
        constant,
        (final value, final term) => value + term.value,
      );

  @override
  Constraint operator >=(
    final EquationMember value,
  ) =>
      _createConstraint(
        value,
        Relation.greaterThanOrEqualTo,
      );

  @override
  Constraint operator <=(
    final EquationMember value,
  ) =>
      _createConstraint(
        value,
        Relation.lessThanOrEqualTo,
      );

  @override
  Constraint equals(
    final EquationMember value,
  ) =>
      _createConstraint(
        value,
        Relation.equalTo,
      );

  Constraint _createConstraint(
    final EquationMember /* rhs */ value,
    final Relation relation,
  ) {
    return value.match(
      constant: (final value) => ConstraintImpl(
        expression: ExpressionImpl(
          List<Term>.from(terms),
          constant - value.value,
        ),
        relation: relation,
        priority: Priority.required,
      ),
      param: (final value) {
        return ConstraintImpl(
          expression: ExpressionImpl(
            List<Term>.from(terms)
              ..add(
                TermImpl(
                  value.variable,
                  -1,
                ),
              ),
            constant,
          ),
          relation: relation,
          priority: Priority.required,
        );
      },
      expression: (final value) => ConstraintImpl(
        expression: ExpressionImpl(
          value.terms.fold<List<Term>>(
            List<Term>.from(terms),
            (final list, final t) => list
              ..add(
                TermImpl(
                  t.variable,
                  -t.coefficient,
                ),
              ),
          ),
          constant - value.constant,
        ),
        relation: relation,
        priority: Priority.required,
      ),
      term: (final value) => ConstraintImpl(
        expression: ExpressionImpl(
          List<Term>.from(terms)
            ..add(
              TermImpl(
                value.variable,
                -value.coefficient,
              ),
            ),
          constant,
        ),
        relation: relation,
        priority: Priority.required,
      ),
    );
  }

  @override
  Expression operator +(
    final EquationMember m,
  ) =>
      m.match(
        constant: (final m) => ExpressionImpl(
          List<Term>.from(terms),
          constant + m.value,
        ),
        param: (final m) => ExpressionImpl(
          List<Term>.from(terms)
            ..add(
              TermImpl(
                m.variable,
                1,
              ),
            ),
          constant,
        ),
        expression: (final m) => ExpressionImpl(
          List<Term>.from(terms)..addAll(m.terms),
          constant + m.constant,
        ),
        term: (final m) => ExpressionImpl(
          List<Term>.from(terms)..add(m),
          constant,
        ),
      );

  @override
  Expression operator -(
    final EquationMember m,
  ) {
    return m.match(
      constant: (final m) => ExpressionImpl(
        [...terms],
        constant - m.value,
      ),
      param: (final m) => ExpressionImpl(
        [
          ...terms,
          TermImpl(
            m.variable,
            -1,
          ),
        ],
        constant,
      ),
      expression: (final m) => ExpressionImpl(
        [
          ...terms,
          for (final t in m.terms)
            TermImpl(
              t.variable,
              -t.coefficient,
            ),
        ],
        constant - m.constant,
      ),
      term: (final m) => ExpressionImpl(
        [
          ...terms,
          TermImpl(
            m.variable,
            -m.coefficient,
          )
        ],
        constant,
      ),
    );
  }

  @override
  Expression operator *(
    final EquationMember m,
  ) {
    final args = _findMulitplierAndMultiplicand(m);
    if (args == null) {
      throw CassowaryException(
        'Could not find constant multiplicand or multiplier',
        [
          this,
          m,
        ],
      );
    } else {
      return args.multiplier.applyMultiplicand(args.multiplicand);
    }
  }

  @override
  Expression operator /(
    final EquationMember m,
  ) {
    if (!m.isConstant) {
      throw CassowaryException(
        'The divisor was not a constant expression',
        [
          this,
          m,
        ],
      );
    } else {
      return applyMultiplicand(1.0 / m.value);
    }
  }

  _Multiplication? _findMulitplierAndMultiplicand(
    final EquationMember m,
  ) {
    if (!isConstant) {
      if (!m.isConstant) {
        // At least one of the the two members must be constant for the resulting
        // expression to be linear
        return null;
      } else {
        return _Multiplication._(
          multiplier: asExpression(),
          multiplicand: m.value,
        );
      }
    } else {
      return _Multiplication._(
        multiplier: m.asExpression(),
        multiplicand: value,
      );
    }
  }

  @override
  Expression applyMultiplicand(
    final double m,
  ) {
    final newTerms = terms.fold<List<Term>>(
      [],
      (final list, final term) => list
        ..add(
          TermImpl(
            term.variable,
            term.coefficient * m,
          ),
        ),
    );
    return ExpressionImpl(
      newTerms,
      constant * m,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (final t in terms) {
      buffer.write('$t');
    }
    if (constant != 0.0) {
      buffer
        ..write(
          () {
            if (constant.sign > 0.0) {
              return '+';
            } else {
              return '-';
            }
          }(),
        )
        ..write(
          constant.abs(),
        );
    }
    return buffer.toString();
  }

  @override
  Z match<Z>({
    required final Z Function(ConstantMember p1) constant,
    required final Z Function(Param p1) param,
    required final Z Function(Expression p1) expression,
    required final Z Function(Term p1) term,
  }) =>
      expression(this);
}

class _Multiplication {
  final Expression multiplier;
  final double multiplicand;

  const _Multiplication._({
    required final this.multiplier,
    required final this.multiplicand,
  });
}

class TermImpl with EquationMemberMixin implements Term {
  /// Creates term with the given [Variable] and coefficient.
  TermImpl(
    final this.variable,
    final this.coefficient,
  );

  @override
  final Variable variable;

  @override
  final double coefficient;

  @override
  Expression asExpression() => ExpressionImpl(
        <Term>[
          TermImpl(
            variable,
            coefficient,
          ),
        ],
        0,
      );

  @override
  bool get isConstant => false;

  @override
  double get value => coefficient * variable.value;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write(
        () {
          if (coefficient.sign > 0.0) {
            return '+';
          } else {
            return '-';
          }
        }(),
      );
    if (coefficient.abs() != 1.0) {
      buffer
        ..write(coefficient.abs())
        ..write('*');
    }
    buffer.write(variable);
    return buffer.toString();
  }

  @override
  Z match<Z>({
    required final Z Function(ConstantMember p1) constant,
    required final Z Function(Param p1) param,
    required final Z Function(Expression p1) expression,
    required final Z Function(Term p1) term,
  }) =>
      term(this);
}

mixin EquationMemberMixin implements EquationMember {
  @override
  Constraint operator >=(
    final EquationMember m,
  ) =>
      asExpression() >= m;

  @override
  Constraint operator <=(
    final EquationMember m,
  ) =>
      asExpression() <= m;

  @override
  Constraint equals(
    final EquationMember m,
  ) =>
      asExpression().equals(m);

  @override
  Expression operator +(
    final EquationMember m,
  ) =>
      asExpression() + m;

  @override
  Expression operator -(
    final EquationMember m,
  ) =>
      asExpression() - m;

  @override
  Expression operator *(
    final EquationMember m,
  ) =>
      asExpression() * m;

  @override
  Expression operator /(
    final EquationMember m,
  ) =>
      asExpression() / m;
}

VariableImpl unnamedVariable(
  final double value,
) =>
    VariableImpl(value, null);

VariableImpl zeroVariable() => VariableImpl(0.0, null);

class VariableImpl implements Variable {
  VariableImpl(
    final this.value,
    final this.name,
  );

  @override
  double value;

  @override
  String? name;

  @override
  Param? owner;

  @override
  bool applyUpdate(
    final double updated,
  ) {
    final res = updated != value;
    value = updated;
    return res;
  }
}

class ConstraintImpl implements Constraint {
  @override
  final Relation relation;
  @override
  final Expression expression;

  @override
  double priority;

  /// Creates a new [Constraint] by specifying a single [Expression]. This
  /// assumes that the right hand side [Expression] is the constant zero.
  /// (`<expression> <relation> <0>`)
  ConstraintImpl({
    required final this.expression,
    required final this.relation,
    required final this.priority,
  });

  @override
  Constraint operator |(
    final double p,
  ) =>
      this..priority = p;

  @override
  String toString() {
    final buffer = StringBuffer()..write(expression.toString());
    switch (relation) {
      case Relation.equalTo:
        buffer.write(' == 0 ');
        break;
      case Relation.greaterThanOrEqualTo:
        buffer.write(' >= 0 ');
        break;
      case Relation.lessThanOrEqualTo:
        buffer.write(' <= 0 ');
        break;
    }
    buffer.write(' | priority = $priority');
    if (priority == Priority.required) {
      buffer.write(' (required)');
    }
    return buffer.toString();
  }
}

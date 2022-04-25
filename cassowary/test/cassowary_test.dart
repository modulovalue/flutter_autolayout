import 'package:cassowary/base.dart';
import 'package:cassowary/cassowary.dart';
import 'package:cassowary/impl.dart';
import 'package:test/test.dart';

// TODO migrate to texpect
void main() {
  test('variable', () {
    final v = simpleParam(22.0);
    expect(v.value, 22);
  });
  test('variable1', () {
    final v = simpleParam(22.0);
    expect((v + const ConstantMemberImpl(22)).value, 44.0);
    expect((v - const ConstantMemberImpl(20)).value, 2.0);
  });
  test('term', () {
    final t = TermImpl(VariableImpl(22, null), 2);
    expect(t.value, 44);
  });
  test('expression', () {
    final terms = <Term>[
      TermImpl(VariableImpl(22, null), 2),
      TermImpl(VariableImpl(1, null), 1),
    ];
    final e = ExpressionImpl(terms, 40);
    expect(e.value, 85.0);
  });
  bool _is<T>(
    final Object value,
  ) =>
      value is T;
  test('expression1', () {
    final v1 = simpleParam(10.0);
    final v2 = simpleParam(10.0);
    final v3 = simpleParam(22.0);
    expect((v1 + v2).value, 20.0);
    expect((v1 - v2).value, 0.0);
    expect(_is<Expression>(v1 + v2 + v3), true);
    expect((v1 + v2 + v3).value, 42.0);
  });
  test('expression2', () {
    final e = simpleParam(10.0) + const ConstantMemberImpl(5);
    expect(e.value, 15.0);
    // Constant
    expect(_is<Expression>(e + const ConstantMemberImpl(2)), true);
    expect((e + const ConstantMemberImpl(2)).value, 17.0);
    expect(_is<Expression>(e - const ConstantMemberImpl(2)), true);
    expect((e - const ConstantMemberImpl(2)).value, 13.0);
    expect(e.value, 15.0);
    // Param
    final v = simpleParam(2);
    expect(_is<Expression>(e + v), true);
    expect((e + v).value, 17.0);
    expect(_is<Expression>(e - v), true);
    expect((e - v).value, 13.0);
    expect(e.value, 15.0);
    // Term
    final t = TermImpl(v.variable, 2);
    expect(_is<Expression>(e + t), true);
    expect((e + t).value, 19.0);
    expect(_is<Expression>(e - t), true);
    expect((e - t).value, 11.0);
    expect(e.value, 15.0);
    // Expression
    final e2 = simpleParam(7) + simpleParam(3);
    expect(_is<Expression>(e + e2), true);
    expect((e + e2).value, 25.0);
    expect(_is<Expression>(e - e2), true);
    expect((e - e2).value, 5.0);
    expect(e.value, 15.0);
  });
  test('term2', () {
    final t = TermImpl(VariableImpl(12, null), 1);
    // Constant
    const c = ConstantMemberImpl(2);
    expect(_is<Expression>(t + c), true);
    expect((t + c).value, 14.0);
    expect(_is<Expression>(t - c), true);
    expect((t - c).value, 10.0);
    // Variable
    final v = simpleParam(2);
    expect(_is<Expression>(t + v), true);
    expect((t + v).value, 14.0);
    expect(_is<Expression>(t - v), true);
    expect((t - v).value, 10.0);
    // Term
    final t2 = TermImpl(VariableImpl(1, null), 2);
    expect(_is<Expression>(t + t2), true);
    expect((t + t2).value, 14.0);
    expect(_is<Expression>(t - t2), true);
    expect((t - t2).value, 10.0);
    // Expression
    final exp = simpleParam(1) + const ConstantMemberImpl(1);
    expect(_is<Expression>(t + exp), true);
    expect((t + exp).value, 14.0);
    expect(_is<Expression>(t - exp), true);
    expect((t - exp).value, 10.0);
  });
  test('variable3', () {
    final v = simpleParam(3);
    // Constant
    const c = ConstantMemberImpl(2);
    expect(_is<Expression>(v + c), true);
    expect((v + c).value, 5.0);
    expect(_is<Expression>(v - c), true);
    expect((v - c).value, 1.0);
    // Variable
    final v2 = simpleParam(2);
    expect(_is<Expression>(v + v2), true);
    expect((v + v2).value, 5.0);
    expect(_is<Expression>(v - v2), true);
    expect((v - v2).value, 1.0);
    // Term
    final t2 = TermImpl(VariableImpl(1, null), 2);
    expect(_is<Expression>(v + t2), true);
    expect((v + t2).value, 5.0);
    expect(_is<Expression>(v - t2), true);
    expect((v - t2).value, 1.0);
    // Expression
    final exp = simpleParam(1) + const ConstantMemberImpl(1);
    expect(exp.terms.length, 1);
    expect(_is<Expression>(v + exp), true);
    expect((v + exp).value, 5.0);
    expect(_is<Expression>(v - exp), true);
    expect((v - exp).value, 1.0);
  });
  test('constantmember', () {
    const c = ConstantMemberImpl(3);
    // Constant
    const c2 = ConstantMemberImpl(2);
    expect(_is<Expression>(c + c2), true);
    expect((c + c2).value, 5.0);
    expect(_is<Expression>(c - c2), true);
    expect((c - c2).value, 1.0);
    // Variable
    final v2 = simpleParam(2);
    expect(_is<Expression>(c + v2), true);
    expect((c + v2).value, 5.0);
    expect(_is<Expression>(c - v2), true);
    expect((c - v2).value, 1.0);
    // Term
    final t2 = TermImpl(VariableImpl(1, null), 2);
    expect(_is<Expression>(c + t2), true);
    expect((c + t2).value, 5.0);
    expect(_is<Expression>(c - t2), true);
    expect((c - t2).value, 1.0);
    // Expression
    final exp = simpleParam(1) + const ConstantMemberImpl(1);
    expect(_is<Expression>(c + exp), true);
    expect((c + exp).value, 5.0);
    expect(_is<Expression>(c - exp), true);
    expect((c - exp).value, 1.0);
  });
  test('constraint2', () {
    final left = simpleParam(10);
    final right = simpleParam(100);
    final c = right - left >= const ConstantMemberImpl(25);
    // ignore: unnecessary_type_check
    expect(c is Constraint, true);
  });
  test('simple_multiplication', () {
    // Constant
    const c = ConstantMemberImpl(20);
    expect((c * const ConstantMemberImpl(2)).value, 40.0);
    // Variable
    final v = simpleParam(20);
    expect((v * const ConstantMemberImpl(2)).value, 40.0);
    // Term
    final t = TermImpl(v.variable, 1);
    expect((t * const ConstantMemberImpl(2)).value, 40.0);
    // Expression
    final e = ExpressionImpl(<Term>[t], 0);
    expect((e * const ConstantMemberImpl(2)).value, 40.0);
  });
  test('simple_division', () {
    // Constant
    const c = ConstantMemberImpl(20);
    expect((c / const ConstantMemberImpl(2)).value, 10.0);
    // Variable
    final v = simpleParam(20);
    expect((v / const ConstantMemberImpl(2)).value, 10.0);
    // Term
    final t = TermImpl(v.variable, 1);
    expect((t / const ConstantMemberImpl(2)).value, 10.0);
    // Expression
    final e = ExpressionImpl(<Term>[t], 0);
    expect((e / const ConstantMemberImpl(2)).value, 10.0);
  });
  test('full_constraints_setup', () {
    final left = simpleParam(2);
    final right = simpleParam(10);
    final c1 = right - left >= const ConstantMemberImpl(20);
    // ignore: unnecessary_type_check
    expect(c1 is Constraint, true);
    expect(c1.expression.constant, -20.0);
    expect(c1.relation, Relation.greaterThanOrEqualTo);
    final c2 = (right - left).equals(const ConstantMemberImpl(30));
    // ignore: unnecessary_type_check
    expect(c2 is Constraint, true);
    expect(c2.expression.constant, -30.0);
    expect(c2.relation, Relation.equalTo);
    final c3 = right - left <= const ConstantMemberImpl(30);
    // ignore: unnecessary_type_check
    expect(c3 is Constraint, true);
    expect(c3.expression.constant, -30.0);
    expect(c3.relation, Relation.lessThanOrEqualTo);
  });
  test('constraint_strength_update', () {
    final left = simpleParam(2);
    final right = simpleParam(10);
    final c = (right - left >= const ConstantMemberImpl(200)) | 750.0;
    // ignore: unnecessary_type_check
    expect(c is Constraint, true);
    expect(c.expression.terms.length, 2);
    expect(c.expression.constant, -200.0);
    expect(c.priority, 750.0);
  });
  test('solver', () {
    final s = SolverImpl();
    final left = simpleParam(2);
    final right = simpleParam(100);
    final c1 = right - left >= const ConstantMemberImpl(200);
    // ignore: unnecessary_type_check
    expect((right >= left) is Constraint, true);
    expect(s.addConstraint(c1), resultSuccess);
  });
  test('constraint_complex', () {
    final e = simpleParam(200) - simpleParam(100);
    // Constant
    final c1 = e >= const ConstantMemberImpl(50);
    // ignore: unnecessary_type_check
    expect(c1 is Constraint, true);
    expect(c1.expression.terms.length, 2);
    expect(c1.expression.constant, -50.0);
    // Variable
    final c2 = e >= simpleParam(2);
    // ignore: unnecessary_type_check
    expect(c2 is Constraint, true);
    expect(c2.expression.terms.length, 3);
    expect(c2.expression.constant, 0.0);
    // Term
    final c3 = e >= TermImpl(VariableImpl(2, null), 1);
    // ignore: unnecessary_type_check
    expect(c3 is Constraint, true);
    expect(c3.expression.terms.length, 3);
    expect(c3.expression.constant, 0.0);
    // Expression
    final c4 = e >= ExpressionImpl(<Term>[TermImpl(unnamedVariable(2), 1)], 20);
    // ignore: unnecessary_type_check
    expect(c4 is Constraint, true);
    expect(c4.expression.terms.length, 3);
    expect(c4.expression.constant, -20.0);
  });
  test('constraint_complex_non_exprs', () {
    // Constant
    final c1 = const ConstantMemberImpl(100) >= const ConstantMemberImpl(50);
    // ignore: unnecessary_type_check
    expect(c1 is Constraint, true);
    expect(c1.expression.terms.length, 0);
    expect(c1.expression.constant, 50.0);
    // Variable
    final c2 = simpleParam(100) >= simpleParam(2);
    // ignore: unnecessary_type_check
    expect(c2 is Constraint, true);
    expect(c2.expression.terms.length, 2);
    expect(c2.expression.constant, 0.0);
    // Term
    final t = TermImpl(unnamedVariable(100), 1);
    final c3 = t >= TermImpl(unnamedVariable(2), 1);
    // ignore: unnecessary_type_check
    expect(c3 is Constraint, true);
    expect(c3.expression.terms.length, 2);
    expect(c3.expression.constant, 0.0);
    // Expression
    final e = ExpressionImpl(<Term>[t], 0);
    final c4 = e >=
        ExpressionImpl(
          <Term>[
            TermImpl(
              unnamedVariable(2),
              1,
            ),
          ],
          20,
        );
    // ignore: unnecessary_type_check
    expect(c4 is Constraint, true);
    expect(c4.expression.terms.length, 2);
    expect(c4.expression.constant, -20.0);
  });
  test('constraint_update_in_solver', () {
    final s = SolverImpl();
    final left = simpleParam(2);
    final right = simpleParam(100);
    final c1 = right - left >= const ConstantMemberImpl(200);
    final c2 = right >= right;
    expect(s.addConstraint(c1), resultSuccess);
    expect(s.addConstraint(c1), resultDuplicateConstraint);
    expect(s.removeConstraint(c2), resultUnknownConstraint);
    expect(s.removeConstraint(c1), resultSuccess);
    expect(s.removeConstraint(c1), resultUnknownConstraint);
  });
  test('test_multiplication_division_override', () {
    const c = ConstantMemberImpl(10);
    final v = simpleParam(c.value);
    final t = TermImpl(v.variable, 1);
    final e = ExpressionImpl(<Term>[t], 0);
    // Constant
    expect((c * const ConstantMemberImpl(10)).value, 100);
    // Variable
    expect((v * const ConstantMemberImpl(10)).value, 100);
    // Term
    expect((t * const ConstantMemberImpl(10)).value, 100);
    // Expression
    expect((e * const ConstantMemberImpl(10)).value, 100);
    // Constant
    expect((c / const ConstantMemberImpl(10)).value, 1);
    // Variable
    expect((v / const ConstantMemberImpl(10)).value, 1);
    // Term
    expect((t / const ConstantMemberImpl(10)).value, 1);
    // Expression
    expect((e / const ConstantMemberImpl(10)).value, 1);
  });
  test('test_multiplication_division_exceptions', () {
    const c = ConstantMemberImpl(10);
    final v = simpleParam(c.value);
    final t = TermImpl(v.variable, 1);
    final e = ExpressionImpl(<Term>[t], 0);
    expect((c * c).value, 100);
    expect(() => v * v, throwsA(const TypeMatcher<CassowaryException>()));
    expect(() => v / v, throwsA(const TypeMatcher<CassowaryException>()));
    expect(() => v * t, throwsA(const TypeMatcher<CassowaryException>()));
    expect(() => v / t, throwsA(const TypeMatcher<CassowaryException>()));
    expect(() => v * e, throwsA(const TypeMatcher<CassowaryException>()));
    expect(() => v / e, throwsA(const TypeMatcher<CassowaryException>()));
    expect(() => v * c, returnsNormally);
    expect(() => v / c, returnsNormally);
  });
  test('edit_updates', () {
    final s = SolverImpl();
    final left = simpleParam(0);
    final right = simpleParam(100);
    final mid = simpleParam(0);
    final c = left + right >= const ConstantMemberImpl(2) * mid;
    expect(s.addConstraint(c), resultSuccess);
    expect(s.addEditVariable(mid.variable, 999), resultSuccess);
    expect(s.addEditVariable(mid.variable, 999), resultDuplicateEditVariable);
    expect(s.removeEditVariable(mid.variable), resultSuccess);
    expect(s.removeEditVariable(mid.variable), resultUnknownEditVariable);
  });
  test('bug1', () {
    final left = simpleParam(0);
    final right = simpleParam(100);
    final mid = simpleParam(0);
    // ignore: unnecessary_type_check
    expect(((left + right) >= (const ConstantMemberImpl(2) * mid)) is Constraint, true);
  });
  test('single_item', () {
    final left = simpleParam(-20);
    SolverImpl()
      ..addConstraint(left >= const ConstantMemberImpl(0))
      ..flushUpdates();
    expect(left.value, 0.0);
  });
  test('midpoints', () {
    final left = simpleNamedParam(0, 'left');
    final right = simpleNamedParam(0, 'right');
    final mid = simpleNamedParam(0, 'mid');
    final s = SolverImpl();
    expect(s.addConstraint((right + left).equals(mid * const ConstantMemberImpl(2))), resultSuccess);
    expect(s.addConstraint(right - left >= const ConstantMemberImpl(100)), resultSuccess);
    expect(s.addConstraint(left >= const ConstantMemberImpl(0)), resultSuccess);
    s.flushUpdates();
    expect(left.value, 0.0);
    expect(mid.value, 50.0);
    expect(right.value, 100.0);
  });
  test('addition_of_multiple', () {
    final left = simpleParam(0);
    final right = simpleParam(0);
    final mid = simpleParam(0);
    final s = SolverImpl();
    final c = left >= const ConstantMemberImpl(0);
    expect(
        s.addConstraints(<Constraint>[
          (left + right).equals(const ConstantMemberImpl(2) * mid),
          (right - left >= const ConstantMemberImpl(100)),
          c
        ]),
        resultSuccess);
    expect(s.addConstraints(<Constraint>[(right >= const ConstantMemberImpl(-20)), c]), resultDuplicateConstraint);
  });
  test('edit_constraints', () {
    final left = simpleNamedParam(0, 'left');
    final right = simpleNamedParam(0, 'right');
    final mid = simpleNamedParam(0, 'mid');
    final s = SolverImpl();
    expect(s.addConstraint((right + left).equals(mid * const ConstantMemberImpl(2))), resultSuccess);
    expect(s.addConstraint(right - left >= const ConstantMemberImpl(100)), resultSuccess);
    expect(s.addConstraint(left >= const ConstantMemberImpl(0)), resultSuccess);
    expect(s.addEditVariable(mid.variable, Priority.strong), resultSuccess);
    expect(s.suggestValueForVariable(mid.variable, 300), resultSuccess);
    s.flushUpdates();
    expect(left.value, 0.0);
    expect(mid.value, 300.0);
    expect(right.value, 600.0);
  });
  test('test_description', () {
    final left = simpleParam(0);
    final right = simpleParam(100);
    final c1 = right >= left;
    final c2 = right <= left;
    final c3 = right.equals(left);
    final s = SolverImpl();
    expect(s.addConstraint(c1), resultSuccess);
    expect(s.addConstraint(c2), resultSuccess);
    expect(s.addConstraint(c3), resultSuccess);
  });
  test('solution_with_optimize', () {
    final p1 = zeroParam();
    final p2 = zeroParam();
    final p3 = zeroParam();
    final container = zeroParam();
    SolverImpl()
      ..addEditVariable(container.variable, Priority.strong)
      ..suggestValueForVariable(container.variable, 100)
      ..addConstraint((p1 >= const ConstantMemberImpl(30)) | Priority.strong)
      ..addConstraint(p1.equals(p3) | Priority.medium)
      ..addConstraint(p2.equals(const ConstantMemberImpl(2) * p1))
      ..addConstraint(container.equals(p1 + p2 + p3))
      ..flushUpdates();
    expect(container.value, 100.0);
    expect(p1.value, 30.0);
    expect(p2.value, 60.0);
    expect(p3.value, 10.0);
  });
  test('test_updates_collection', () {
    final left = paramWithContext('left', zeroVariable());
    final mid = paramWithContext('mid', zeroVariable());
    final right = paramWithContext('right', zeroVariable());
    final s = SolverImpl();
    expect(s.addEditVariable(mid.variable, Priority.strong), resultSuccess);
    expect(s.addConstraint((mid * const ConstantMemberImpl(2)).equals(left + right)), resultSuccess);
    expect(s.addConstraint(left >= const ConstantMemberImpl(0)), resultSuccess);
    expect(s.suggestValueForVariable(mid.variable, 50), resultSuccess);
    final updates = s.flushUpdates();
    expect(updates.length, 2);
    expect(left.value, 0.0);
    expect(mid.value, 50.0);
    expect(right.value, 100.0);
  });
  test('test_updates_collection_is_set', () {
    final left = paramWithContext('a', zeroVariable());
    final mid = paramWithContext('a', zeroVariable());
    final right = paramWithContext('a', zeroVariable());
    final s = SolverImpl();
    expect(s.addEditVariable(mid.variable, Priority.strong), resultSuccess);
    expect(s.addConstraint((mid * const ConstantMemberImpl(2)).equals(left + right)), resultSuccess);
    expect(s.addConstraint(left >= const ConstantMemberImpl(10)), resultSuccess);
    expect(s.suggestValueForVariable(mid.variable, 50), resultSuccess);
    final updates = s.flushUpdates();
    expect(updates.length, 1);
    expect(left.value, 10.0);
    expect(mid.value, 50.0);
    expect(right.value, 90.0);
  });
  test('param_context_non_final', () {
    final p = paramWithContext('a', zeroVariable())..context = 'b';
    expect(p.context, 'b');
  });
  test('check_type_of_eq_result', () {
    final left = zeroParam();
    final right = zeroParam();
    expect(left.equals(right).runtimeType, ConstraintImpl);
  });
  test('bulk_add_edit_variables', () {
    final s = SolverImpl();
    final left = simpleParam(0);
    final right = simpleParam(100);
    final mid = simpleParam(0);
    expect(s.addEditVariables(<Variable>[left.variable, right.variable, mid.variable], 999), resultSuccess);
  });
  test('bulk_remove_constraints_and_variables', () {
    final s = SolverImpl();
    final left = simpleParam(0);
    final right = simpleParam(100);
    final mid = simpleParam(0);
    expect(s.addEditVariables(<Variable>[left.variable, right.variable, mid.variable], 999), resultSuccess);
    final c1 = left <= mid;
    final c2 = mid <= right;
    expect(s.addConstraints(<Constraint>[c1, c2]), resultSuccess);
    expect(s.removeConstraints(<Constraint>[c1, c2]), resultSuccess);
    expect(s.removeEditVariables(<Variable>[left.variable, right.variable, mid.variable]), resultSuccess);
  });
}

import 'package:cassowary/cassowary.dart';
import 'package:cassowary/impl.dart';

void main() {
  final solver = SolverImpl();
  final left = simpleParam(10.0);
  final right = simpleParam(20.0);
  final widthAtLeast100 = right - left >= const ConstantMemberImpl(100);
  final edgesPositive = (left >= const ConstantMemberImpl(0))..priority = Priority.weak;
  solver
    ..addConstraints(
      [
        widthAtLeast100,
        edgesPositive,
      ],
    )
    ..flushUpdates();
  print(
    'left: ' + left.value.toString() + ', right: ' + right.value.toString(),
  );
  final mid = VariableImpl(15, null);
  // It appears that == isn't defined
  solver
    ..addConstraint(
      (left + right).equals(
        TermImpl(mid, 1) * const ConstantMemberImpl(2),
      ),
    )
    ..addEditVariable(
      mid,
      Priority.strong,
    )
    ..flushUpdates();
  print(
    'left: ' + left.value.toString() + ', mid: ' + mid.value.toString() + ', right: ' + right.value.toString(),
  );
}

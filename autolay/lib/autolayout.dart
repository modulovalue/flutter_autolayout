import 'package:cassowary/base.dart';
import 'package:cassowary/cassowary.dart';
import 'package:cassowary/impl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that uses the cassowary constraint solver to
/// automatically size and position children.
class AutoLayout extends MultiChildRenderObjectWidget {
  /// The delegate that generates constraints for the layout.
  ///
  /// If the delegate is null, the layout is unconstrained.
  final AutoLayoutDelegate? delegate;

  AutoLayout({
    final Key? key,
    final this.delegate,
    final List<Widget> children = const <Widget>[],
  }) : super(
          key: key,
          children: children,
        );

  @override
  RenderAutoLayout createRenderObject(
    final BuildContext context,
  ) =>
      RenderAutoLayout(
        delegate: delegate,
        children: [],
      );

  @override
  void updateRenderObject(
    final BuildContext context,
    final RenderAutoLayout renderObject,
  ) =>
      renderObject.delegate = delegate;
}

/// A widget that provides constraints for a child of an [AutoLayout] widget.
///
/// An [AutoLayoutChild] widget must be a descendant of an [AutoLayout], and
/// the path from the [AutoLayoutChild] widget to its enclosing [AutoLayout]
/// must contain only [StatelessWidget]s or [StatefulWidget]s (not other kinds
/// of widgets, like [RenderObjectWidget]s).
class AutoLayoutChild extends ParentDataWidget<AutoLayoutParentData> {
  /// The constraints to use for this child.
  ///
  /// The object identity of the [rect] object must be unique among children of
  /// a given [AutoLayout] widget.
  ///
  /// If null, the child's size and position are unconstrained.
  final AutoLayoutRect? rect;

  /// Creates a widget that provides constraints for a child of an [AutoLayout] widget.
  ///
  /// The object identity of the [rect] argument must be unique among children
  /// of a given [AutoLayout] widget.
  AutoLayoutChild({
    required final Widget child,
    final this.rect,
  }) : super(
          key: () {
            if (rect != null) {
              return ObjectKey(rect);
            } else {
              return null;
            }
          }(),
          child: child,
        );

  @override
  void applyParentData(
    final RenderObject renderObject,
  ) {
    final parentData = (renderObject.parentData as AutoLayoutParentData?)!;
    // AutoLayoutParentData filters out redundant writes and marks needs layout
    // as appropriate.
    parentData.rect = rect;
  }

  @override
  Type get debugTypicalAncestorWidgetClass => AutoLayout;
}

/// Parent data for use with [RenderAutoLayout].
class AutoLayoutParentData extends ContainerBoxParentData<RenderBox> {
  final RenderBox _renderBox;

  /// Creates parent data associated with the given render box.
  AutoLayoutParentData(
    final this._renderBox,
  );

  /// Parameters that represent the size and position of the render box.
  AutoLayoutRect? get rect => _rect;
  AutoLayoutRect? _rect;

  set rect(
    final AutoLayoutRect? value,
  ) {
    if (_rect == value) {
      return;
    } else {
      if (_rect != null) {
        _removeImplicitConstraints();
      }
      _rect = value;
      if (_rect != null) {
        _addImplicitConstraints();
      }
    }
  }

  BoxConstraints get _constraintsFromSolver => BoxConstraints.tightFor(
        width: _rect!.right.value - _rect!.left.value,
        height: _rect!.bottom.value - _rect!.top.value,
      );

  Offset get _offsetFromSolver => Offset(
        _rect!.left.value,
        _rect!.top.value,
      );

  List<Constraint>? _implicitConstraints;

  void _addImplicitConstraints() {
    if (_renderBox.parent == null || _rect == null) {
      return;
    } else {
      final implicit = _constructImplicitConstraints();
      // ignore: prefer_asserts_with_message
      assert(implicit.isNotEmpty);
      // ignore: prefer_asserts_with_message
      assert(_renderBox.parent is RenderAutoLayout);
      final parent = (_renderBox.parent as RenderAutoLayout?)!;
      final result = parent._solver.addConstraints(implicit);
      // ignore: prefer_asserts_with_message
      assert(result == resultSuccess);
      parent.markNeedsLayout();
      _implicitConstraints = implicit;
    }
  }

  void _removeImplicitConstraints() {
    if (_renderBox.parent == null || _implicitConstraints == null || _implicitConstraints!.isEmpty) {
      return;
    } else {
      final parent = (_renderBox.parent as RenderAutoLayout?)!;
      final result = parent._solver.removeConstraints(_implicitConstraints!);
      // ignore: prefer_asserts_with_message
      assert(result == resultSuccess);
      parent.markNeedsLayout();
      _implicitConstraints = null;
    }
  }

  /// Returns the set of implicit constraints that need to be applied to all
  /// instances of this class when they are moved into a render object with an
  /// active solver. If no implicit constraints needs to be applied, the object
  /// may return null.
  List<Constraint> _constructImplicitConstraints() => <Constraint>[
        _rect!.left >= const ConstantMemberImpl(0.0), // The left edge must be positive.
        _rect!.right >= _rect!.left, // Width must be positive.
        // TODO(chinmay): Check whether we need something similar for the top and bottom.
      ];
}

/// Subclass to control the layout of a [RenderAutoLayout].
abstract class AutoLayoutDelegate<SELF extends AutoLayoutDelegate<SELF>> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AutoLayoutDelegate();

  /// Returns the constraints to use when computing layout.
  ///
  /// The `parent` argument contains the parameters for the parent's position
  /// and size. Typical implementations will return constraints that determine
  /// the size and position of each child.
  ///
  /// The delegate interface does not provide a mechanism for obtaining the
  /// parameters for children. Subclasses are expected to obtain those
  /// parameters through some other mechanism.
  List<Constraint> getConstraints(
    final AutoLayoutRect parent,
  );

  /// Override this method to return true when new constraints need to be generated.
  bool shouldUpdateConstraints(
    final SELF oldDelegate,
  );
}

/// A render object that uses the cassowary constraint solver to automatically size and position children.
class RenderAutoLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, AutoLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, AutoLayoutParentData> {
  bool _needToUpdateConstraints;
  final AutoLayoutRect _rect = AutoLayoutRect();
  final Solver _solver = SolverImpl();
  final List<Constraint> _explicitConstraints = [];

  /// Creates a render box that automatically sizes and positions its children.
  RenderAutoLayout({
    required final AutoLayoutDelegate? delegate,
    required final List<RenderBox> children,
  })  : _delegate = delegate,
        _needToUpdateConstraints = delegate != null {
    _solver.addEditVariables(<Variable>[
      _rect.left.variable,
      _rect.right.variable,
      _rect.top.variable,
      _rect.bottom.variable,
    ], Priority.required - 1);
    addAll(children);
  }

  /// The delegate that generates constraints for the layout.
  ///
  /// If the new delegate is the same as the previous one, this does nothing.
  ///
  /// If the new delegate is the same class as the previous one, then the new
  /// delegate has its [AutoLayoutDelegate.shouldUpdateConstraints] called; if
  /// the result is `true`, then the delegate will be called.
  ///
  /// If the new delegate is a different class than the previous one, then the
  /// delegate will be called.
  ///
  /// If the delegate is null, the layout is unconstrained.
  AutoLayoutDelegate? get delegate => _delegate;
  AutoLayoutDelegate? _delegate;

  set delegate(
    final AutoLayoutDelegate? newDelegate,
  ) {
    if (_delegate == newDelegate) {
      return;
    } else {
      final oldDelegate = _delegate;
      _delegate = newDelegate;
      if (newDelegate == null) {
        // ignore: prefer_asserts_with_message
        assert(oldDelegate != null);
        _needToUpdateConstraints = true;
        markNeedsLayout();
      } else if (oldDelegate == null ||
          newDelegate.runtimeType != oldDelegate.runtimeType ||
          newDelegate.shouldUpdateConstraints(oldDelegate)) {
        _needToUpdateConstraints = true;
        markNeedsLayout();
      }
    }
  }

  void _setExplicitConstraints(
    final List<Constraint> constraints,
  ) {
    if (constraints.isNotEmpty) {
      if (_solver.addConstraints(constraints) == resultSuccess) {
        _explicitConstraints.addAll(constraints);
      }
    }
  }

  void _clearExplicitConstraints() {
    if (_explicitConstraints.isNotEmpty) {
      if (_solver.removeConstraints(_explicitConstraints) == resultSuccess) {
        _explicitConstraints.clear();
      }
    }
  }

  @override
  void adoptChild(
    final RenderObject child,
  ) {
    // Make sure to call super first to setup the parent data
    super.adoptChild(child);
    final childParentData = (child.parentData as AutoLayoutParentData?)!;
    childParentData._addImplicitConstraints();
    // ignore: prefer_asserts_with_message
    assert(child.parentData == childParentData);
  }

  @override
  void dropChild(
    final RenderObject child,
  ) {
    final childParentData = (child.parentData as AutoLayoutParentData?)!;
    childParentData._removeImplicitConstraints();
    // ignore: prefer_asserts_with_message
    assert(child.parentData == childParentData);
    super.dropChild(child);
  }

  @override
  void setupParentData(
    final RenderBox child,
  ) {
    if (child.parentData is! AutoLayoutParentData) {
      child.parentData = AutoLayoutParentData(child);
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() => size = constraints.biggest;

  Size? _previousSize;

  @override
  void performLayout() {
    bool needToFlushUpdates = false;
    if (_needToUpdateConstraints) {
      _clearExplicitConstraints();
      if (_delegate != null) {
        _setExplicitConstraints(_delegate!.getConstraints(_rect));
      }
      _needToUpdateConstraints = false;
      needToFlushUpdates = true;
    }
    if (size != _previousSize) {
      _solver
        ..suggestValueForVariable(_rect.left.variable, 0.0)
        ..suggestValueForVariable(_rect.top.variable, 0.0)
        ..suggestValueForVariable(_rect.bottom.variable, size.height)
        ..suggestValueForVariable(_rect.right.variable, size.width);
      _previousSize = size;
      needToFlushUpdates = true;
    }
    if (needToFlushUpdates) {
      _solver.flushUpdates();
    }
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = (child.parentData as AutoLayoutParentData?)!;
      child.layout(childParentData._constraintsFromSolver);
      childParentData.offset = childParentData._offsetFromSolver;
      // ignore: prefer_asserts_with_message
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(
    final BoxHitTestResult result, {
    required final Offset position,
  }) =>
      defaultHitTestChildren(
        result,
        position: position,
      );

  @override
  void paint(
    final PaintingContext context,
    final Offset offset,
  ) =>
      defaultPaint(context, offset);
}

/// Hosts the edge parameters and vends useful methods to construct expressions
/// for constraints. Also sets up and manages implicit constraints and edit
/// variables.
class AutoLayoutRect {
  /// A parameter that represents the left edge of the rectangle.
  final Param left;

  /// A parameter that represents the right edge of the rectangle.
  final Param right;

  /// A parameter that represents the top edge of the rectangle.
  final Param top;

  /// A parameter that represents the bottom edge of the rectangle.
  final Param bottom;

  /// Creates parameters for a rectangle for use with auto layout.
  AutoLayoutRect()
      : left = zeroParam(),
        right = zeroParam(),
        top = zeroParam(),
        bottom = zeroParam();

  /// An expression that represents the horizontal extent of the rectangle.
  Expression get width => right - left;

  /// An expression that represents the vertical extent of the rectangle.
  Expression get height => bottom - top;

  /// An expression that represents halfway between the left and right edges of the rectangle.
  Expression get horizontalCenter => (left + right) / const ConstantMemberImpl(2.0);

  /// An expression that represents halfway between the top and bottom edges of the rectangle.
  Expression get verticalCenter => (top + bottom) / const ConstantMemberImpl(2.0);

  /// Constraints that require that this rect contains the given rect.
  List<Constraint> contains(
    final AutoLayoutRect other,
  ) =>
      <Constraint>[
        other.left >= left,
        other.right <= right,
        other.top >= top,
        other.bottom <= bottom,
      ];
}

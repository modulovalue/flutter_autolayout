import 'package:cassowary/cassowary.dart';
import 'package:flutter/material.dart';
import 'package:modulovalue_project_widgets/all.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: App(),
    );
  }
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  double movedBy = 0.0;

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 70.0;
    return Scaffold(
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          shrinkWrap: true,
          children: [
            ...modulovalueTitle("Cassowary UI Demo", "cassowary_ui_demo"),
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(builder: (context, constraints) {
                final end = constraints.biggest.width;
                final positions = make(movedBy, cardWidth, end, 20.0, 10);
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      movedBy += details.delta.dx;
                      movedBy.clamp(0.0, end);
                    });
                  },
                  child: Container(
                    color: Colors.blue[100],
                    child: Container(
                      height: 200.0,
                      width: end,
                      child: Stack(
                        children: <Widget>[
                          ...positions
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            return Positioned(
                              left: entry.value.left.value,
                              top: 20.0,
                              height: 160,
                              child: Card(
                                child: Center(
                                  child: Container(
                                    width: 100.0,
                                    child: Text("${entry.key}"),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

List<CardRange> make(double movedBy, double cardWidth, double end, double space,
    int cardsAmount) {
  final solver = Solver();

  final cardPositions = List.generate(cardsAmount, (cardNr) {
    return CardRange(
      left: Param(0.0),
      right: Param(0.0),
    );
  });

  CardRange lastCard;
  cardPositions.forEach((card) {
    if (lastCard != null) {
      solver.addConstraints([
        card.left.equals(card.right + cm(cardWidth)),
        card.left.equals(lastCard.right + cm(space)),
      ]);
      lastCard = card;
    }
  });
  solver.addConstraint(cardPositions.first.left >= cm(0));
  solver.addConstraint(cardPositions.last.right <= cm(end));

  solver.flushUpdates();

  return cardPositions;
}

class CardRange {
  final Param left;
  final Param right;

  const CardRange({
    @required this.left,
    @required this.right,
  });
}
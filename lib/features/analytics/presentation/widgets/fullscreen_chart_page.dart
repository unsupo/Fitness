import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows [chart] full-bleed in forced landscape orientation — more room to
/// read a dense chart than the small card view allows. Restores the app's
/// normal (portrait) orientation on close.
class FullScreenChartPage extends StatefulWidget {
  const FullScreenChartPage({super.key, required this.title, required this.chart});

  final String title;
  final Widget chart;

  @override
  State<FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<FullScreenChartPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: widget.chart),
    );
  }
}

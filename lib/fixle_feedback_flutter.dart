// library fixle_feedback_flutter;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fixle_feedback_flutter/thread_data.dart';
import 'package:fixle_feedback_flutter/thread_widget.dart';
import 'package:flutter/material.dart';
import 'package:native_screenshot_ext/native_screenshot_ext.dart';

import 'primitive_wrapper.dart';

class Fixle {
  static final Fixle _instance = Fixle._internal();

  Fixle._internal();

  factory Fixle() {
    return _instance;
  }

  Offset offset = Offset(0, 200);
  OverlayEntry? fixleBarOverlayEntry;
  List<_Thread> threads = <_Thread>[];

  hideOverlay() {
    fixleBarOverlayEntry?.remove();
    fixleBarOverlayEntry = null;
  }

  showOverlay(BuildContext context) {
    if (fixleBarOverlayEntry == null) {
      fixleBarOverlayEntry = OverlayEntry(
          builder: (context) => Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                  onPanUpdate: (details) {
                    offset += details.delta;
                    fixleBarOverlayEntry!.markNeedsBuild();
                  },
                  child: FixleBar(fixleBarOverlayEntry, threads))));
      WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(fixleBarOverlayEntry!));
    }
  }
}

class FixleBar extends StatefulWidget {
  /// Never remove it; removing it didn't quite work. So hiding it instead using `hide`.
  final OverlayEntry? fixleBarOverlayEntry;
  final List<_Thread> threads;

  const FixleBar(this.fixleBarOverlayEntry, this.threads);

  @override
  State<StatefulWidget> createState() {
    return FixleBarState();
  }
}

enum FixBarStateEnum {
  visible,
  hidingForSnapshot,
  hidingAfterSnapshot,
}

class FixleBarState extends State<FixleBar> {
  FixBarStateEnum hide = FixBarStateEnum.visible;
  int currentVisibleThread = 0;

  @override
  Widget build(BuildContext context) {
    // Had to create states to avoid this being called again and again for some reason due to rebuild through
    // addThreadWithScreenshotOnFixBarAbsence -> hideThread -> removing Entries even when not needed to remove.
    if (hide == FixBarStateEnum.hidingForSnapshot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        addThreadWithScreenshotOnFixBarAbsence();
      });
      return Container();
    }

    if (hide == FixBarStateEnum.hidingAfterSnapshot) {
      return Container();
    }
    return Material(
        elevation: 10,
        shape: RoundedRectangleBorder(
          // side: BorderSide(color: Colors.black, width: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                height: 30.0,
                width: 30.0,
                child: IconButton(
                  onPressed: () async {
                    // Avoid adding new threads when already showing an image and a thread. Ask to minimize first.
                    if (widget.threads.isNotEmpty && widget.threads[currentVisibleThread].isNotHidden()) {
                      // TODO: Not working.
                      inform(context, 'Minimize the current thread before adding new comment');
                      return;
                    }
                    if (widget.threads.isNotEmpty) {
                      widget.threads[currentVisibleThread].hideThreadBoxAndImage();
                    }
                    setState(() {
                      hide = FixBarStateEnum.hidingForSnapshot;
                    });
                  },
                  icon: const Icon(Icons.add_comment),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  alignment: Alignment.center,
                )),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {}, padding: const EdgeInsets.fromLTRB(0, 10, 0, 30), icon: const Icon(Icons.list))),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {
                      if (widget.threads.isNotEmpty) {
                        widget.threads[currentVisibleThread].hideThreadBoxAndImage();
                        currentVisibleThread = (currentVisibleThread - 1) % widget.threads.length;
                        widget.threads[currentVisibleThread].rebuildThread(context, widget.fixleBarOverlayEntry);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_upward))),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {
                      if (widget.threads.isNotEmpty) {
                        widget.threads[currentVisibleThread].hideThreadBoxAndImage();
                        currentVisibleThread = (currentVisibleThread + 1) % widget.threads.length;
                        widget.threads[currentVisibleThread].rebuildThread(context, widget.fixleBarOverlayEntry);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_downward)))
          ],
        ));
  }

  void addThreadWithScreenshotOnFixBarAbsence() async {
    Uint8List pngData = await NativeScreenshot.takeScreenshotImage(1) as Uint8List;

    var newThread = _Thread.addNewThread(context, pngData, makeFixleOverlayVisible);
    currentVisibleThread = widget.threads.length;
    widget.threads.add(newThread);
    // This is important to avoid the method addThreadWithScreenshotOnFixBarAbsence being recalled becuase of some rebuild
    setState(() {
      hide = FixBarStateEnum.hidingAfterSnapshot;
    });
  }

  void makeFixleOverlayVisible() {
    if (hide != FixBarStateEnum.visible) {
      setState(() {
        hide = FixBarStateEnum.visible;
      });
    }
  }

  static inform(BuildContext? context, String? textMsg, {int? milliseconds}) {
    if (context == null || textMsg == null) {
      return;
    }
    var sn = SnackBar(
      content: Text(textMsg),
      elevation: 20,
      duration: Duration(milliseconds: milliseconds ?? 1000),
    );
    ScaffoldMessenger.of(context).showSnackBar(sn);
  }
}

class _Thread {
  late OverlayEntry threadBoxEntry;
  late OverlayEntry imageEntry;
  late ThreadData threadData;

  _Thread();

  factory _Thread.addNewThread(BuildContext context, Uint8List pngData, void Function() makeFixleOverlayVisible) {
    List<String> comments = [];
    var threadPosition = PrimitiveWrapper(const Offset(50, 50));
    var pngWidget = Image.memory(pngData);
    var threadData = ThreadData.fromNewThread(comments, threadPosition, pngData);
    var threadWidget = ThreadWidget(threadData, makeFixleOverlayVisible);
    OverlayEntry threadEntry = OverlayEntry(builder: (context) => threadWidget);
    OverlayEntry pngOverlay = OverlayEntry(builder: (context) => pngWidget);
    // Bad pattern, but no choice for now.
    threadWidget.threadMinimizingCallback = () {
      threadEntry.remove();
      pngOverlay.remove();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(pngOverlay));
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(threadEntry, above: pngOverlay));
    return _Thread()
      ..threadBoxEntry = threadEntry
      ..imageEntry = pngOverlay
      ..threadData = threadData;
  }

  bool isNotHidden() {
    return threadBoxEntry.mounted || imageEntry.mounted;
  }

  hideThreadBoxAndImage() {
    if (threadBoxEntry.mounted) {
      threadBoxEntry.remove();
    }
    if (imageEntry.mounted) {
      imageEntry.remove();
    }
  }

  rebuildThread(BuildContext context, OverlayEntry? fixleBarOverlayEntry) {
    if (!imageEntry.mounted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Overlay.of(context)?.insert(imageEntry, below: fixleBarOverlayEntry));
    }
    if (!threadBoxEntry.mounted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Overlay.of(context)?.insert(threadBoxEntry, above: fixleBarOverlayEntry));
    }
  }
}


class ImageWidget extends StatefulWidget {
  final Uint8List pngData;

  const ImageWidget(this.pngData);

  @override
  State<StatefulWidget> createState() {
    return ImageWidgetState();
  }
}

class ImageWidgetState extends State<ImageWidget> {
  @override
  Widget build(BuildContext context) {
    return Image.memory(widget.pngData);
  }
}

class ImagePainter extends CustomPainter {
  ImagePainter(this.image, this.pointsList);

  ui.Image image;

  List<DrawingPoints?> pointsList;
  List<Offset> offsetPoints = [];

  List<Offset> points = [];

  // final Paint painter = new Paint()

  @override
  void paint(Canvas canvas, Size size) {
    // canvas.drawImage(this.image, Offset(0.0, 0.0), Paint());
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final src = Offset.zero & imageSize;
    final dst = Offset.zero & size;
    // canvas.pic
    canvas.drawImageRect(this.image, src, dst, Paint());
    // for (Offset offset in points) {
    //   canvas.drawCircle(offset, 10, painter);
    // }
    pointsList = pointsList.map((e) {
      if (e != null) {
        if (e.points.dy <= dst.height) {
          return e;
        }
      }

      return null;
    }).toList();
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        canvas.drawLine(pointsList[i]!.points, pointsList[i + 1]!.points, pointsList[i]!.paint);
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        offsetPoints.clear();
        offsetPoints.add(pointsList[i]!.points);
        offsetPoints.add(Offset(pointsList[i]!.points.dx + 0.1, pointsList[i]!.points.dy + 0.1));
        canvas.drawPoints(ui.PointMode.points, offsetPoints, pointsList[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class DrawingPoints {
  Paint paint;
  Offset points;

  DrawingPoints(this.points, this.paint);
}
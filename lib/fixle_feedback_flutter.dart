// library fixle_feedback_flutter;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fixle_feedback_flutter/network_utils.dart';
import 'package:fixle_feedback_flutter/primitive_wrapper.dart';
import 'package:fixle_feedback_flutter/project_and_threads_data.dart';
import 'package:fixle_feedback_flutter/thread_widget.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:native_screenshot_ext/native_screenshot_ext.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Fixle {
  static final Fixle _instance = Fixle._internal();

  Fixle._internal();

  factory Fixle() {
    return _instance;
  }

  Offset offset = const Offset(0, 200);
  OverlayEntry? fixleBarOverlayEntry;

  hideOverlay() {
    fixleBarOverlayEntry?.remove();
    fixleBarOverlayEntry = null;
  }

  showOverlay(BuildContext context, String apiKey) {
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
                  child: Tooltip(
                      message:
                          'This is fixle bar; use it to add comments on screens, or go through previously made comments',
                      child: FixleBar(fixleBarOverlayEntry, apiKey)))));
      var overlayState = context.findAncestorStateOfType<OverlayState>();
      assert(() {
        if (overlayState == null) {
          final List<DiagnosticsNode> information = <DiagnosticsNode>[
            ErrorSummary(
                'Your app hasn\'t built yet. Don\'t initiate Fixle in the build method of the top-level widget.'),
            ErrorDescription(
                'Fixle requires a MaterialApp, CupertinoApp or Navigator widget to be built, before it can be built. '),
            ErrorHint(
                'Invoke the `Fixle().showOverlay(context, api_key_)` method inside the build method of second top level widget. The second-top level widget is the one that sits inside `MaterialApp(...)`. It is fine to mention `Fixle().showOverlay(context, api_key_)` in multiple widgets, you only create one Fixle widget.'),
          ];

          throw FlutterError.fromParts(information);
        }
        return true;
      }());
      WidgetsBinding.instance.addPostFrameCallback((_) => overlayState?.insert(fixleBarOverlayEntry!));
    }
  }
}

class FixleBar extends StatefulWidget {
  /// Never remove it; removing it didn't quite work. So hiding it instead using `hide`.
  final OverlayEntry? fixleBarOverlayEntry;
  final String projectId;
  const FixleBar(this.fixleBarOverlayEntry, this.projectId, {super.key});
  static Logger logger = Logger();

  @override
  State<StatefulWidget> createState() {
    return FixleBarState();
  }
}

enum FixleBarStateEnum {
  visible,
  hidingForSnapshot,
  hidingAfterSnapshot,
  alwaysHidden
}

enum FixleModeEnum {
  appRunning,
  addingNewThread,
  showingThreads,
}

class FixleBarState extends State<FixleBar> {
  FixleBarStateEnum hide = FixleBarStateEnum.alwaysHidden;
  FixleModeEnum mode = FixleModeEnum.appRunning;
  int currentVisibleThread = 0;
  List<Thread> threads = [];
  String currentVersion = "latest";
  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((packageInfo) => {
      currentVersion = packageInfo.version,
      NetworkRequestUtilsFixle.getAllThreads(widget.projectId, currentVersion).then((projectThreads) => {
        if (projectThreads.enabledVersions != null &&
            projectThreads.enabledVersions?.contains(currentVersion) == true)
          {
            setState(() {
              hide = FixleBarStateEnum.visible;
            }),
            if (projectThreads.threads != null)
              for (var thread in projectThreads.threads!)
                {
                  threads.add(Thread.loadThread(
                      context, thread.comments, thread.threadPosition, thread.pngData, widget.projectId, makeFixleOverlayVisible))
                }
          }
        else
          {
            FixleBar.logger.d(
                "Fixle not enabled for \"$currentVersion\". To enable, go to Fixle Dashboard(http://fixle-dash.web.app) -> Project -> Settings -> Enable version ")
          }
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    // Had to create states to avoid this being called again and again for some reason due to rebuild through
    // addThreadWithScreenshotOnFixBarAbsence -> hideThread -> removing Entries even when not needed to remove.
    if (hide == FixleBarStateEnum.hidingForSnapshot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        addThreadWithScreenshotOnFixBarAbsence();
      });
      return Container();
    }

    if (hide == FixleBarStateEnum.hidingAfterSnapshot || hide == FixleBarStateEnum.alwaysHidden) {
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
            (mode == FixleModeEnum.addingNewThread || mode == FixleModeEnum.showingThreads)
                ? Container()
                : SizedBox(
                    height: 30.0,
                    width: 30.0,
                    child: IconButton(
                      onPressed: () async {
                        // Avoid adding new threads when already showing an image and a thread. Ask to minimize first.
                        if (threads.isNotEmpty && threads[currentVisibleThread].isNotHidden()) {
                          // TODO: Not working.
                          inform(context, 'Minimize the current thread before adding new comment');
                          return;
                        }
                        if (threads.isNotEmpty) {
                          threads[currentVisibleThread].hideThreadBoxAndImage();
                        }
                        setState(() {
                          hide = FixleBarStateEnum.hidingForSnapshot;
                          mode = FixleModeEnum.addingNewThread;
                        });
                      },
                      icon: const Icon(Icons.add_comment),
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      alignment: Alignment.center,
                    )),
            /*SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {}, padding: const EdgeInsets.fromLTRB(0, 10, 0, 30), icon: const Icon(Icons.list))),*/
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: Tooltip(message:'',child:IconButton(
                    onPressed: () {
                      if (threads.isNotEmpty) {
                        threads[currentVisibleThread].hideThreadBoxAndImage();
                        currentVisibleThread = (currentVisibleThread - 1) % threads.length;
                        threads[currentVisibleThread].rebuildThread(context, widget.fixleBarOverlayEntry);
                        mode = FixleModeEnum.showingThreads;
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_upward)))),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {
                      if (threads.isNotEmpty) {
                        threads[currentVisibleThread].hideThreadBoxAndImage();
                        currentVisibleThread = (currentVisibleThread + 1) % threads.length;
                        threads[currentVisibleThread].rebuildThread(context, widget.fixleBarOverlayEntry);
                        mode = FixleModeEnum.showingThreads;
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_downward)))
          ],
        ));
  }

  void signInDialog() {
    Widget cancelButton = TextButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget okButton = Builder(
        builder: (bContext) => TextButton(
          child: const Text("Yes"),
          onPressed: () {
            Navigator.pop(context);

          },
        ));

    var loginDialog = AlertDialog(
      content: const Text("You need to signin first", textAlign: TextAlign.justify),
      actions: [cancelButton, okButton],
    );
    showDialog(
      context: context,
      builder: (BuildContext bcontext) {
        return loginDialog;
      },
    );
  }

  void addThreadWithScreenshotOnFixBarAbsence() async {
    Uint8List pngData = await NativeScreenshot.takeScreenshotImage(1) as Uint8List;

    var newThread = Thread.addNewThread(context, pngData, widget.projectId, makeFixleOverlayVisible);
    currentVisibleThread = threads.length;
    threads.add(newThread);
    setState(() {
      // This is important to avoid the method addThreadWithScreenshotOnFixBarAbsence being recalled because of some rebuild
      hide = FixleBarStateEnum.hidingAfterSnapshot;
    });
  }

  void makeFixleOverlayVisible() {
    if (hide != FixleBarStateEnum.visible) {
      setState(() {
        hide = FixleBarStateEnum.visible;
        mode = FixleModeEnum.appRunning;
      });
    } else {
      setState(() {
        mode = FixleModeEnum.appRunning;
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

class Thread {
  late OverlayEntry threadBoxEntry;
  late OverlayEntry imageEntry;
  late ThreadData threadData;

  Thread();

  factory Thread.addNewThread(BuildContext context, Uint8List pngData, String projectId, void Function() makeFixleOverlayVisible) {
    List<Comment> comments = [];
    var threadPosition = PrimitiveWrapper(const Offset(50, 50));
    var pngWidget = Image.memory(pngData);
    var threadData = ThreadData.fromNewThread(comments, threadPosition, pngData);
    var threadWidget = ThreadWidget(threadData, makeFixleOverlayVisible, projectId);
    OverlayEntry threadEntry = OverlayEntry(builder: (context) => threadWidget);
    OverlayEntry pngOverlay = OverlayEntry(builder: (context) => pngWidget);
    // Bad pattern, but no choice for now.
    threadWidget.threadMinimizingCallback = () {
      threadEntry.remove();
      pngOverlay.remove();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(pngOverlay));
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(threadEntry, above: pngOverlay));
    return Thread()
      ..threadBoxEntry = threadEntry
      ..imageEntry = pngOverlay
      ..threadData = threadData;
  }

  factory Thread.loadThread(BuildContext context, List<Comment> comments, PrimitiveWrapper<Offset>? threadPosition,
      Uint8List pngData, String projectId, void Function() makeFixleOverlayVisible) {
    var pngWidget = Image.memory(pngData);
    var threadData = ThreadData.fromExistingThread(comments, threadPosition?? PrimitiveWrapper(const Offset(50, 50)), pngData);
    var threadWidget = ThreadWidget(threadData, makeFixleOverlayVisible, projectId);
    OverlayEntry threadEntry = OverlayEntry(builder: (context) => threadWidget);
    OverlayEntry pngOverlay = OverlayEntry(builder: (context) => pngWidget);
    // Bad pattern, but no choice for now.
    threadWidget.threadMinimizingCallback = () {
      threadEntry.remove();
      pngOverlay.remove();
    };
    return Thread()
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

  const ImageWidget(this.pngData, {super.key});

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
    canvas.drawImageRect(image, src, dst, Paint());
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

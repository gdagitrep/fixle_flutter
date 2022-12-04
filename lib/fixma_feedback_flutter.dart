// library fixma_feedback_flutter;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fixma_feedback_flutter/thread_data.dart';
import 'package:fixma_feedback_flutter/thread_widget.dart';
import 'package:flutter/material.dart';
import 'package:native_screenshot_ext/native_screenshot_ext.dart';

import 'primitive_wrapper.dart';

class Fixma {
  static final Fixma _instance = Fixma._internal();

  Fixma._internal();

  factory Fixma() {
    return _instance;
  }

  Offset offset = Offset(0, 200);
  OverlayEntry? fixmaOverlayEntry;
  List<_Thread> threads = <_Thread>[];

  hideOverlay() {
    fixmaOverlayEntry?.remove();
    fixmaOverlayEntry = null;
  }

  showOverlay(BuildContext context) {
    if (fixmaOverlayEntry == null) {
      fixmaOverlayEntry = OverlayEntry(
          builder: (context) => Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                  onPanUpdate: (details) {
                    offset += details.delta;
                    fixmaOverlayEntry!.markNeedsBuild();
                  },
                  child: FixmaBar(fixmaOverlayEntry, threads))));
      WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(fixmaOverlayEntry!));
    }
  }
}

class FixmaBar extends StatefulWidget {
  /// Never remove it; removing it didn't quite work. So hiding it instead using `hide`.
  final OverlayEntry? fixmaOverlayEntry;
  final List<_Thread> threads;

  const FixmaBar(this.fixmaOverlayEntry, this.threads);

  @override
  State<StatefulWidget> createState() {
    return FixmaBarState();
  }
}

enum FixBarStateEnum {
  visible,
  hidingForSnapshot,
  hidingAfterSnapshot,
}

class FixmaBarState extends State<FixmaBar> {
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
                        widget.threads[currentVisibleThread].rebuildThread(context, widget.fixmaOverlayEntry);
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
                        widget.threads[currentVisibleThread].rebuildThread(context, widget.fixmaOverlayEntry);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_downward)))
          ],
        ));
  }

  void addThreadWithScreenshotOnFixBarAbsence() async {
    Uint8List pngData = await NativeScreenshot.takeScreenshotImage(1) as Uint8List;

    var newThread = _Thread.addNewThread(context, pngData, makeFixmaOverlayVisible);
    currentVisibleThread = widget.threads.length;
    widget.threads.add(newThread);
    // This is important to avoid the method addThreadWithScreenshotOnFixBarAbsence being recalled becuase of some rebuild
    setState(() {
      hide = FixBarStateEnum.hidingAfterSnapshot;
    });
  }

  void makeFixmaOverlayVisible() {
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

  factory _Thread.addNewThread(BuildContext context, Uint8List pngData, void Function() makeFixmaOverlayVisible) {
    List<String> comments = [];
    var threadPosition = PrimitiveWrapper(const Offset(50, 50));
    var pngWidget = Image.memory(pngData);
    var threadData = ThreadData.fromNewThread(comments, threadPosition, pngData);
    var threadWidget = ThreadWidget(threadData, makeFixmaOverlayVisible);
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

  rebuildThread(BuildContext context, OverlayEntry? fixmaOverlayEntry) {
    if (!imageEntry.mounted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Overlay.of(context)?.insert(imageEntry, below: fixmaOverlayEntry));
    }
    if (!threadBoxEntry.mounted) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Overlay.of(context)?.insert(threadBoxEntry, above: fixmaOverlayEntry));
    }
  }
}



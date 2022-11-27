// library fixma_feedback_flutter;

import 'dart:typed_data';

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
          builder: (context) =>
              Positioned(
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
  final OverlayEntry? fixmaOverlayEntry;
  final List<_Thread> threads;

  FixmaBar(this.fixmaOverlayEntry, this.threads);

  @override
  State<StatefulWidget> createState() {
   return FixmaBarState();
  }
}
class FixmaBarState extends State<FixmaBar> {
  bool hide = false;
  int currentThreadIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (hide) {
      WidgetsBinding.instance.addPostFrameCallback((_) { addThreadWithScreenshotOnFixBarAbsence();});
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
                    setState(() {
                      hide = true;
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
                        widget.threads[currentThreadIndex].hideThread();
                        currentThreadIndex = (currentThreadIndex - 1) % widget.threads.length;
                        widget.threads[currentThreadIndex].rebuildThread(context, widget.fixmaOverlayEntry);
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
                        widget.threads[currentThreadIndex].hideThread();
                        currentThreadIndex = (currentThreadIndex + 1) % widget.threads.length;
                        widget.threads[currentThreadIndex].rebuildThread(context, widget.fixmaOverlayEntry);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_downward)))
          ],
        ));
  }

  void addThreadWithScreenshotOnFixBarAbsence () async {
    if (widget.threads.isNotEmpty) {
      widget.threads[currentThreadIndex].hideThread();
    }

    Uint8List pngData = await NativeScreenshot.takeScreenshotImage() as Uint8List;
    var newThread = _Thread.addNewThread(context, pngData, widget.fixmaOverlayEntry);
    currentThreadIndex = widget.threads.length;
    widget.threads.add(newThread);
    setState(() {
      hide = false;
    });
  }
}

class _ThreadData {
  List<String> comments = [];
  PrimitiveWrapper<Offset>? threadPosition;

  _ThreadData(this.comments, this.threadPosition);
}

class _Thread {
  late OverlayEntry entry;
  late OverlayEntry pngEntry;
  late _ThreadData threadData;
  late ValueNotifier<bool> minimized;

  _Thread();

  factory _Thread.addNewThread(BuildContext context, Uint8List pngData, OverlayEntry? fixmaOverlayEntry) {
    List<String> comments = [];
    var threadPosition = PrimitiveWrapper(const Offset(50, 50));
    ValueNotifier<bool> minimized = ValueNotifier(false);
    var pngWidget = ValueListenableBuilder(
        valueListenable: minimized,
        builder: (BuildContext context, bool val, Widget? child) {
          return val ?  Container(): Image.memory(pngData);
        });
    var threadWidget = _ThreadWidget(comments, threadPosition, minimized);
    OverlayEntry threadEntry = OverlayEntry(builder: (context) => threadWidget);
    OverlayEntry pngOverlay = OverlayEntry(builder: (context) => pngWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(pngOverlay, below: fixmaOverlayEntry));
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(threadEntry, above: fixmaOverlayEntry));
    return _Thread()
      ..entry = threadEntry
      ..pngEntry = pngOverlay
      ..minimized = minimized
      ..threadData = _ThreadData(comments, threadPosition);
  }

  hideThread() {
    entry.remove();
    pngEntry.remove();
  }

  rebuildThread(BuildContext context, OverlayEntry? fixmaOverlayEntry) {
    minimized.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(pngEntry, below: fixmaOverlayEntry));
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(entry, above: fixmaOverlayEntry));
  }
}

class _ThreadWidget extends StatefulWidget {
  final List<String> comments;
  final PrimitiveWrapper<Offset>? threadPosition;
  final ValueNotifier<bool> minimized;

  const _ThreadWidget(this.comments, this.threadPosition, this.minimized);

  @override
  State<StatefulWidget> createState() => _ThreadWidgetState();

}

class _ThreadWidgetState extends State<_ThreadWidget> {
  late List<String> comments;
  bool? isMinimized;
  PrimitiveWrapper<Offset>? threadPosition;
  bool? placeIsLocked;
  final fieldText = TextEditingController();
  static final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    comments = widget.comments;
    isMinimized = false;
    threadPosition = widget.threadPosition;
    placeIsLocked = false;
  }

  @override
  Widget build(BuildContext context) {
    return isMinimized == true ? minimizedThread() : commentThread(widget.comments);
  }

  Widget commentThread(List<String> previousComments) {
    Widget bottomBar() => SizedBox(
        height: 35,
        child: Row(
          children: [
            // if no comments, show cross button, or show minimize button
            IconButton(
              onPressed: () {
                setState(() {
                  isMinimized = true;
                });
                widget.minimized.value = true;
              },
              icon: Icon(
                comments.isEmpty? Icons.close : Icons.minimize,
                color: Colors.blue,
              ),
              padding: EdgeInsets.zero,
            ),
            Expanded(child: Container()),
            IconButton(
              onPressed: () {
                final form = formKey.currentState!;
                if (form.validate()) {
                  form.save();
                }
              },
              icon: const Icon(
                Icons.arrow_circle_right_outlined,
                color: Colors.blue,
              ),
              padding: EdgeInsets.zero,
            )
          ],
        ));
    List<Widget> children = <Widget>[];
    for(var comment in comments) {
      children.add(Text(comment));
    }
    children.add(TextFormField(
      controller: fieldText,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      maxLines: 10,
      minLines: 1,
      decoration: const InputDecoration(
        hintText: 'Add comment',
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Enter comment';
        }
        return null;
      },
      onSaved: (val) {
        comments.add(val!);
        fieldText.clear();
        setState(() {
          placeIsLocked = true;
        });
      },
    ));
    children.add(bottomBar());

    return Positioned(
        left: threadPosition?.value.dx,
        top: threadPosition?.value.dy,
        child: GestureDetector(
            onPanUpdate: (details) {
              if (placeIsLocked == false) {
                setState(() {
                  threadPosition?.value += details.delta;
                });
              }
            },
            child: Material(
                elevation: 10,
                child: SizedBox(
                    width: 200,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                        child: Form(key: formKey, child: Column(children: children)))))));
  }

  Widget minimizedThread() {
    return Positioned(
        left: 0,
        top: threadPosition?.value.dy,
        child: Material(
            elevation: 8,
            child: SizedBox(
                width: 50,
                child: IconButton(
                    onPressed: () {
                      setState(() {
                        isMinimized = false;
                      });
                      widget.minimized.value = false;
                    },
                    icon: const Icon(
                      Icons.line_axis,
                      color: Colors.blue,
                    )))));
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

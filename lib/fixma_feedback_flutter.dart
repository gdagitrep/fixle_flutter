// library fixma_feedback_flutter;

import 'package:flutter/material.dart';

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
                  child: fixmaBar(context))));
      var overlay = Overlay.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => overlay?.insert(fixmaOverlayEntry!));
    }
  }

  Widget fixmaBar(BuildContext context) {
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
                  onPressed: () {
                    var newThread = _Thread.addNewThread(context);
                  },
                  icon: const Icon(Icons.add_comment),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  alignment: Alignment.center,
                )),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {
          
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.leak_remove)))
          ],
        ));
  }
}

class _ThreadData {
  List<String> comments = [];
  PrimitiveWrapper<Offset>? threadPosition;

  _ThreadData(this.comments, this.threadPosition);
}

class _Thread {
  OverlayEntry? entry;
  _ThreadData? threadData;

  _Thread();

  factory _Thread.addNewThread(BuildContext context) {
    List<String> comments = [];
    var threadPosition = PrimitiveWrapper(const Offset(50, 50));
    OverlayEntry threadEntry = OverlayEntry(builder: (context) => _ThreadWidget(comments, threadPosition));
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(threadEntry));
    return _Thread()
      ..entry = threadEntry
      ..threadData = _ThreadData(comments, threadPosition);
  }

  rebuildThread(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(entry!));
  }
}

class _ThreadWidget extends StatefulWidget {
  final List<String> comments;
  final PrimitiveWrapper<Offset>? threadPosition;

  const _ThreadWidget(this.comments, this.threadPosition);

  @override
  State<StatefulWidget> createState() => _ThreadWidgetState();
}

class _ThreadWidgetState extends State<_ThreadWidget> {
  List<String>? comments;
  bool? isMinimized;
  PrimitiveWrapper<Offset>? threadPosition;

  @override
  void initState() {
    super.initState();
    comments = widget.comments;
    isMinimized = false;
    threadPosition = widget.threadPosition;
  }

  @override
  Widget build(BuildContext context) {
    return isMinimized == true ? minimizedThread() : commentThread(widget.comments);
  }

  Widget commentThread(List<String> previousComments) {
    return Positioned(
        left: threadPosition?.value.dx,
        top: threadPosition?.value.dy,
        child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                threadPosition?.value += details.delta;
              });
            },
            child: Material(
                elevation: 10,
                child: SizedBox(
                    width: 200,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                        child: Column(children: [
                          const TextField(
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.sentences,
                              key: Key("meal_description"),
                              keyboardType: TextInputType.multiline,
                              maxLines: 10,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Add comment',
                              )),
                          SizedBox(
                              height: 35,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isMinimized = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.minimize,
                                      color: Colors.blue,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Expanded(child: Container()),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.arrow_circle_right_outlined,
                                      color: Colors.blue,
                                    ),
                                    padding: EdgeInsets.zero,
                                  )
                                ],
                              ))
                        ]))))));
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
                    },
                    icon: const Icon(
                      Icons.line_axis,
                      color: Colors.blue,
                    )))));
  }
}

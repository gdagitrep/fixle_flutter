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
  int currentThreadIndex = 0;

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
                    if (threads.isNotEmpty) {
                      threads[currentThreadIndex].hideThread();
                    }
                    currentThreadIndex = threads.length;
                    threads.add(newThread);
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
                      if (threads.isNotEmpty) {
                        threads[currentThreadIndex].hideThread();
                        currentThreadIndex = (currentThreadIndex - 1) % threads.length;
                        threads[currentThreadIndex].rebuildThread(context);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_upward))),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(
                    onPressed: () {
                      if (threads.isNotEmpty) {
                        threads[currentThreadIndex].hideThread();
                        currentThreadIndex = (currentThreadIndex + 1) % threads.length;
                        threads[currentThreadIndex].rebuildThread(context);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.arrow_downward)))
          ],
        ));
  }

  displayAllThreads() {}
}

class _ThreadData {
  List<String> comments = [];
  PrimitiveWrapper<Offset>? threadPosition;

  _ThreadData(this.comments, this.threadPosition);
}

class _Thread {
  late OverlayEntry entry;
  late _ThreadData threadData;

  _Thread();

  factory _Thread.addNewThread(BuildContext context) {
    List<String> comments = [];
    var threadPosition = PrimitiveWrapper(const Offset(50, 50));
    var threadWidget = _ThreadWidget(comments, threadPosition);
    OverlayEntry threadEntry = OverlayEntry(builder: (context) => threadWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(threadEntry));
    return _Thread()
      ..entry = threadEntry
      ..threadData = _ThreadData(comments, threadPosition);
  }

  hideThread() {
    entry.remove();
  }

  rebuildThread(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => Overlay.of(context)?.insert(entry));
  }
}

class _ThreadWidget extends StatefulWidget {
  final List<String> comments;
  final PrimitiveWrapper<Offset>? threadPosition;

  _ThreadWidget(this.comments, this.threadPosition);

  @override
  State<StatefulWidget> createState() => _ThreadWidgetState();

  void minimizeExternal() {

  }
}

class _ThreadWidgetState extends State<_ThreadWidget> {
  late List<String> comments;
  bool? isMinimized;
  PrimitiveWrapper<Offset>? threadPosition;
  bool? isHidden;
  bool? placeIsLocked;
  final fieldText = TextEditingController();
  static final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    comments = widget.comments;
    isMinimized = false;
    isHidden = false;
    threadPosition = widget.threadPosition;
    placeIsLocked = false;
  }

  void minimizeExternal() {
    setState(() {
      isMinimized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isHidden == true) {
      return Container();
    }
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
                    },
                    icon: const Icon(
                      Icons.line_axis,
                      color: Colors.blue,
                    )))));
  }
}

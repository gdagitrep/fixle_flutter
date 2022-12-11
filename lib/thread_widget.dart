import 'package:fixle_feedback_flutter/primitive_wrapper.dart';
import 'package:fixle_feedback_flutter/thread_data.dart';
import 'package:flutter/material.dart';

class ThreadWidget extends StatefulWidget {
  final ThreadData threadData;
  late final void Function() threadMinimizingCallback;
  final void Function() makeFixleOverlayVisible;

  ThreadWidget(this.threadData, this.makeFixleOverlayVisible);

  @override
  State<StatefulWidget> createState() => _ThreadWidgetState();
}

class _ThreadWidgetState extends State<ThreadWidget> {
  late List<String> comments;
  PrimitiveWrapper<Offset>? threadPosition;
  bool? placeIsLocked;
  final fieldText = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    comments = widget.threadData.comments;
    threadPosition = widget.threadData.threadPosition;
    placeIsLocked = false;
  }

  @override
  Widget build(BuildContext context) {
    return commentThread(widget.threadData.comments);
  }

  Widget commentThread(List<String> previousComments) {
    Widget bottomBar() => SizedBox(
        height: 35,
        child: Row(
          children: [
            // if no comments, show cross button, or show minimize button
            IconButton(
              onPressed: () {
                widget.threadMinimizingCallback();
                widget.makeFixleOverlayVisible();
              },
              icon: Icon(
                comments.isEmpty ? Icons.close : Icons.minimize,
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
    for (var comment in comments) {
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
        widget.threadData.saveThreadData();
        setState(() {
          placeIsLocked = true;
        });
        // printThreadData(widget.threadData);
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
    return Container();
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
                        // isMinimized = false;
                      });
                      // widget.minimized.value = false;
                    },
                    icon: const Icon(
                      Icons.line_axis,
                      color: Colors.blue,
                    )))));
  }
}

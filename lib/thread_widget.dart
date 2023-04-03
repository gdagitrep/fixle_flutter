import 'package:fixle_feedback_flutter/primitive_wrapper.dart';
import 'package:fixle_feedback_flutter/project_and_threads_data.dart';
import 'package:flutter/material.dart';

class ThreadWidget extends StatefulWidget {
  final ThreadData threadData;
  late final void Function() threadMinimizingCallback;
  final void Function() makeFixleOverlayVisible;
  final String projectId;

  ThreadWidget(this.threadData, this.makeFixleOverlayVisible, this.projectId, {super.key});

  @override
  State<StatefulWidget> createState() => _ThreadWidgetState();
}

class _ThreadWidgetState extends State<ThreadWidget> {
  bool? placeIsLocked;
  final fieldText = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    placeIsLocked = false;
  }

  @override
  Widget build(BuildContext context) {
    return commentThread(widget.threadData.comments, widget.threadData.threadPosition);
  }

  Widget commentThread(List<Comment> previousComments, PrimitiveWrapper<Offset>? threadPosition) {
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
                previousComments.isEmpty ? Icons.close : Icons.minimize,
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
    for (var comment in previousComments) {
      children.add(Text(comment.commentText));
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
        previousComments.add(Comment()
          ..commentText = val!
          ..commentorEmail = "yetToFill");
        fieldText.clear();
        widget.threadData.saveThreadData(widget.projectId);
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

  Widget minimizedThreadAndShowCross() {
    return Container();
  //   return Positioned(
  //       left: 0,
  //       top: threadPosition?.value.dy,
  //       child: Material(
  //           elevation: 8,
  //           child: SizedBox(
  //               width: 50,
  //               child: IconButton(
  //                   onPressed: () {
  //                     setState(() {
  //                       // isMinimized = false;
  //                     });
  //                     // widget.minimized.value = false;
  //                   },
  //                   icon: const Icon(
  //                     Icons.line_axis,
  //                     color: Colors.blue,
  //                   )))));
  }
}

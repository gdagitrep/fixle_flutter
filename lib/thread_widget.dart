import 'package:fixle_feedback_flutter/primitive_wrapper.dart';
import 'package:fixle_feedback_flutter/project_and_threads_data.dart';
import 'package:flutter/material.dart';

class ThreadWidget extends StatefulWidget {
  final ThreadData threadData;
  late final void Function() threadMinimizingCallback;
  final void Function() makeFixleOverlayVisible;
  final String projectId;

  ThreadWidget(this.threadData, this.makeFixleOverlayVisible, this.projectId);

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
    return commentThread(
        widget.threadData.comments, widget.threadData.threadPosition);
  }

  Widget commentThread(List<Comment> previousComments,
      PrimitiveWrapper<Offset>? threadPosition) {
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
                color: Colors.pink,
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
      children.add(
        Text(
          comment.commentText,
        ),
      );
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Material(
            elevation: 10,
            child: Form(
              key: formKey,
              child: Container(
                padding: const EdgeInsets.all(6.0),
                width: 250.0,
                decoration: BoxDecoration(
                  color: Color(0xFFE7EEFB),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              widget.threadMinimizingCallback();
                              widget.makeFixleOverlayVisible();
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                previousComments.isEmpty
                                    ? Icons.close
                                    : Icons.minimize,
                                color: Color(0xFF2C384A),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final form = formKey.currentState!;
                              if (form.validate()) {
                                form.save();
                              }
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                Icons.arrow_circle_right_outlined,
                                color: Color(0xFF2C384A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: SizedBox(
                              height: 40.0,
                              width: 40.0,
                              child: Image.network(
                                "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            "OJ",
                            style: TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Text(
                        "This is the comment of the 2 line that should work perfectly...",
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFcfd7e2),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: TextFormField(
                          controller: fieldText,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          maxLines: 10,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Add comment',
                            border: InputBorder.none,
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
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

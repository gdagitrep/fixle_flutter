// library fixma_feedback_flutter;

import 'package:flutter/material.dart';


class CommentOverlay {
  OverlayEntry? entry;
  Offset? offset;

  CommentOverlay(this.entry, this.offset);
}

class Fixma {
  static final Fixma _instance = Fixma._internal();
  Fixma._internal();

  factory Fixma() {
    return _instance;
  }

  Offset offset = Offset(0, 200);
  OverlayEntry? entry;
  List<CommentOverlay>? comments;

  hideOverlay() {
    entry?.remove();
    entry = null;
  }

  showOverlay(BuildContext context) {
    if (entry == null) {
      entry = OverlayEntry(
          builder: (context) =>
              Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: GestureDetector(
                      onPanUpdate: (details) {
                        offset += details.delta;
                        entry!.markNeedsBuild();
                      },
                      child: gammaBar(context))
              ));
      var overlay = Overlay.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => overlay?.insert(entry!));
    }
  }

  Widget gammaBar(BuildContext context) {
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
                child: IconButton(onPressed: () {
                  addNewComment(context);
                }, icon: const Icon(Icons.add_comment),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  alignment: Alignment.center,)),
            SizedBox(
                height: 40.0,
                width: 30.0,
                child: IconButton(onPressed: () {},
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                    icon: const Icon(Icons.more_horiz))
            )
          ],
        ));
  }

  Widget commentThread() {
    return Material(
        elevation: 10,
        child: SizedBox(
            width: 200,
            child: Padding(
                padding:  const EdgeInsets.fromLTRB(5, 0, 10, 0),
                child: Column(

                    children : [
                      const TextField(
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        key: Key("meal_description"),
                        keyboardType: TextInputType.multiline,
                        maxLines: 10,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Add comment',
                        )
                    ),

                      SizedBox(
                          height: 35,
                          child:Row(

                            children: [
                              Expanded(child: Container()),
                              IconButton(onPressed: (){},
                                icon: const Icon(Icons.arrow_circle_right_outlined, color: Colors.blue,),
                                padding: EdgeInsets.zero,)
                            ],
                          ))
                    ]))));
  }

  void addNewComment(BuildContext context) {
    OverlayEntry? commentEntry;
    Offset commentOffset = Offset(50, 50);
    commentEntry = OverlayEntry(
        builder: (context) =>
            Positioned(
                left: commentOffset.dx,
                top: commentOffset.dy,
                child: GestureDetector(
                    onPanUpdate: (details) {
                      commentOffset += details.delta;
                      commentEntry!.markNeedsBuild();
                    },
                    child: commentThread())
            ));
    var overlay = Overlay.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => overlay?.insert(commentEntry!));
    if (comments == null) {
      comments = [CommentOverlay(commentEntry, commentOffset)];
    } else {
      comments?.add(CommentOverlay(commentEntry, commentOffset));
    }
  }
}
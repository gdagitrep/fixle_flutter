import 'dart:typed_data';

import 'package:fixma_feedback_flutter/network_utils.dart';
import 'package:fixma_feedback_flutter/primitive_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class ThreadData {
  late List<String> comments = [];
  late PrimitiveWrapper<Offset>? threadPosition;
  late Uint8List pngData;

// TODO read for an apiKey from api.
  static const String SAS_SUFFIX =
      "?sp=rw&st=2022-12-04T18:55:57Z&se=2030-12-05T02:55:57Z&spr=https&sv=2021-06-08&sr=c&sig=pMoZZxksl%2BDdg4rguIJSp6yrCrAFmUo1k6E2PybxEQ0%3D";
  static final String API_KEY = '1234';

  late String _imageNameWithoutContainer;
  late String _threadId;

  ThreadData();

  factory ThreadData.fromNewThread(List<String> comments, PrimitiveWrapper<Offset> threadPosition, Uint8List pngData) {
    String seed = DateTime.now().toString();
    var randomString = const Uuid().v5(Uuid.NAMESPACE_NIL, seed);
    return ThreadData()
      .._imageNameWithoutContainer = randomString
      ..comments = comments
      ..threadPosition = threadPosition
      ..pngData = pngData;
  }

  saveThreadData() {
    if (comments.isEmpty) {
      return;
    } else if (comments.length == 1) {
      var futures = <Future>[
        NetworkRequestUtilsFixma.putToBlobStorage(_imageNameWithoutContainer, SAS_SUFFIX, pngData),
        NetworkRequestUtilsFixma.addThreadDataToApi(this, API_KEY).then((value) {
          if (value != null) _threadId = value;
        })
      ];
      Future.wait(futures);
    } else if (comments.length > 1) {
      // edit the thread
      NetworkRequestUtilsFixma.editThreadDataToApi(this, _threadId, API_KEY);
    }
  }

  NetworkImage getNetworkImage() {
    return NetworkRequestUtilsFixma.getNetworkImage(_imageNameWithoutContainer);
  }

  Map<String, dynamic> toJson(String apiKey) => <String, dynamic>{
        'Image': _imageNameWithoutContainer,
        'Comments': comments,
        'Offset': threadPosition != null
            ? {
                "dx": threadPosition?.value.dx,
                "dy": threadPosition?.value.dy,
              }
            : null,
        'ApiKey': apiKey,
      };

  static Future<ThreadData> fromJson(Map<String, dynamic> json) async {
    var imageNameWithoutContainer = json['Image'] as String;
    Map<String, dynamic> position = json['Offset'];
    var threadPosition = Offset(position['dx'], position['dy']);
    var pngData = await NetworkRequestUtilsFixma.getImage(imageNameWithoutContainer);
    return ThreadData()
      ..pngData = pngData
      .._imageNameWithoutContainer = imageNameWithoutContainer
      ..threadPosition = PrimitiveWrapper(threadPosition)
      ..comments = (json['comments'] as List).map((e) => e as String).toList();
  }
}

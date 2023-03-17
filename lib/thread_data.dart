import 'dart:typed_data';

import 'package:fixle_feedback_flutter/network_utils.dart';
import 'package:fixle_feedback_flutter/primitive_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

class ProjectThreads {
  List<ThreadData>? threads;
  static Logger logger = Logger();

  List<ProjectUser>? adminAndCollaborators;

  static Future<ProjectThreads> fromJson(Map<String, dynamic> json) async {
    List<Future<ThreadData>> futures = [];
    for (var thread in json['threads']) {
      futures.add(ThreadData.fromJson(thread));
    }
    var result = await Future.wait(futures);
    logger.d("successfully obtained all threads");

    return Future.value(ProjectThreads()
      ..adminAndCollaborators =
          (json['adminAndCollaborators'] as List).map((projectUser) => ProjectUser.fromJson(projectUser)).toList()
      ..threads = result);
  }
}

class ProjectUser {
  String? fullName;

  String? email;

  static ProjectUser fromJson(Map<String, dynamic> json) {
    return ProjectUser()
      ..fullName = json["fullName"]
      ..email = json["email"];
  }
}

class ThreadData {
  late List<Comment> comments = [];
  late PrimitiveWrapper<Offset>? threadPosition;
  late Uint8List pngData;

// TODO read for an apiKey from api.
  static const String BLOB_PUT_SAS_SUFFIX =
      "?sp=rw&st=2022-12-04T18:55:57Z&se=2030-12-05T02:55:57Z&spr=https&sv=2021-06-08&sr=c&sig=pMoZZxksl%2BDdg4rguIJSp6yrCrAFmUo1k6E2PybxEQ0%3D";

  late String _imageNameWithoutContainer;
  late String _threadId;

  ThreadData();

  factory ThreadData.fromNewThread(List<Comment> comments, PrimitiveWrapper<Offset> threadPosition, Uint8List pngData) {
    String seed = DateTime.now().toString();
    var randomString = const Uuid().v5(Uuid.NAMESPACE_NIL, seed);
    return ThreadData()
      .._imageNameWithoutContainer = randomString
      ..comments = comments
      ..threadPosition = threadPosition
      ..pngData = pngData;
  }

  saveThreadData(String projectId) {
    if (comments.isEmpty) {
      return;
    } else if (comments.length == 1) {
      var futures = <Future>[
        NetworkRequestUtilsFixle.putToBlobStorage(_imageNameWithoutContainer, BLOB_PUT_SAS_SUFFIX, pngData),
        NetworkRequestUtilsFixle.addThreadDataToApi(this, projectId).then((value) {
          if (value != null) _threadId = value;
        })
      ];
      Future.wait(futures);
    } else if (comments.length > 1) {
      // edit the thread
      NetworkRequestUtilsFixle.editThreadDataToApi(this, _threadId, projectId);
    }
  }

  NetworkImage getNetworkImage() {
    return NetworkRequestUtilsFixle.getNetworkImage(_imageNameWithoutContainer);
  }

  Map<String, dynamic> toJson(String apiKey) => <String, dynamic>{
        'Image': _imageNameWithoutContainer,
        'Comments': comments.map((comment) => comment.toJson()).toList(),
        'Offset': threadPosition != null
            ? {
                "dx": threadPosition?.value.dx,
                "dy": threadPosition?.value.dy,
              }
            : null,
        'ProjectId': apiKey,
      };

  static Future<ThreadData> fromJson(Map<String, dynamic> json) async {
    var imageNameWithoutContainer = json['image'] as String;
    Map<String, dynamic> position = json['offset'];
    var threadPosition = Offset((position['dx']).toDouble(), (position['dy']).toDouble());
    var pngData = await NetworkRequestUtilsFixle.getImage(imageNameWithoutContainer);
    return ThreadData()
      ..pngData = pngData
      .._threadId = json['id']
      .._imageNameWithoutContainer = imageNameWithoutContainer
      ..threadPosition = PrimitiveWrapper(threadPosition)
      ..comments = (json['comments'] as List).map((e) => Comment.fromJson(e)).toList();
  }
}

class Comment {
  late String commentText;
  late String commentorEmail;

  Map<String, dynamic> toJson() {
    return <String, dynamic> {
      'CommentText': commentText,
      'CommentorEmail': commentorEmail
    };
  }

  Comment();

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment()
      ..commentorEmail = json["commentorEmail"]
      ..commentText = json["commentText"];
  }
}

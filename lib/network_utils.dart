import 'dart:io';
import 'dart:typed_data';
import 'package:dart_utils/network_core.dart';
import 'package:dio/dio.dart';
import 'package:fixma_feedback_flutter/thread_data.dart';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class NetworkRequestUtilsFixma {
  static const String AZ_BLOB_STORAGE_URL = "https://mealblobstorage.blob.core.windows.net/";
  static const String BLOB_CDN_URL = "https://dsqcdn.azureedge.net/threadimages/";
  static const String _THREAD_ADD_URL = "https://kadamapi.azurewebsites.net/thread/addThread";
  static const String _THREAD_edit_URL = "https://kadamapi.azurewebsites.net/thread/editThread?threadId=";
  static const String _THREADS_GET_URL = "https://kadamapi.azurewebsites.net/thread/getThreads?apiKey=";
  static Logger logger = Logger();

  static Future<bool> putToBlobStorage(String imageWithoutContainerName, String sasSuffix, Uint8List postData) async {
    try {
      String url = BLOB_CDN_URL + imageWithoutContainerName + sasSuffix;
      await Dioo.put(url,
          data: Stream.fromIterable(
            postData.map((e) => [e]),
          ),
          options: Options(
            headers: {
              HttpHeaders.contentLengthHeader: postData.length,
              "x-ms-blob-type": "BlockBlob",
            },
          ),
          trackTelemetry: false);
      logger.d('Posted image successfully imageName: $imageWithoutContainerName');
      return true;
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {
        // Utils.inform(context, 'No permission to post image');
      } else {
        // Utils.inform(context, 'Error happened while uploading image');
      }
      logger.d('Upload of blob failed${e.response}');
      return false;
    }
  }

  static NetworkImage getNetworkImage(String imageNameWithoutContainer) {
    return NetworkImage(BLOB_CDN_URL + imageNameWithoutContainer);
  }

  static Future<Uint8List> getImage(String imageNameWithoutContainer) async {
    var response = await Dioo.get(BLOB_CDN_URL + imageNameWithoutContainer);
    return response.data;
  }

  static Future<String?> addThreadDataToApi(ThreadData threadData, String apiKey) async {
    try {
      String url = _THREAD_ADD_URL;
      var postData = threadData.toJson(apiKey);
      var response = await Dioo.post(
        url,
        data: postData,
        // propertiesToLog: {"email": userDetails.email!},
        options: Options(
          headers: {HttpHeaders.contentTypeHeader: "application/json"},
        ),
      );
      logger.d("successfully added thread");
      return response.data;
      // Utils.inform(context, 'Posted meal successfully');
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {
        // Utils.inform(context, 'No permission to post meal');
      } else {
        // Utils.inform(context, 'Error happened while posting meal');
      }
      logger.d(e);
    }
    return null;
  }

  static Future<bool> editThreadDataToApi(ThreadData threadData, String threadId, String apiKey) async {
    try {
      String url = _THREAD_edit_URL + threadId;
      var postData = threadData.toJson(apiKey);
      await Dioo.put(
        url,
        data: postData,
        options: Options(
          headers: {HttpHeaders.contentTypeHeader: "application/json"},
        ),
      );
      logger.d("successfully updated thread");
      // Utils.inform(context, 'Posted meal successfully');
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {
        // Utils.inform(context, 'No permission to post meal');
      } else {
        // Utils.inform(context, 'Error happened while posting meal');
      }
      logger.d(e);
      return false;
    }

    return true;
  }

  static Future<List<ThreadData>> getAllThreads(String apiKey) async {
    var response = await Dioo.get(_THREADS_GET_URL + apiKey);
    List<ThreadData> castedMeals = response.data.map((thread) => ThreadData.fromJson(thread)).toList();
    return castedMeals;
  }
}

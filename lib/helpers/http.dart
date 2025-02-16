import 'dart:io';

import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';


enum GetUriKeys {
  groupHasGuests("/groups/{}/has_guests"),
  groupCurrent("/groups/{}"),
  groupMember("/groups/{}/member"),
  groups("/groups"),
  userBalanceSum("/balance"),
  passwordReminder("/password_reminder"),
  groupBoost("/groups/{}/boost"),
  groupGuests("/groups/{}/guests"),
  groupUnapprovedMembers("/groups/{}/members/unapproved"),
  groupExportXls("/groups/{}/export/get_link_xls"),
  groupExportPdf("/groups/{}/export/get_link_pdf"),
  purchases("/purchases"),
  payments("/payments"),
  statisticsPayments("/groups/{}/statistics/payments"),
  statisticsPurchases("/groups/{}/statistics/purchases"),
  statisticsAll("/groups/{}/statistics/all"),
  requests("/requests"),
  groupFromToken("/groups/from-invitation/{}");

  const GetUriKeys(this.uri);
  final String uri;
}

enum HttpType { get, post, put, delete }

///Generates URI-s from enum values. The default value of [params] is [currentGroupId].
String generateUri(
  GetUriKeys key,
  BuildContext context, {
  HttpType type = HttpType.get,
  List<String>? params,
  Map<String, String?>? queryParams,
}) {
  if (type == HttpType.get) {
    Group? currentGroup = context.read<UserState>().group;
    if (params == null && currentGroup != null) {
      params = [currentGroup.id.toString()];
    }
    params ??= [];
    String uri = key.uri;

    for (String arg in params) {
      if (uri.contains('{}')) {
        uri = uri.replaceFirst('{}', arg);
      } else {
        break;
      }
    }

    if (queryParams != null) {
      if (queryParams.values.any((element) => element != null)) {
        uri += '?';
      }
      for (String name in queryParams.keys) {
        uri += name + '=' + (queryParams[name] ?? '') + '&';
      }
    }
    return uri;
  }
  return '';
}

class Http {
  static Future<http.Response> get({
    required String uri,
    bool overwriteCache = false,
    bool useCache = true,
  }) async {
    throw 'cannot_connect';
  }

  static Future<http.Response> post({
    required String uri,
    Map<String, dynamic>? body,
  }) async {
    throw 'cannot_connect';
  }

  static Future<http.Response> put({
    required String uri,
    Map<String, dynamic>? body,
  }) async {
     throw 'cannot_connect';
  }

  static Future<http.Response> delete({required String uri}) async {
    throw 'cannot_connect';
  }
}

Widget errorToast(String msg, BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: Theme.of(context).colorScheme.error,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.clear,
          color: Theme.of(context).colorScheme.onError,
        ),
        SizedBox(
          width: 12.0,
        ),
        Flexible(
            child: Text(msg.tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.onError))),
      ],
    ),
  );
}

Future<Directory> _getCacheDir() async {
  String delimiter = Platform.isWindows ? '\\' : '/';
  return Directory((await getTemporaryDirectory()).path + delimiter + 'lender');
}

Future<http.Response?> fromCache(
    {required String uri,
    required bool overwriteCache,
    bool alwaysReturnCache = false}) async {
  try {
    String s = Platform.isWindows ? '\\' : '/';
    String fileName =
        uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
    var cacheDir = await _getCacheDir();
    if (!cacheDir.existsSync()) {
      return null;
    }
    File file = File(cacheDir.path + s + fileName);
    if (file.existsSync() && (alwaysReturnCache ||
        (!overwriteCache &&
            DateTime.now().difference(await file.lastModified()).inMinutes <
                    5))) {
      return http.Response(await file.readAsString(), 200);
    }
    // print('from API');
    return null;
  } catch (e) {
    //TODO: this is wrong, shouldn't be this way
    print(e.toString());
    return null;
  }
}

Future toCache({required String uri, required http.Response response}) async {
  // print('to cache');
  String s = Platform.isWindows ? '\\' : '/';
  String fileName =
      uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
  var cacheDir = await _getCacheDir();
  //print('itt');
  cacheDir.create();
  File file = File(cacheDir.path + s + fileName);
  file.writeAsString(response.body, flush: true, mode: FileMode.write);
}

///Deletes file at the given [uri] from the cache directory.
///The [multipleArgs] bool is used for [uri]-s where not all of the [args]
///are known at the time of the removal. (See [generateUri] function)
///In this case the [uri] becomes a search word
Future deleteCache({required String uri, bool multipleArgs = false}) async {
  if (!kIsWeb) {
    uri = uri.substring(1);
    String fileName =
        uri.replaceAll('/', '-').replaceAll('&', '-').replaceAll('?', '-');
    String separator = Platform.isWindows ? '\\' : '/';
    var cacheDir = await _getCacheDir();
    if (multipleArgs) {
      if (cacheDir.existsSync()) {
        List<FileSystemEntity> files = cacheDir.listSync();
        for (var file in files) {
          if (file is File) {
            String fileName = file.path.split(separator).last;
            if (fileName.contains(uri) && file.existsSync()) {
              file.deleteSync();
            }
          }
        }
      }
    } else {
      File file = File(cacheDir.path + separator + fileName);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}

Future clearGroupCache(BuildContext context) async {
  //
}

Future clearAllCache() async {
  if (!kIsWeb) {
    // print('all cache');
    var cacheDir = await _getCacheDir();
    if (cacheDir.existsSync()) {
      for (FileSystemEntity file in cacheDir.listSync()) {
        if (file is File) {
          file.deleteSync();
        }
      }
    }
  }
}

Duration delayTime() {
  return Duration(milliseconds: 700);
}

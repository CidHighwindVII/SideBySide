import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../engine/models.dart';
import '../log.dart';

/// Single JSON file via path_provider (locked in spec §8).
class Store {
  File? _file;

  Future<File> get file async {
    if (_file == null) {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}${Platform.pathSeparator}sidebyside.json');
    }
    return _file!;
  }

  Future<AppData> load() async {
    try {
      final f = await file;
      if (!await f.exists()) return const AppData();
      return AppData.fromJson(jsonDecode(await f.readAsString()));
    } catch (e, s) {
      logWarn('store', 'load failed, starting empty');
      logErr('store', e, s);
      return const AppData();
    }
  }

  Future<void> save(AppData data) async {
    final f = await file;
    // v0.2.0 (#2): temp+rename — a crash mid-write can't corrupt the only copy.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(f.path);
  }

  Future<void> wipe() async {
    final f = await file;
    if (await f.exists()) await f.delete();
  }
}

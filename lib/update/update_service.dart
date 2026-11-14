import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 应用内更新服务：
/// 1. 检查 GitHub 最新 Release 的版本号；
/// 2. 下载对应 CPU 架构的 APK（带进度）；
/// 3. 通过平台通道拉起系统安装器。
///
/// 仓库固定为本项目开源仓库；手表设备默认下载 arm64 包。
class UpdateService {
  UpdateService._() {
    _initVersion();
  }

  static final UpdateService instance = UpdateService._();

  static const MethodChannel _channel = MethodChannel('m3e_mail/update');

  static const String _repoApi =
      'https://api.github.com/repos/lliiaannggyu/m3e-mail-wearos/releases/latest';

  /// 手表真机以 arm64 为主，优先下载 arm64 分包。
  static const String _archPattern = 'arm64';

  String? currentVersion;
  String? latestVersion;
  String? apkUrl;
  int apkSize = 0;

  final ValueNotifier<UpdateState> state =
      ValueNotifier<UpdateState>(const UpdateState.idle());

  late final Future<void> _versionReady = _initVersion();

  Future<void> _initVersion() async {
    try {
      currentVersion = await _channel.invokeMethod<String>('appVersion');
    } catch (_) {
      // 平台通道在测试环境/异常情况下不可用，退回 pubspec 声明的版本
      currentVersion = null;
    }
  }

  /// 检查最新版本。结果通过 [state] 与返回值同时给出。
  Future<UpdateState> check() async {
    await _versionReady; // 确保 currentVersion 已就绪再比较
    state.value = const UpdateState.checking();
    try {
      final HttpClientRequest req =
          await HttpClient().getUrl(Uri.parse(_repoApi));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final HttpClientResponse res = await req.close().timeout(
            const Duration(seconds: 15),
          );
      if (res.statusCode != 200) {
        throw Exception('GitHub 响应 ${res.statusCode}');
      }
      final Map<String, dynamic> body =
          jsonDecode(await res.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      latestVersion = (body['tag_name'] as String?)?.replaceFirst('v', '');
      final List<dynamic> assets = body['assets'] as List<dynamic>? ?? <dynamic>[];
      for (final a in assets) {
        final name = (a['name'] as String).toLowerCase();
        if (name.endsWith('.apk') && name.contains(_archPattern)) {
          apkUrl = a['browser_download_url'] as String;
          apkSize = a['size'] as int? ?? 0;
          break;
        }
      }
      if (apkUrl == null) {
        throw Exception('Release 中没有 arm64 APK');
      }
      final bool newer = isNewer(latestVersion ?? '', currentVersion ?? '');
      final UpdateState r = newer
          ? UpdateState.available(latestVersion!, apkSize)
          : const UpdateState.upToDate();
      state.value = r;
      return r;
    } catch (e) {
      final UpdateState r = UpdateState.error(e.toString());
      state.value = r;
      return r;
    }
  }

  /// 下载 APK 到应用缓存目录，进度写入 [state]。
  Future<UpdateState> download() async {
    if (apkUrl == null) return await check();
    state.value = const UpdateState.downloading(0);
    try {
      final String dir = await _cacheDir();
      final Directory apkDir = Directory('$dir/apk');
      if (!apkDir.existsSync()) apkDir.createSync(recursive: true);
      final File file = File('${apkDir.path}/m3e-mail-update.apk');
      if (file.existsSync()) file.deleteSync();

      final HttpClientRequest req =
          await HttpClient().getUrl(Uri.parse(apkUrl!));
      final HttpClientResponse res = await req.close().timeout(
            const Duration(seconds: 20),
          );
      if (res.statusCode != 200) {
        throw Exception('下载响应 ${res.statusCode}');
      }
      final int total =
          res.contentLength > 0 ? res.contentLength : (apkSize > 0 ? apkSize : 1);
      final IOSink sink = file.openWrite();
      int received = 0;
      int lastPct = -1;
      await for (final List<int> chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        final int pct = (received * 100 ~/ total).clamp(0, 100);
        if (pct != lastPct) {
          lastPct = pct;
          state.value = UpdateState.downloading(pct / 100);
        }
      }
      await sink.flush();
      await sink.close();
      state.value = UpdateState.ready(file.path);
      return state.value;
    } catch (e) {
      final UpdateState r = UpdateState.error(e.toString());
      state.value = r;
      return r;
    }
  }

  /// 确保有「安装未知来源应用」权限；没有则跳转系统设置页。
  Future<bool> ensureInstallPermission() async {
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestInstallPermission() async {
    try {
      await _channel.invokeMethod<void>('requestInstallPermission');
    } catch (_) {
      // 忽略：部分系统无此设置页
    }
  }

  /// 拉起系统安装器安装已下载的 APK。
  Future<void> install(String path) async {
    await _channel.invokeMethod<void>('installApk', <String, dynamic>{
      'path': path,
    });
  }

  Future<String> _cacheDir() async {
    return await _channel.invokeMethod<String>('cacheDir') ??
        Directory.systemTemp.path;
  }

  /// 语义化版本比较：latest 是否比 current 新。
  /// 只取数字段（忽略 v 前缀与后缀），如 1.2.0 vs 1.2.10。
  static bool isNewer(String latest, String current) {
    final List<int> a = _segments(latest);
    final List<int> b = _segments(current);
    if (a.isEmpty || b.isEmpty) return false;
    for (var i = 0; i < 3; i++) {
      final int x = i < a.length ? a[i] : 0;
      final int y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static List<int> _segments(String v) {
    final m =
        RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(v.trim().replaceFirst('v', ''));
    if (m == null) return <int>[];
    return <int>[int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!)];
  }
}

/// 更新流程的状态。
class UpdateState {
  const UpdateState._(
    this.kind, {
    this.progress = 0,
    this.latestVersion,
    this.latestSize = 0,
    this.apkPath,
    this.error,
  });

  const UpdateState.idle() : this._(UpdateStateKind.idle);

  const UpdateState.checking() : this._(UpdateStateKind.checking);

  factory UpdateState.available(String version, int size) =>
      UpdateState._(UpdateStateKind.available,
          latestVersion: version, latestSize: size);

  const UpdateState.upToDate() : this._(UpdateStateKind.upToDate);

  const UpdateState.downloading(double p)
      : this._(UpdateStateKind.downloading, progress: p);

  const UpdateState.ready(String path)
      : this._(UpdateStateKind.ready, apkPath: path);

  factory UpdateState.error(String message) =>
      UpdateState._(UpdateStateKind.error, error: message);

  final UpdateStateKind kind;
  final double progress;
  final String? latestVersion;
  final int latestSize;
  final String? apkPath;
  final String? error;
}

enum UpdateStateKind { idle, checking, available, upToDate, downloading, ready, error }

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/storage/local_db_service.dart';
import '../../data/sample_game.dart';

/// Holds the latest AI-generated game HTML for sharing between pages.
final pendingGameHtmlProvider = StateProvider<String?>((ref) => null);

class PreviewState {
  final String htmlCode;
  final bool isFullscreen;
  final int selectedTab;
  final bool isLoading;
  final bool isOffline;
  final bool isInitialized;

  const PreviewState({
    this.htmlCode = sampleGameHtml,
    this.isFullscreen = false,
    this.selectedTab = 0,
    this.isLoading = false,
    this.isOffline = false,
    this.isInitialized = false,
  });

  PreviewState copyWith({
    String? htmlCode,
    bool? isFullscreen,
    int? selectedTab,
    bool? isLoading,
    bool? isOffline,
    bool? isInitialized,
  }) =>
      PreviewState(
        htmlCode: htmlCode ?? this.htmlCode,
        isFullscreen: isFullscreen ?? this.isFullscreen,
        selectedTab: selectedTab ?? this.selectedTab,
        isLoading: isLoading ?? this.isLoading,
        isOffline: isOffline ?? this.isOffline,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

class PreviewNotifier extends StateNotifier<PreviewState> {
  PreviewNotifier(this.projectId, this._ref) : super(PreviewState()) {
    Future(() {
      _init();
      _initCompleted = true;
    });
  }

  final String projectId;
  final Ref _ref;
  final LocalDbService _localDb = LocalDbService();
  bool _initCompleted = false;

  /// Path to the HTML file for WebView file-based loading.
  String? htmlFilePath;

  Future<void> _init() async {
    // Check pending HTML first (freshly generated from workspace)
    final pending = _ref.read(pendingGameHtmlProvider);
    if (pending != null) {
      _ref.read(pendingGameHtmlProvider.notifier).state = null;
      await _writeHtmlFile(pending);
      state = state.copyWith(htmlCode: pending, isInitialized: true);
      return;
    }

    // Fall back to local DB cache
    final online = await _localDb.isOnline;
    final localBuild = await _localDb.getLatestLocalBuild(projectId);
    if (localBuild != null) {
      await _writeHtmlFile(localBuild);
      state = state.copyWith(
        htmlCode: localBuild,
        isOffline: !online,
        isInitialized: true,
      );
    } else {
      await _writeHtmlFile(sampleGameHtml);
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Writes the HTML to a temp file for reliable WebView loading
  /// (avoids iOS data: URL size limits).
  Future<void> _writeHtmlFile(String html) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/game_preview_$projectId.html');
      await file.writeAsString(html);
      htmlFilePath = file.path;
    } catch (_) {
      htmlFilePath = null;
    }
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  /// Consumes a pending game HTML from [pendingGameHtmlProvider] if one
  /// exists, bypassing DB/cache fallback. Safe to call multiple times;
  /// no-op if the provider is null.
  ///
  /// Called from the page's [initState] to handle the case where the
  /// notifier is reused (same projectId, second navigation) after a
  /// fresh generation in the workspace.  On the first visit [_init] is
  /// responsible for consuming the pending HTML, so this is a no-op
  /// until [_initCompleted] is true.
  void consumePending() {
    if (!_initCompleted) return;
    final pending = _ref.read(pendingGameHtmlProvider);
    if (pending != null) {
      _ref.read(pendingGameHtmlProvider.notifier).state = null;
      _updateCodeInternal(pending, clearFilePath: true);
    }
  }

  void updateCode(String code) {
    _updateCodeInternal(code, clearFilePath: false);
  }

  void _updateCodeInternal(String code, {required bool clearFilePath}) {
    _writeHtmlFile(code);
    if (clearFilePath) htmlFilePath = null;
    state = state.copyWith(htmlCode: code);
  }

  Future<void> shareCode() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/game_$projectId.html');
      await file.writeAsString(state.htmlCode);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'GameForger - 我的游戏',
      );
    } catch (_) {
      // sharing failed silently
    }
  }
}

final previewProvider =
    StateNotifierProvider.family<PreviewNotifier, PreviewState, String>(
  (ref, projectId) => PreviewNotifier(projectId, ref),
);

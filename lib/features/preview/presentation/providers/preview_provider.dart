import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/storage/local_db_service.dart';
import '../../../../services/supabase/game_build_service.dart';
import '../../../../services/supabase/supabase_client.dart';
import '../../../../services/ai/model_router.dart';
import '../../data/sample_game.dart';
import '../../../../services/ai/preview_agent_service.dart';
import '../../../workspace/presentation/providers/workspace_provider.dart';

/// Holds the latest AI-generated game HTML for sharing between pages,
/// scoped by projectId so that generating project A never leaks into
/// a preview opened for project B.
final pendingGameHtmlProvider = StateProvider.family<String?, String>(
  (ref, projectId) => null,
);

/// Agent state machine for the preview chat.
enum AgentState {
  /// Waiting for user input.
  idle,

  /// AI is generating a response (streaming).
  thinking,

  /// AI has finished, edits are pending user review.
  reviewing,

  /// Edits are being applied to the HTML.
  applying,

  /// An error occurred.
  error,
}

class PreviewChatMessage {
  final String id;
  final bool isUser;
  final String content;
  final bool isStreaming;
  final String? modelLabel;

  const PreviewChatMessage({
    required this.id,
    required this.isUser,
    required this.content,
    this.isStreaming = false,
    this.modelLabel,
  });

  PreviewChatMessage copyWith({
    String? content,
    bool? isStreaming,
    String? modelLabel,
  }) => PreviewChatMessage(
    id: id,
    isUser: isUser,
    content: content ?? this.content,
    isStreaming: isStreaming ?? this.isStreaming,
    modelLabel: modelLabel ?? this.modelLabel,
  );
}

/// A proposed code edit shown in the diff review panel.
class PreviewEditProposal {
  final String id;
  final String oldCode;
  final String newCode;
  final bool isAccepted;
  final bool isRejected;
  final bool isApplied;
  final String? applyError;

  const PreviewEditProposal({
    required this.id,
    required this.oldCode,
    required this.newCode,
    this.isAccepted = false,
    this.isRejected = false,
    this.isApplied = false,
    this.applyError,
  });

  PreviewEditProposal copyWith({
    bool? isAccepted,
    bool? isRejected,
    bool? isApplied,
    String? applyError,
  }) => PreviewEditProposal(
    id: id,
    oldCode: oldCode,
    newCode: newCode,
    isAccepted: isAccepted ?? this.isAccepted,
    isRejected: isRejected ?? this.isRejected,
    isApplied: isApplied ?? this.isApplied,
    applyError: applyError ?? this.applyError,
  );
}

class PreviewState {
  final String htmlCode;
  final bool isFullscreen;
  final int selectedTab;
  final bool isLoading;
  final bool isOffline;
  final bool isInitialized;
  final List<PreviewChatMessage> chatMessages;
  final bool isChatLoading;

  // Agent state
  final AgentState agentState;
  final List<PreviewEditProposal> pendingEdits;
  final String? agentErrorMessage;

  const PreviewState({
    this.htmlCode = sampleGameHtml,
    this.isFullscreen = false,
    this.selectedTab = 0,
    this.isLoading = false,
    this.isOffline = false,
    this.isInitialized = false,
    this.chatMessages = const [],
    this.isChatLoading = false,
    this.agentState = AgentState.idle,
    this.pendingEdits = const [],
    this.agentErrorMessage,
  });

  PreviewState copyWith({
    String? htmlCode,
    bool? isFullscreen,
    int? selectedTab,
    bool? isLoading,
    bool? isOffline,
    bool? isInitialized,
    List<PreviewChatMessage>? chatMessages,
    bool? isChatLoading,
    AgentState? agentState,
    List<PreviewEditProposal>? pendingEdits,
    String? agentErrorMessage,
  }) => PreviewState(
    htmlCode: htmlCode ?? this.htmlCode,
    isFullscreen: isFullscreen ?? this.isFullscreen,
    selectedTab: selectedTab ?? this.selectedTab,
    isLoading: isLoading ?? this.isLoading,
    isOffline: isOffline ?? this.isOffline,
    isInitialized: isInitialized ?? this.isInitialized,
    chatMessages: chatMessages ?? this.chatMessages,
    isChatLoading: isChatLoading ?? this.isChatLoading,
    agentState: agentState ?? this.agentState,
    pendingEdits: pendingEdits ?? this.pendingEdits,
    agentErrorMessage: agentErrorMessage ?? this.agentErrorMessage,
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
  final PreviewAgentService _agentService = PreviewAgentService();
  bool _initCompleted = false;

  /// Path to the HTML file for WebView file-based loading.
  String? htmlFilePath;

  Future<void> _init() async {
    try {
      // Check pending HTML first (freshly generated from workspace),
      // scoped to this project so cross-project pollution is impossible.
      final pending = _ref.read(pendingGameHtmlProvider(projectId));
      if (pending != null) {
        _ref.read(pendingGameHtmlProvider(projectId).notifier).state = null;
        await _writeHtmlFile(pending);
        state = state.copyWith(htmlCode: pending, isInitialized: true);
        return;
      }

      // Fall back to local DB cache
      final online = await _localDb.isOnline;
      final localBuild = await _localDb.getLatestLocalBuild(projectId);
      if (localBuild != null && localBuild.isNotEmpty) {
        await _writeHtmlFile(localBuild);
        state = state.copyWith(
          htmlCode: localBuild,
          isOffline: !online,
          isInitialized: true,
        );
      } else {
        final remoteBuild = await _getLatestRemoteBuild();
        if (remoteBuild != null && remoteBuild.htmlCode.isNotEmpty) {
          await _localDb.cacheBuild(
            projectId,
            remoteBuild.htmlCode,
            remoteBuild.specSnapshot,
          );
          await _writeHtmlFile(remoteBuild.htmlCode);
          state = state.copyWith(
            htmlCode: remoteBuild.htmlCode,
            isOffline: !online,
            isInitialized: true,
          );
        } else {
          await _writeHtmlFile(sampleGameHtml);
          state = state.copyWith(isInitialized: true);
        }
      }
    } catch (_) {
      // If anything fails (DB, connectivity, file I/O), fall back to the
      // sample game so the user isn't stuck on a loading spinner forever.
      await _writeHtmlFile(sampleGameHtml);
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<GameBuildModel?> _getLatestRemoteBuild() async {
    try {
      return GameBuildService(SupabaseManager.client).getLatestBuild(projectId);
    } catch (_) {
      return null;
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
    if (state.selectedTab == index) return;
    state = state.copyWith(selectedTab: index);
  }

  /// Consumes a pending game HTML from [pendingGameHtmlProvider] if one
  /// exists, bypassing DB/cache fallback. Safe to call multiple times;
  /// no-op if the provider is null.
  void consumePending() {
    if (!_initCompleted) return;
    final pending = _ref.read(pendingGameHtmlProvider(projectId));
    if (pending != null) {
      _ref.read(pendingGameHtmlProvider(projectId).notifier).state = null;
      _updateCodeInternal(pending, clearFilePath: true);
    }
  }

  void updateCode(String code) {
    _updateCodeInternal(code, clearFilePath: false);
  }

  Future<void> updateCodeAndPersist(String code) async {
    _updateCodeInternal(code, clearFilePath: false);
    final spec = _ref.read(workspaceProvider(projectId)).gameSpec;
    await _localDb.cacheBuild(projectId, code, spec);
    try {
      await GameBuildService(
        SupabaseManager.client,
      ).saveBuild(projectId, code, spec);
    } catch (_) {
      // Local cache is the source of truth for immediate reloads; Supabase can
      // fail offline or due to auth/network without blocking the preview.
    }
  }

  void _updateCodeInternal(String code, {required bool clearFilePath}) {
    _writeHtmlFile(code);
    if (clearFilePath) htmlFilePath = null;
    state = state.copyWith(htmlCode: code);
  }

  Future<void> shareCode() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/game_$projectId.html');
    await file.writeAsString(state.htmlCode);
    await Share.shareXFiles([XFile(file.path)], subject: 'GameForger - 我的游戏');
  }

  // ─── Agent-powered Preview Chat ──────────────────────────────────────

  /// Send a user message to the AI agent for code modification.
  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.agentState != AgentState.idle) return;

    final id = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    final modelLabel = await _currentCodeModelLabel();
    final userMsg = PreviewChatMessage(
      id: '${id}_user',
      isUser: true,
      content: text.trim(),
    );
    final aiId = '${id}_ai';
    final aiMsg = PreviewChatMessage(
      id: aiId,
      isUser: false,
      content: '',
      isStreaming: true,
      modelLabel: modelLabel,
    );

    state = state.copyWith(
      chatMessages: [...state.chatMessages, userMsg, aiMsg],
      agentState: AgentState.thinking,
      pendingEdits: [],
      agentErrorMessage: null,
    );

    try {
      final history = state.chatMessages
          .where((m) => !m.isStreaming && m.content.isNotEmpty)
          .map(
            (m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList();

      final workspaceState = _ref.read(workspaceProvider(projectId));

      final result = await _agentService.processModificationStream(
        currentHtml: state.htmlCode,
        gameSpec: workspaceState.gameSpec,
        userMessage: text.trim(),
        chatHistory: history,
        onChunk: (fullText) {
          _updateChatMessage(aiId, fullText, true);
        },
      );

      // Update AI message with clean text
      _updateChatMessage(aiId, result.message, false);

      // Case 1: Agent proposed structured edits → enter review mode
      if (result.hasEdits) {
        final proposals = result.edits.map(
          (e) => PreviewEditProposal(
            id: e.id,
            oldCode: e.oldCode,
            newCode: e.newCode,
          ),
        );
        state = state.copyWith(
          pendingEdits: proposals.toList(),
          agentState: AgentState.reviewing,
          isChatLoading: false,
        );
      }
      // Case 2: Legacy HTML block (no EDIT blocks) → apply immediately
      else if (result.hasLegacyHtml) {
        await updateCodeAndPersist(result.legacyModifiedHtml!);
        state = state.copyWith(
          agentState: AgentState.idle,
          isChatLoading: false,
        );
      }
      // Case 3: Just a message, no code changes
      else {
        state = state.copyWith(
          agentState: AgentState.idle,
          isChatLoading: false,
        );
      }

      // Handle spec updates (same as before)
      if (result.specUpdates.isNotEmpty) {
        final ws = _ref.read(workspaceProvider(projectId).notifier);
        for (final entry in result.specUpdates.entries) {
          ws.editSpecValue(entry.key, entry.value);
        }
      }

      // Sync to workspace
      _ref
          .read(workspaceProvider(projectId).notifier)
          .addPreviewChatMessage(text.trim(), result.message);
    } catch (e) {
      _updateChatMessage(aiId, 'AI 响应失败: $e\n\n请检查网络连接后重试。', false);
      state = state.copyWith(
        agentState: AgentState.error,
        agentErrorMessage: e.toString(),
        isChatLoading: false,
      );
    }
  }

  // ─── Edit Approval Methods ───────────────────────────────────────────

  void acceptEdit(String editId) {
    state = state.copyWith(
      pendingEdits: state.pendingEdits.map((e) {
        if (e.id == editId) {
          return e.copyWith(isAccepted: true, isRejected: false);
        }
        return e;
      }).toList(),
    );
  }

  void rejectEdit(String editId) {
    state = state.copyWith(
      pendingEdits: state.pendingEdits.map((e) {
        if (e.id == editId) {
          return e.copyWith(isAccepted: false, isRejected: true);
        }
        return e;
      }).toList(),
    );
  }

  void acceptAllEdits() {
    state = state.copyWith(
      pendingEdits: state.pendingEdits.map((e) {
        if (e.isRejected) return e;
        return e.copyWith(isAccepted: true);
      }).toList(),
    );
  }

  void rejectAllEdits() {
    state = state.copyWith(
      pendingEdits: state.pendingEdits.map((e) {
        if (e.isAccepted) return e;
        return e.copyWith(isRejected: true);
      }).toList(),
    );
  }

  /// Apply all accepted edits to the game HTML.
  Future<void> applyAcceptedEdits() async {
    final accepted = state.pendingEdits
        .where((e) => e.isAccepted && !e.isRejected && !e.isApplied)
        .toList();
    if (accepted.isEmpty) {
      state = state.copyWith(agentState: AgentState.idle);
      return;
    }

    state = state.copyWith(agentState: AgentState.applying);

    final agentEdits = accepted
        .map(
          (e) => AgentEditProposal(
            id: e.id,
            oldCode: e.oldCode,
            newCode: e.newCode,
          ),
        )
        .toList();
    final result = _agentService.applyEdits(state.htmlCode, agentEdits);

    // Always update htmlCode with the result — successful edits are
    // already applied in result.modifiedHtml; only failed edits stay
    // pending with error markers.
    await updateCodeAndPersist(result.modifiedHtml);
    final appliedIds = accepted.map((e) => e.id).toSet();
    final errorMap = {for (final e in result.errors) e.editId: e.message};

    state = state.copyWith(
      htmlCode: result.modifiedHtml,
      pendingEdits: state.pendingEdits.map((e) {
        if (appliedIds.contains(e.id) && !errorMap.containsKey(e.id)) {
          return e.copyWith(isApplied: true);
        }
        final err = errorMap[e.id];
        if (err != null) return e.copyWith(applyError: err);
        return e;
      }).toList(),
      agentState: result.success ? AgentState.idle : AgentState.reviewing,
    );
  }

  /// Retry a failed edit with corrected old/new code and apply immediately.
  Future<void> manualRetryEdit(
    String editId,
    String correctedOld,
    String correctedNew,
  ) async {
    final agentEdit = AgentEditProposal(
      id: editId,
      oldCode: correctedOld,
      newCode: correctedNew,
    );
    final result = _agentService.applyEdits(state.htmlCode, [agentEdit]);

    if (result.success) {
      await updateCodeAndPersist(result.modifiedHtml);
      state = state.copyWith(
        htmlCode: result.modifiedHtml,
        pendingEdits: state.pendingEdits.map((e) {
          if (e.id != editId) return e;
          return e.copyWith(isApplied: true, applyError: null);
        }).toList(),
        // If all edits are now decided, go back to idle.
        agentState: state.pendingEdits.every((e) => e.isApplied || e.isRejected)
            ? AgentState.idle
            : AgentState.reviewing,
      );
    } else {
      final errorMsg = result.errors.isNotEmpty
          ? result.errors.first.message
          : '匹配失败';
      state = state.copyWith(
        pendingEdits: state.pendingEdits.map((e) {
          if (e.id != editId) return e;
          return e.copyWith(applyError: errorMsg);
        }).toList(),
        agentState: AgentState.reviewing,
      );
    }
  }

  void clearChat() {
    state = state.copyWith(
      chatMessages: [],
      pendingEdits: [],
      agentState: AgentState.idle,
      agentErrorMessage: null,
    );
  }

  Future<String> _currentCodeModelLabel() async {
    try {
      final provider = await ModelRouter.getProvider(ModelType.code);
      return provider == null || provider.isEmpty ? '当前 AI 模型' : provider;
    } catch (_) {
      return '当前 AI 模型';
    }
  }

  void _updateChatMessage(String id, String content, bool streaming) {
    final msgs = state.chatMessages.map((m) {
      if (m.id == id) {
        return m.copyWith(content: content, isStreaming: streaming);
      }
      return m;
    }).toList();
    state = state.copyWith(chatMessages: msgs);
  }
}

final previewProvider =
    StateNotifierProvider.family<PreviewNotifier, PreviewState, String>(
      (ref, projectId) => PreviewNotifier(projectId, ref),
    );

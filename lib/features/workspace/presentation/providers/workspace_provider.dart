import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/ai/workspace_ai_service.dart';
import '../../../../services/ai/socratic_engine.dart';
import '../../../../services/credits/credit_service.dart';
import '../../../../services/storage/local_db_service.dart';
import '../../../../services/supabase/card_service.dart';
import '../../../../services/supabase/supabase_client.dart';
import '../../domain/card_model.dart';
import '../../domain/game_spec.dart';

const _uuid = Uuid();
String _genId() => _uuid.v4();

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final List<CardModel> cards;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.cards = const [],
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    List<CardModel>? cards,
    bool? isStreaming,
  }) =>
      ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        cards: cards ?? this.cards,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );
}

class WorkspaceState {
  final List<ChatMessage> messages;
  final GameSpec gameSpec;
  final bool isLoading;
  final String? error;

  const WorkspaceState({
    this.messages = const [],
    this.gameSpec = const GameSpec(),
    this.isLoading = false,
    this.error,
  });

  bool get isSpecComplete => gameSpec.isComplete;

  WorkspaceState copyWith({
    List<ChatMessage>? messages,
    GameSpec? gameSpec,
    bool? isLoading,
    String? error,
  }) =>
      WorkspaceState(
        messages: messages ?? this.messages,
        gameSpec: gameSpec ?? this.gameSpec,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final _dimensions = <_DimInfo>[
  _DimInfo('genre', '玩法类型', CardType.gameplay),
  _DimInfo('theme', '主题/故事背景', CardType.story),
  _DimInfo('art_style', '美术风格', CardType.art),
  _DimInfo('camera_view', '视角', CardType.gameplay),
  _DimInfo('core_mechanic', '核心机制', CardType.gameplay),
  _DimInfo('player_ability', '玩家能力', CardType.gameplay),
  _DimInfo('goal', '目标', CardType.gameplay),
  _DimInfo('music_vibe', '音乐氛围', CardType.music),
  _DimInfo('difficulty', '难度', CardType.gameplay),
];

class _DimInfo {
  final String key;
  final String label;
  final CardType cardType;
  const _DimInfo(this.key, this.label, this.cardType);
}

final _questions = [
  '好的！我们先从最基本的开始——你想做什么**类型**的游戏？\n\n常见选择：平台跳跃、RPG、射击、益智、跑酷、模拟经营、节奏',
  '不错的类型！那游戏的**主题/故事背景**是什么呢？\n\n比如：魔法森林、太空探险、赛博朋克、中世纪、末世废土',
  '游戏想要什么样的**美术风格**？\n\n比如：像素风、卡通手绘、低多边形、水墨风、写实',
  '游戏使用什么**视角**？\n\n常见选择：横版卷轴、俯视角、第一人称、第三人称、鸟瞰',
  '**核心玩法机制**是什么？玩家主要做什么？\n\n比如：跳跃闯关、资源收集、战斗系统、解谜推理、建造创造',
  '玩家角色有哪些**能力**？\n\n比如：二段跳、冲刺、攻击、隐身、飞行、攀爬、游泳',
  '游戏的**最终目标**是什么？怎样算通关？\n\n比如：到达终点、击败 BOSS、收集所有物品、达成最高分',
  '游戏的**音乐氛围**想要什么样的？\n\n比如：轻快活泼、紧张激烈、空灵神秘、史诗壮丽、悠闲放松',
  '**难度**设计如何？\n\n比如：休闲轻松（适合所有人）、适中（需要一定技巧）、硬核（挑战性强）',
];

const _completeMessage =
    '太棒了！所有 **9 个维度** 都已确定！\n\n你的游戏创意已经非常完整了，现在可以点击右上角的「**生成游戏**」按钮，开始将你的想法变为现实！';

const _generationHint =
    '\n\n---\n已经聊了不少了！如果你觉得想法已经比较清晰，随时可以点击右上角的「**生成游戏**」按钮先看看效果，不满意还可以回来继续调整。';

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier(this.projectId)
      : _cardService = CardService(SupabaseManager.client),
        _localDb = LocalDbService(),
        _aiService = WorkspaceAiService(),
        super(WorkspaceState()) {
    Future(() => _init());
  }

  final String projectId;
  final CardService _cardService;
  final LocalDbService _localDb;
  final WorkspaceAiService _aiService;

  int _currentDimIndex = 0;
  int _roundsInDim = 1;
  int _totalRounds = 0;
  final Set<String> _filledDimKeys = {};

  /// Public access for the visual cards panel.
  Set<String> get filledDimKeys => Set.unmodifiable(_filledDimKeys);

  // ─── Initialization ────────────────────────────────────────────────

  Future<void> _init() async {
    List<CardModel> cards;
    try {
      cards = await _cardService.getCards(projectId);
      if (cards.isNotEmpty) {
        await _localDb.cacheCards(projectId, cards);
      }
    } catch (_) {
      cards = await _localDb.getLocalCards(projectId);
    }

    if (cards.isNotEmpty) {
      _reconstructConversation(cards);
      return;
    }
    _sendWelcome();
  }

  void _reconstructConversation(List<CardModel> cards) {
    final messages = <ChatMessage>[];
    var spec = const GameSpec();

    for (final card in cards) {
      final key = _dimKeyFromCard(card);
      if (key == null) continue;
      final value = card.content[key] as String? ?? '';

      final dimIndex = _dimensions.indexWhere((d) => d.key == key);
      if (dimIndex >= 0) {
        spec = _updateSpecByKey(spec, key, value);
        _filledDimKeys.add(key);
      }

      messages.add(ChatMessage(
        id: _genId(),
        role: MessageRole.user,
        content: value,
        timestamp: card.createdAt,
      ));
      messages.add(ChatMessage(
        id: _genId(),
        role: MessageRole.assistant,
        content: '已记录「${SocraticEngine.labelForKey(key)}」设定 ✓',
        cards: [card],
        timestamp: card.updatedAt,
      ));
    }

    _totalRounds = cards.length;

    // Find next unfilled dimension
    _advanceToNextUnfilled();

    final nextContent = _currentDimIndex < _dimensions.length
        ? _questions[_currentDimIndex]
        : _completeMessage;

    messages.add(ChatMessage(
      id: _genId(),
      role: MessageRole.assistant,
      content: nextContent,
      timestamp: DateTime.now(),
    ));

    state = WorkspaceState(messages: messages, gameSpec: spec);
  }

  void _sendWelcome() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: _genId(),
          role: MessageRole.assistant,
          content: '欢迎来到 **GameForger**！🎮\n\n我会通过一系列提问，帮你逐步完善你的游戏创意。'
              '当我觉得你的想法还不够清晰时，我会继续追问——这不是啰嗦，而是帮你想得更透彻。\n\n${_questions[0]}',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  // ─── Conversation History ──────────────────────────────────────────

  /// Builds dimension summaries (one line per filled dimension).
  String _buildDimensionSummaries() {
    final buf = StringBuffer();
    for (final key in _filledDimKeys) {
      final value = _specValueForKey(state.gameSpec, key);
      if (value != null && value.isNotEmpty) {
        buf.writeln('- ${SocraticEngine.labelForKey(key)}: $value');
      }
    }
    return buf.toString();
  }

  /// Builds recent conversation history (last 6 messages in full, plus
  /// a summary count of older messages).
  String _buildRecentHistory() {
    final allMsgs = state.messages
        .where((m) => !m.isStreaming && m.content.isNotEmpty)
        .toList();

    if (allMsgs.isEmpty) return '';

    final recentCount = 6;
    final startIdx = allMsgs.length > recentCount
        ? allMsgs.length - recentCount
        : 0;

    final buf = StringBuffer();
    if (startIdx > 0) {
      buf.writeln('（前面已有 $startIdx 轮对话）');
    }

    for (int i = startIdx; i < allMsgs.length; i++) {
      final msg = allMsgs[i];
      final role = msg.role == MessageRole.user
          ? '用户'
          : msg.role == MessageRole.assistant
              ? 'GameForger'
              : '系统';
      buf.writeln('$role: ${msg.content}');
    }
    return buf.toString();
  }

  // ─── Send Message ──────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id: _genId(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    final assistantId = _genId();
    final streamingMsg = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, streamingMsg],
      isLoading: true,
    );

    _totalRounds++;

    if (_currentDimIndex < _dimensions.length) {
      final dim = _dimensions[_currentDimIndex];

      // Check forced advance (max rounds per dimension)
      final forcedAdvance =
          _roundsInDim >= SocraticEngine.maxRoundsPerDimension;

      final summaries = _buildDimensionSummaries();
      final recentHistory = _buildRecentHistory();

      try {
        final aiResponse = await _aiService.processResponseStream(
          currentSpec: state.gameSpec,
          currentDimKey: dim.key,
          currentDimLabel: dim.label,
          userResponse: text.trim(),
          dimensionSummaries: summaries,
          recentHistory: recentHistory,
          roundInDim: _roundsInDim,
          onChunk: (fullTextSoFar) {
            if (mounted) {
              _updateAssistantMessage(assistantId, fullTextSoFar, true);
            }
          },
        );

        final shouldAdvance =
            forcedAdvance || aiResponse.shouldProceed;

        if (shouldAdvance) {
          // Save card for the current dimension
          final newSpec = _updateSpecByKey(
              state.gameSpec, dim.key, aiResponse.extractedValue);

          final card = CardModel(
            id: _genId(),
            projectId: projectId,
            type: dim.cardType,
            content: {
              dim.key: aiResponse.extractedValue,
              '_label': dim.label,
              if (aiResponse.cardSummary != null &&
                  aiResponse.cardSummary!.isNotEmpty)
                'summary': aiResponse.cardSummary!,
            },
            orderIndex: _filledDimKeys.length,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          _filledDimKeys.add(dim.key);
          _roundsInDim = 1;

          // Determine next dimension
          final suggestedKey = aiResponse.suggestedNextDimension;
          if (suggestedKey != null &&
              suggestedKey.isNotEmpty &&
              !_filledDimKeys.contains(suggestedKey)) {
            final suggestedIdx =
                _dimensions.indexWhere((d) => d.key == suggestedKey);
            if (suggestedIdx >= 0) {
              _currentDimIndex = suggestedIdx;
            } else {
              _advanceToNextUnfilled();
            }
          } else {
            _advanceToNextUnfilled();
          }

          // Build completion or next-question message
          final buffer = StringBuffer();
          if (aiResponse.reflection.isNotEmpty) {
            buffer.writeln(aiResponse.reflection);
            buffer.writeln();
          }

          if (_currentDimIndex < _dimensions.length) {
            // Show depth score indicator for transparency
            if (forcedAdvance) {
              buffer.writeln(
                  '> ⚡ 已自动推进到下一个维度（本维度已达 ${SocraticEngine.maxRoundsPerDimension} 轮上限）');
              buffer.writeln();
            } else {
              buffer.writeln(
                  '> 深度评分: ${'★' * aiResponse.currentDimDepth}${'☆' * (5 - aiResponse.currentDimDepth)} — ${aiResponse.shouldProceedReasoning}');
              buffer.writeln();
            }
            buffer.write(aiResponse.nextQuestion);
          } else {
            buffer.write(_completeMessage);
          }

          // Check guardrail: suggest generation after many rounds
          if (_totalRounds >= SocraticEngine.suggestGenerationAfterRounds) {
            buffer.write(_generationHint);
          }

          _finalizeAssistantMessage(
              assistantId, buffer.toString().trim(), [card]);

          state = state.copyWith(
            gameSpec: newSpec,
            isLoading: false,
          );

          _cardService.saveCard(card);
          _localDb.cacheCard(card);
        } else {
          // Stay on current dimension — no card saved
          _roundsInDim++;

          final buffer = StringBuffer();
          if (aiResponse.reflection.isNotEmpty) {
            buffer.writeln(aiResponse.reflection);
            buffer.writeln();
          }
          buffer.writeln(
              '> 深度评分: ${'★' * aiResponse.currentDimDepth}${'☆' * (5 - aiResponse.currentDimDepth)} — ${aiResponse.shouldProceedReasoning}');
          buffer.writeln();
          buffer.write(aiResponse.nextQuestion);

          if (_totalRounds >= SocraticEngine.suggestGenerationAfterRounds) {
            buffer.write(_generationHint);
          }

          _finalizeAssistantMessage(
              assistantId, buffer.toString().trim(), []);

          state = state.copyWith(isLoading: false);
        }
      } on DeductException catch (e) {
        _finalizeAssistantMessage(
          assistantId,
          '点数不足！\n\n当前余额: ${e.balance} 点，需要: ${e.required} 点\n请到「设置 → 点数中心」购买更多点数。',
          [],
        );
        state = state.copyWith(isLoading: false, error: e.message);
      } catch (e) {
        _finalizeAssistantMessage(
          assistantId,
          'AI 响应失败: $e\n\n请检查网络连接，或到「设置 → API 配置」确认 API Key 配置正确。',
          [],
        );
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } else {
      // ── Free-chat refinement mode (all dimensions filled) ──
      final summaries = _buildDimensionSummaries();
      final recentHistory = _buildRecentHistory();

      try {
        final aiText = await _aiService.processRefinementStream(
          currentSpec: state.gameSpec,
          userResponse: text.trim(),
          dimensionSummaries: summaries,
          recentHistory: recentHistory,
          onChunk: (fullTextSoFar) {
            if (mounted) {
              _updateAssistantMessage(assistantId, fullTextSoFar, true);
            }
          },
        );

        // Check if user is modifying an existing dimension
        _tryUpdateSpecFromRefinement(aiText, text.trim());

        _finalizeAssistantMessage(assistantId, aiText, []);
        state = state.copyWith(isLoading: false);
      } on DeductException catch (e) {
        _finalizeAssistantMessage(
          assistantId,
          '点数不足！\n\n当前余额: ${e.balance} 点，需要: ${e.required} 点\n请到「设置 → 点数中心」购买更多点数。',
          [],
        );
        state = state.copyWith(isLoading: false, error: e.message);
      } catch (e) {
        _finalizeAssistantMessage(
          assistantId,
          'AI 响应失败: $e\n\n请检查网络连接，或到「设置 → API 配置」确认 API Key 配置正确。',
          [],
        );
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  // ─── Dimension Navigation ──────────────────────────────────────────

  /// Moves [_currentDimIndex] to the next unfilled dimension.
  void _advanceToNextUnfilled() {
    for (int i = 0; i < _dimensions.length; i++) {
      if (!_filledDimKeys.contains(_dimensions[i].key)) {
        _currentDimIndex = i;
        return;
      }
    }
    _currentDimIndex = _dimensions.length; // All filled
  }

  // ─── Spec Helpers ──────────────────────────────────────────────────

  GameSpec _updateSpecByKey(GameSpec spec, String key, String value) {
    switch (key) {
      case 'genre': return spec.copyWith(genre: value);
      case 'theme': return spec.copyWith(theme: value);
      case 'art_style': return spec.copyWith(artStyle: value);
      case 'camera_view': return spec.copyWith(cameraView: value);
      case 'core_mechanic': return spec.copyWith(coreMechanic: value);
      case 'player_ability': return spec.copyWith(playerAbility: value);
      case 'goal': return spec.copyWith(goal: value);
      case 'music_vibe': return spec.copyWith(musicVibe: value);
      case 'difficulty': return spec.copyWith(difficulty: value);
      default: return spec;
    }
  }

  String? _specValueForKey(GameSpec spec, String key) {
    switch (key) {
      case 'genre': return spec.genre;
      case 'theme': return spec.theme;
      case 'art_style': return spec.artStyle;
      case 'camera_view': return spec.cameraView;
      case 'core_mechanic': return spec.coreMechanic;
      case 'player_ability': return spec.playerAbility;
      case 'goal': return spec.goal;
      case 'music_vibe': return spec.musicVibe;
      case 'difficulty': return spec.difficulty;
      default: return null;
    }
  }

  String? _dimKeyFromCard(CardModel card) {
    for (final dim in _dimensions) {
      if (card.content.containsKey(dim.key)) return dim.key;
    }
    return null;
  }

  // ─── Streaming Helpers ─────────────────────────────────────────────

  void _updateAssistantMessage(String id, String content, bool streaming) {
    final msgs = state.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(content: content, isStreaming: streaming);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: msgs);
  }

  void _finalizeAssistantMessage(
      String id, String content, List<CardModel> cards) {
    final msgs = state.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(content: content, cards: cards, isStreaming: false);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: msgs);
  }

  /// Heuristically detect if the user is modifying an existing dimension
  /// during refinement chat, and update the spec accordingly.
  void _tryUpdateSpecFromRefinement(String aiResponse, String userMessage) {
    final lowerResp = aiResponse.toLowerCase();
    final lowerMsg = userMessage.toLowerCase();

    for (final dim in _dimensions) {
      // Check if user message and AI response both reference this dimension
      final dimCN = dim.label;
      if (_filledDimKeys.contains(dim.key) &&
          (lowerMsg.contains(dimCN) || lowerResp.contains(dimCN))) {
        // Simple heuristic: if AI says "已更新" or "修改" near the dimension,
        // extract the new value from the user message
        if (lowerResp.contains('更新') || lowerResp.contains('修改') ||
            lowerResp.contains('改为') || lowerResp.contains('改成')) {
          final currentVal = _specValueForKey(state.gameSpec, dim.key) ?? '';
          if (userMessage.trim() != currentVal && userMessage.trim().length > 1) {
            state = state.copyWith(
              gameSpec: _updateSpecByKey(state.gameSpec, dim.key, userMessage.trim()),
            );
          }
        }
      }
    }
  }

  // ─── Manual Card / Spec / Clear ────────────────────────────────────

  void addManualCard(CardType type, Map<String, dynamic> content) {
    final card = CardModel(
      id: _genId(),
      projectId: projectId,
      type: type,
      content: {...content, '_label': type.label},
      orderIndex: state.messages.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final msg = ChatMessage(
      id: _genId(),
      role: MessageRole.system,
      content: '添加了「${type.label}」卡片',
      cards: [card],
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void updateGameSpec(GameSpec spec) {
    state = state.copyWith(gameSpec: spec);
  }

  /// Directly edit a dimension value from the visual card.
  void editSpecValue(String dimKey, String newValue) {
    if (newValue.trim().isEmpty) return;
    final newSpec = _updateSpecByKey(state.gameSpec, dimKey, newValue.trim());
    state = state.copyWith(gameSpec: newSpec);

    // Add a system message noting the edit
    final label = SocraticEngine.labelForKey(dimKey);
    final msg = ChatMessage(
      id: _genId(),
      role: MessageRole.system,
      content: '✏️ 已修改「$label」为：$newValue',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  /// Add a summary message from the preview-page AI chat, so the
  /// conversation continuity is preserved when returning to the workspace.
  void addPreviewChatMessage(String userMessage, String aiResponse) {
    final msg = ChatMessage(
      id: _genId(),
      role: MessageRole.system,
      content: '💬 预览对话\n\n**你**: $userMessage\n\n**AI**: ${aiResponse.length > 200 ? '${aiResponse.substring(0, 200)}...' : aiResponse}',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  /// Re-discuss a dimension via Socratic dialogue.
  /// Sets the current dimension index back to the requested one and
  /// asks the AI a follow-up question about that dimension.
  void rediscussDimension(String dimKey, String label) {
    final dimIndex = _dimensions.indexWhere((d) => d.key == dimKey);
    if (dimIndex < 0) return;

    _currentDimIndex = dimIndex;
    _roundsInDim = 1;
    _filledDimKeys.remove(dimKey);

    final question = '我想重新讨论「$label」。之前的选择可能不太合适，让我们重新想想。';

    final msg = ChatMessage(
      id: _genId(),
      role: MessageRole.system,
      content: '🔄 重新讨论「$label」...',
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);

    // Trigger AI to ask the question for this dimension
    sendMessage(question);
  }

  Future<void> clearMessages() async {
    await _cardService.deleteProjectCards(projectId);
    await _localDb.deleteLocalProject(projectId);
    state = WorkspaceState();
    _currentDimIndex = 0;
    _roundsInDim = 1;
    _totalRounds = 0;
    _filledDimKeys.clear();
    _sendWelcome();
  }
}

final workspaceProvider = StateNotifierProvider.family<
    WorkspaceNotifier, WorkspaceState, String>(
  (ref, projectId) => WorkspaceNotifier(projectId),
);

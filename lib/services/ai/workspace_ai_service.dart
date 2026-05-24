import 'dart:async';
import 'dart:convert';
import 'deepseek_proxy.dart';
import '../../features/workspace/domain/game_spec.dart';
import 'socratic_engine.dart';

class WorkspaceAiResponse {
  final String extractedValue;
  final String nextQuestion;
  final String? cardSummary;
  final String reflection;
  final int currentDimDepth;
  final bool shouldProceed;
  final String shouldProceedReasoning;
  final String? suggestedNextDimension;

  const WorkspaceAiResponse({
    required this.extractedValue,
    required this.nextQuestion,
    this.cardSummary,
    required this.reflection,
    this.currentDimDepth = 1,
    this.shouldProceed = false,
    this.shouldProceedReasoning = '',
    this.suggestedNextDimension,
  });
}

class WorkspaceAiService {
  final AiProxy _proxy;

  WorkspaceAiService({AiProxy? proxy})
      : _proxy = proxy ?? AiProxy();

  String _buildRefinementPrompt(GameSpec spec, {
    String dimensionSummaries = '',
    String recentHistory = '',
  }) {
    final filled = <String>[];
    if (spec.genre != null) filled.add('- 玩法类型: ${spec.genre}');
    if (spec.theme != null) filled.add('- 主题/故事: ${spec.theme}');
    if (spec.artStyle != null) filled.add('- 美术风格: ${spec.artStyle}');
    if (spec.cameraView != null) filled.add('- 视角: ${spec.cameraView}');
    if (spec.coreMechanic != null) filled.add('- 核心机制: ${spec.coreMechanic}');
    if (spec.playerAbility != null) filled.add('- 玩家能力: ${spec.playerAbility}');
    if (spec.goal != null) filled.add('- 目标: ${spec.goal}');
    if (spec.musicVibe != null) filled.add('- 音乐氛围: ${spec.musicVibe}');
    if (spec.difficulty != null) filled.add('- 难度: ${spec.difficulty}');

    return '''你是 GameForger，一位世界级的游戏设计顾问。所有9个设计维度已初步确定，现在进入**自由细化阶段**。

## 当前完整设计
${filled.join('\n')}

## 近期对话
${recentHistory.isEmpty ? '（这是对话的开始）' : recentHistory}

## 你的职责
用户可能会：
1. 修改某个已有的设定（如"我想把美术风格改成像素风"）
2. 深入讨论某个维度的细节（如"跳跃手感应该怎么设计"）
3. 询问游戏设计建议（如"这个机制会不会太简单"）
4. 添加之前未涉及的新想法

## 对话规则
- 热情回应，给出有洞察力的建议
- 如果用户要修改某个设定，确认后告知这个改动对整体的影响
- 如果用户的想法有设计矛盾，友善地指出
- 用具体的游戏案例来说明你的观点
- 当用户的设计足够完善时，鼓励他们点击「生成游戏」按钮
- 保持对话流畅自然，不需要评分，不需要强制推进维度

## 输出格式
直接以自然语言回复，不需要 JSON 格式。像真正的游戏设计顾问一样聊天。''';
  }

  String _buildSystemPrompt(
    String currentDimKey,
    String currentDimLabel,
    GameSpec spec, {
    String dimensionSummaries = '',
    String recentHistory = '',
    int roundInDim = 1,
  }) {
    final filled = <String>[];
    if (spec.genre != null) filled.add('- 玩法类型: ${spec.genre}');
    if (spec.theme != null) filled.add('- 主题/故事: ${spec.theme}');
    if (spec.artStyle != null) filled.add('- 美术风格: ${spec.artStyle}');
    if (spec.cameraView != null) filled.add('- 视角: ${spec.cameraView}');
    if (spec.coreMechanic != null) filled.add('- 核心机制: ${spec.coreMechanic}');
    if (spec.playerAbility != null) filled.add('- 玩家能力: ${spec.playerAbility}');
    if (spec.goal != null) filled.add('- 目标: ${spec.goal}');
    if (spec.musicVibe != null) filled.add('- 音乐氛围: ${spec.musicVibe}');
    if (spec.difficulty != null) filled.add('- 难度: ${spec.difficulty}');

    final forcedAdvanceNote = roundInDim >= SocraticEngine.maxRoundsPerDimension
        ? '\n⚠️ 这是「$currentDimLabel」维度的第 $roundInDim 轮（已达上限）。本轮**必须**推进到下一个维度，不要再停留。'
        : '';

    return '''你是 GameForger，一位世界级的游戏设计顾问，拥有 20 年独立游戏开发经验。你的专长是通过苏格拉底式对话，帮助创作者发现自己内心真正想做的游戏——而不是简单地记录他们的表面答案。

## 核心信念
- 每个好游戏都有一个"核心情感"：你想让玩家感到紧张？好奇？成就感？自由？
- 最好的设计是互相增强的——玩法类型应该呼应主题，美术风格应该强化氛围
- "好玩"不是一个充分的答案。追问下去：是操作精准带来的好胜心？是探索未知带来的惊喜？是收集养成带来的满足感？
- 一个模糊的想法，经过 5 层"为什么"的追问，才能变成真正的设计

## 对话风格
- 热情但不浮夸，专业但不冷漠
- 对用户的每个回答，先给予真诚的肯定
- 然后通过追问帮助用户深化想法：如果有矛盾，指出它；如果有多种可能，列举它们；如果某个选择会影响后续设计，提前告知
- 用具体的游戏案例来说明你的观点（"像 Celeste 那样的精确跳跃手感"比"手感要好"有用一百倍）
- 如果你的提问没有激发用户新的思考，那就不是一个好问题

## 回答深度评分标准（1-5）
你必须对用户在**当前维度**的回答进行深度评分：
- **1 分**：模糊、笼统，没有实质内容（"做个好玩的游戏"、"随便"、"不知道"）
- **2 分**：有大致方向但缺乏具体细节（"平台跳跃游戏"、"科幻风格"）
- **3 分**：有具体的机制描述（"2D平台跳跃，收集金币，3条命"）
- **4 分**：机制清晰且有具体游戏参考（"像 Celeste 一样有冲刺和攀墙的平台跳跃"）
- **5 分**：设计完整且包含情感核心（"我希望玩家在精确操作后感受到巨大的成就感，每次失败都是学习..."）

## 推进规则（极其重要）
- depth >= 3 且用户表现出对该维度的清晰理解 → should_proceed = true
- depth < 3 → **必须留在当前维度**，用更简单、更具体的问题引导用户深入思考
- depth < 3 时，给 2-3 个具体的选择题帮助用户降低思考门槛
- 不要为了推进而降低标准——模糊的设计会导致糟糕的游戏体验

## 维度跳转建议
你可以在 suggested_next_dimension 中建议跳转到某个非顺序的维度，当：
- 用户的回答暗示了某个后续维度的强烈倾向（如提到"音乐"→建议跳到 music_vibe）
- 某个维度的选择会根本性地影响其他维度（如选择了"音游"→应该先确定 music_vibe）
- 正常情况留空字符串即可，系统会按顺序推进

## 当前设计进度
${filled.isEmpty ? '（刚刚开始，什么还没确定）' : filled.join('\n')}

## 已确定维度摘要
${dimensionSummaries.isEmpty ? '（尚未确定任何维度）' : dimensionSummaries}

## 近期对话
${recentHistory.isEmpty ? '（这是对话的开始）' : recentHistory}

## 当前维度和任务
你现在正在帮助用户厘清：**$currentDimLabel**（第 $roundInDim 轮）$forcedAdvanceNote

你需要：
1. 分析用户刚才的回复
2. 对回答进行深度评分（1-5）
3. 给出有洞察力的回应（2-4句，比之前更深）
4. 根据深度决定是留在当前维度追问还是推进到下一个维度
5. 如果推进，建议下一个维度（通常留空即可）

## 输出格式（严格 JSON，不要包含其他文字）
{
  "reflection": "对用户回复的深入分析——2-4句话。包括：肯定用户回答中的亮点、指出这个选择与已有设计的关联或潜在矛盾、给出可操作的改进建议",
  "extracted_value": "从用户回复中提炼的关于$currentDimLabel的具体描述，要准确、不要丢失细节",
  "current_dim_depth": 3,
  "should_proceed": true,
  "should_proceed_reasoning": "简短说明为什么推进或不推进（1句话）",
  "suggested_next_dimension": "",
  "next_question": "下一个问题。如果 should_proceed=false，针对当前维度问得更具体（给选择题）；如果 should_proceed=true，问下一个维度的问题。要包含：为什么这个维度重要 + 1-2个具体例子 + 开放式的结尾",
  "card_summary": "一句话卡片总结（仅在 should_proceed=true 时填写，否则留空字符串）"
}''';
  }

  Future<WorkspaceAiResponse> processResponse({
    required GameSpec currentSpec,
    required String currentDimKey,
    required String currentDimLabel,
    required String userResponse,
    String dimensionSummaries = '',
    String recentHistory = '',
    int roundInDim = 1,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      currentDimKey, currentDimLabel, currentSpec,
      dimensionSummaries: dimensionSummaries,
      recentHistory: recentHistory,
      roundInDim: roundInDim,
    );

    try {
      final result = await _proxy.chat(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userResponse},
        ],
      );

      final content =
          result['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Empty AI response');
      }

      return _parseResponse(content, userResponse.trim(), currentDimLabel);
    } catch (e) {
      _logError(e);
      return _fallbackResponse(userResponse, currentDimLabel);
    }
  }

  /// Streaming version: yields raw text chunks as they arrive, then completes
  /// with the parsed [WorkspaceAiResponse].
  Future<WorkspaceAiResponse> processResponseStream({
    required GameSpec currentSpec,
    required String currentDimKey,
    required String currentDimLabel,
    required String userResponse,
    String dimensionSummaries = '',
    String recentHistory = '',
    int roundInDim = 1,
    required void Function(String fullTextSoFar) onChunk,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      currentDimKey, currentDimLabel, currentSpec,
      dimensionSummaries: dimensionSummaries,
      recentHistory: recentHistory,
      roundInDim: roundInDim,
    );

    try {
      final buffer = StringBuffer();
      await for (final chunk in _proxy.chatStream(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userResponse},
        ],
        temperature: 0.7,
      )) {
        buffer.write(chunk);
        onChunk(buffer.toString());
      }

      final fullContent = buffer.toString();
      if (fullContent.isEmpty) {
        throw Exception('Empty AI response');
      }

      return _parseResponse(fullContent, userResponse.trim(), currentDimLabel);
    } catch (e) {
      _logError(e);
      return _fallbackResponse(userResponse, currentDimLabel);
    }
  }

  /// Free-form refinement chat after all dimensions are filled.
  /// No JSON parsing — returns the raw AI text response.
  Future<String> processRefinementStream({
    required GameSpec currentSpec,
    required String userResponse,
    String dimensionSummaries = '',
    String recentHistory = '',
    required void Function(String fullTextSoFar) onChunk,
  }) async {
    final systemPrompt = _buildRefinementPrompt(
      currentSpec,
      dimensionSummaries: dimensionSummaries,
      recentHistory: recentHistory,
    );

    try {
      final buffer = StringBuffer();
      await for (final chunk in _proxy.chatStream(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userResponse},
        ],
        temperature: 0.8,
      )) {
        buffer.write(chunk);
        onChunk(buffer.toString());
      }

      final fullContent = buffer.toString();
      if (fullContent.isEmpty) {
        throw Exception('Empty AI response');
      }
      return fullContent;
    } catch (e) {
      _logError(e);
      return '抱歉，AI 服务暂时无法响应。请稍后重试，或到「设置 → API 配置」检查 API Key 是否配置正确。';
    }
  }

  void _logError(Object e) {
    // ignore: avoid_print
    print('⚠️ [WorkspaceAiService] AI call failed: $e');
  }

  WorkspaceAiResponse _fallbackResponse(
      String userResponse, String dimLabel) {
    return WorkspaceAiResponse(
      extractedValue: userResponse.trim(),
      nextQuestion: '抱歉，AI 服务暂时无法响应。请稍后重试，或到「设置 → API 配置」检查 API Key 是否配置正确。',
      cardSummary: null,
      reflection: '',
      currentDimDepth: SocraticEngine.scoreDepth(userResponse, dimLabel),
      shouldProceed: true,
      shouldProceedReasoning: 'AI unavailable — proceeding with heuristic depth',
    );
  }

  WorkspaceAiResponse _parseResponse(
      String content, String fallbackValue, String dimLabel) {
    try {
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) throw Exception('No JSON found');

      final jsonStr = content.substring(jsonStart, jsonEnd + 1);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final aiDepth = (data['current_dim_depth'] as num?)?.toInt();
      final depth = aiDepth ??
          SocraticEngine.scoreDepth(
              (data['extracted_value'] as String?) ?? fallbackValue, dimLabel);

      return WorkspaceAiResponse(
        extractedValue:
            (data['extracted_value'] as String?)?.trim() ?? fallbackValue,
        nextQuestion:
            (data['next_question'] as String?)?.trim() ?? '请继续描述你的想法',
        cardSummary: data['card_summary'] as String?,
        reflection: (data['reflection'] as String?)?.trim() ?? '',
        currentDimDepth: depth,
        shouldProceed: data['should_proceed'] as bool? ?? (depth >= 3),
        shouldProceedReasoning:
            (data['should_proceed_reasoning'] as String?)?.trim() ?? '',
        suggestedNextDimension:
            data['suggested_next_dimension'] as String?,
      );
    } catch (_) {
      final depth = SocraticEngine.scoreDepth(fallbackValue, dimLabel);
      return WorkspaceAiResponse(
        extractedValue: fallbackValue,
        nextQuestion: '好的，请继续展开说说你的想法！',
        cardSummary: null,
        reflection: '',
        currentDimDepth: depth,
        shouldProceed: depth >= 3,
        shouldProceedReasoning: '',
      );
    }
  }
}

import 'deepseek_proxy.dart';
import '../../features/workspace/domain/game_spec.dart';

/// A single edit proposed by the AI agent.
class AgentEditProposal {
  final String id;
  final String oldCode;
  final String newCode;

  const AgentEditProposal({
    required this.id,
    required this.oldCode,
    required this.newCode,
  });
}

/// Result of parsing the AI's full response.
class PreviewAgentResult {
  /// Clean message text (all structural blocks removed).
  final String message;

  /// Edit proposals extracted from ---EDIT--- blocks.
  final List<AgentEditProposal> edits;

  /// Spec dimension updates: {dimKey: newValue}
  final Map<String, String> specUpdates;

  /// Legacy: modified HTML from ```html block (fallback when no EDIT blocks).
  final String? legacyModifiedHtml;

  const PreviewAgentResult({
    required this.message,
    this.edits = const [],
    this.specUpdates = const {},
    this.legacyModifiedHtml,
  });

  bool get hasEdits => edits.isNotEmpty;
  bool get hasLegacyHtml =>
      legacyModifiedHtml != null && legacyModifiedHtml!.isNotEmpty;
}

/// Result of applying edits to HTML.
class ApplyEditsResult {
  final String modifiedHtml;
  final bool success;
  final List<ApplyError> errors;

  const ApplyEditsResult({
    required this.modifiedHtml,
    required this.success,
    this.errors = const [],
  });
}

class ApplyError {
  final String editId;
  final String message;

  const ApplyError({required this.editId, required this.message});
}

/// Agent service for the preview-page code modification.
///
/// Unlike [PreviewChatService], this service uses a structured block format
/// (---THINK---, ---EDIT---, ---MESSAGE---) to let the AI propose targeted
/// code edits that the user can approve or reject — similar to Claude Code.
class PreviewAgentService {
  final AiProxy _proxy;

  PreviewAgentService({AiProxy? proxy}) : _proxy = proxy ?? AiProxy();

  String _buildSystemPrompt(GameSpec spec) {
    final lines = <String>[];
    if (spec.genre != null) lines.add('- 玩法类型: ${spec.genre}');
    if (spec.theme != null) lines.add('- 主题/故事: ${spec.theme}');
    if (spec.artStyle != null) lines.add('- 美术风格: ${spec.artStyle}');
    if (spec.cameraView != null) lines.add('- 视角: ${spec.cameraView}');
    if (spec.coreMechanic != null) lines.add('- 核心机制: ${spec.coreMechanic}');
    if (spec.playerAbility != null) lines.add('- 玩家能力: ${spec.playerAbility}');
    if (spec.goal != null) lines.add('- 目标: ${spec.goal}');
    if (spec.musicVibe != null) lines.add('- 音乐氛围: ${spec.musicVibe}');
    if (spec.difficulty != null) lines.add('- 难度: ${spec.difficulty}');

    return '''你是 GameForger，一位 AI 游戏开发代理。你正在帮助用户对正在运行的 HTML5 游戏进行小幅修改。

## 游戏当前设计
${lines.isEmpty ? '（暂无设定）' : lines.join('\n')}

## 你的工具

你可以使用以下工具来修改游戏代码：

### 1. THINK —— 思考和推理
使用 ---THINK--- 块来分析代码和规划修改方案。用户可以看到你的思考过程。

### 2. EDIT —— 修改代码（关键工具）
使用 ---EDIT--- 块来对游戏代码进行精确的字符串替换。格式如下：

---EDIT---
---OLD---
<要替换的精确代码>
---NEW---
<替换后的代码>
---END---

要求：
- OLD 中的字符串必须和游戏代码**完全匹配**（包括空格和缩进）
- 只修改用户要求的部分，做最小幅度的修改
- 每次只输出一个 EDIT 块，不连续的修改要输出多个 EDIT 块
- 如果某段代码出现不止一次，在 OLD 中包含足够的周围上下文以确保唯一性

### 3. MESSAGE —— 回复用户
使用 ---MESSAGE--- 块来输出面向用户的最终回复。

## 输出顺序
始终按以下顺序输出：

---THINK---
你的分析和修改方案...
---EDIT---
---OLD---
精确匹配的代码...
---NEW---
替换后的代码...
---END---
---MESSAGE---
给用户的中文回复...

如果不需要修改代码（比如用户只是提问），可以只输出：
---MESSAGE---
你的回复...

如果用户的需求会导致游戏无法运行，请在 MESSAGE 中解释原因，不要输出 EDIT 块。

## 修改原则
- 尽量做最小幅度的修改
- 保持原有的游戏架构和核心机制
- 确保修改后的代码能正常运行（标签闭合、语法正确）
- 修改后检查：所有 HTML 标签是否闭合、JavaScript 语法是否正确

## 设计维度更新
如果用户的修改涉及修改某个设计维度（玩法类型、主题、美术风格、视角、核心机制、玩家能力、目标、音乐氛围、难度），在 MESSAGE 之后附加：

---SPEC_UPDATE---
dim_key: 维度键名
new_value: 新值
---END_SPEC_UPDATE---

注意：只有当用户的请求确实改变了某个维度的定义时才附加 SPEC_UPDATE，不要过度推断。''';
  }

  /// Stream the AI response, returning the parsed agent result.
  Future<PreviewAgentResult> processModificationStream({
    required String currentHtml,
    required GameSpec gameSpec,
    required String userMessage,
    required List<Map<String, String>> chatHistory,
    required void Function(String fullTextSoFar) onChunk,
  }) async {
    final systemPrompt = _buildSystemPrompt(gameSpec);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content': '这是当前游戏的完整 HTML 代码：\n\n```html\n$currentHtml\n```\n\n'
      },
    ];

    // Include recent chat history (last 4 exchanges)
    final recentHistory = chatHistory.length > 8
        ? chatHistory.sublist(chatHistory.length - 8)
        : chatHistory;
    for (final msg in recentHistory) {
      messages.add(Map.of(msg));
    }

    // Add the current user message
    messages.add({'role': 'user', 'content': userMessage});

    try {
      final buffer = StringBuffer();
      await for (final chunk in _proxy.chatStream(
        messages: messages,
        temperature: 0.7,
      )) {
        buffer.write(chunk);
        onChunk(buffer.toString());
      }

      final fullContent = buffer.toString();
      return _parseResponse(fullContent);
    } catch (e) {
      final msg = e.toString();
      // Provide helpful hints for known error patterns
      if (msg.contains('missing OPENAI_API_KEY')) {
        return PreviewAgentResult(
          message: 'AI 服务无法使用 GPT 模型，因为服务器未配置 OpenAI API 密钥。\n\n'
              '解决方法：\n'
              '1. 在「设置 → API 配置」中添加您自己的 OpenAI API Key（推荐）\n'
              '2. 在「设置 → API 配置」中将提供商切换为「DeepSeek」以使用内置服务\n'
              '3. 或联系管理员在 Supabase 后台配置 OPENAI_API_KEY 环境变量',
        );
      }
      if (msg.contains('Insufficient credits') ||
          msg.contains('insufficient credits') ||
          msg.contains('点数不足')) {
        return PreviewAgentResult(
          message: '点数不足，无法使用 AI 服务。\n\n'
              '请充值点数，或在「设置 → API 配置」中添加您自己的 API Key。',
        );
      }
      return PreviewAgentResult(
        message: '抱歉，AI 服务暂时无法响应。请稍后重试。\n\n'
            '提示：您可以在「设置 → API 配置」中添加自定义 API Key 来获得更稳定的服务。\n\n错误: $e',
      );
    }
  }

  /// Parse the AI response into structured blocks.
  PreviewAgentResult _parseResponse(String content) {
    // Extract spec updates first
    final specUpdates = <String, String>{};
    final specMatch = RegExp(
      r'---SPEC_UPDATE---\s*dim_key:\s*(.+?)\s*new_value:\s*(.+?)\s*---END_SPEC_UPDATE---',
      dotAll: true,
    ).firstMatch(content);
    if (specMatch != null) {
      specUpdates[specMatch.group(1)!.trim()] = specMatch.group(2)!.trim();
    }

    // Extract EDIT blocks using a line-based state machine
    final edits = <AgentEditProposal>[];
    bool inEdit = false;
    bool inOld = false;
    bool inNew = false;
    final oldBuf = StringBuffer();
    final newBuf = StringBuffer();
    int editIndex = 0;

    for (final line in content.split('\n')) {
      final trimmed = line.trim();

      if (trimmed == '---EDIT---') {
        inEdit = true;
        inOld = false;
        inNew = false;
        oldBuf.clear();
        newBuf.clear();
        continue;
      }
      if (trimmed == '---OLD---' && inEdit) {
        inOld = true;
        inNew = false;
        oldBuf.clear();
        continue;
      }
      if (trimmed == '---NEW---' && inEdit) {
        inOld = false;
        inNew = true;
        newBuf.clear();
        continue;
      }
      if (trimmed == '---END---' && inEdit) {
        // Trim trailing newlines the parser added — a trailing \n that
        // doesn't exist in the source HTML will cause indexOf to miss.
        final oldCode = _trimTrailingNewlines(oldBuf.toString());
        final newCode = _trimTrailingNewlines(newBuf.toString());
        if (oldCode.isNotEmpty || newCode.isNotEmpty) {
          edits.add(AgentEditProposal(
            id: 'edit_${editIndex++}',
            oldCode: oldCode,
            newCode: newCode,
          ));
        }
        inEdit = false;
        inOld = false;
        inNew = false;
        continue;
      }

      if (inOld) {
        oldBuf.write(line);
        oldBuf.write('\n');
      } else if (inNew) {
        newBuf.write(line);
        newBuf.write('\n');
      }
    }

    // Close unclosed edit block at end of file
    if (inEdit) {
      final oldCode = _trimTrailingNewlines(oldBuf.toString());
      final newCode = _trimTrailingNewlines(newBuf.toString());
      if (oldCode.isNotEmpty || newCode.isNotEmpty) {
        edits.add(AgentEditProposal(
          id: 'edit_${editIndex++}',
          oldCode: oldCode,
          newCode: newCode,
        ));
      }
    }

    // Extract THINK and MESSAGE blocks
    final thinkBuf = StringBuffer();
    final messageBuf = StringBuffer();
    bool inThink = false;
    bool inMessage = false;

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed == '---THINK---') {
        inThink = true;
        inMessage = false;
        continue;
      }
      if (trimmed == '---MESSAGE---') {
        inThink = false;
        inMessage = true;
        continue;
      }
      if (trimmed == '---EDIT---' ||
          trimmed == '---OLD---' ||
          trimmed == '---NEW---' ||
          trimmed == '---END---' ||
          trimmed.startsWith('---SPEC_UPDATE---') ||
          trimmed.startsWith('---END_SPEC_UPDATE---')) {
        continue;
      }
      if (inThink) {
        thinkBuf.write(line);
        thinkBuf.write('\n');
      } else if (inMessage) {
        messageBuf.write(line);
        messageBuf.write('\n');
      }
    }

    // Clean message: prefer MESSAGE, fall back to THINK, fall back to everything minus blocks
    String cleanMessage = messageBuf.toString().trim();
    if (cleanMessage.isEmpty) {
      cleanMessage = thinkBuf.toString().trim();
    }
    if (cleanMessage.isEmpty) {
      // Strip all known block markers from raw content
      cleanMessage = content
          .replaceAll(RegExp(r'---THINK---[\s\S]*?(?=---EDIT---|---MESSAGE---|---SPEC_UPDATE---|---END_SPEC_UPDATE---|$)'), '')
          .replaceAll(RegExp(r'---EDIT---|---OLD---|---NEW---|---END---'), '')
          .replaceAll(RegExp(r'---SPEC_UPDATE---[\s\S]*?---END_SPEC_UPDATE---'), '')
          .replaceAll(RegExp(r'```html[\s\S]*?```'), '')
          .trim();
    }

    // Extract legacy HTML code block (fallback)
    final htmlMatch =
        RegExp(r'```html\s*\n(.*?)```', dotAll: true).firstMatch(content);
    final legacyHtml = htmlMatch?.group(1)?.trim();

    return PreviewAgentResult(
      message: cleanMessage,
      edits: edits,
      specUpdates: specUpdates,
      legacyModifiedHtml: legacyHtml,
    );
  }

  /// Trim trailing newline characters from parsed code blocks.
  /// The line-based parser appends \n after every line, including the last,
  /// which would cause indexOf misses against source HTML.
  String _trimTrailingNewlines(String s) {
    return s.replaceAll(RegExp(r'\n+$'), '');
  }

  /// Apply a list of accepted edits to HTML sequentially.
  ///
  /// Tries an exact match first, then falls back to a whitespace-flexible
  /// match so that minor indentation / trailing-whitespace differences
  /// don't cause every edit to fail.
  ApplyEditsResult applyEdits(
      String html, List<AgentEditProposal> acceptedEdits) {
    String result = html;
    final errors = <ApplyError>[];

    for (final edit in acceptedEdits) {
      final match = _tryMatch(result, edit.oldCode);
      if (match == null) {
        errors.add(ApplyError(
          editId: edit.id,
          message: '在代码中未找到匹配的片段，请检查缩进和空格是否一致。',
        ));
        continue;
      }
      // match.matched is the actual substring in result that we need to
      // replace (may differ from edit.oldCode when fallback was used).
      result = result.replaceFirst(match.matched, edit.newCode);
    }

    return ApplyEditsResult(
      modifiedHtml: result,
      success: errors.isEmpty,
      errors: errors,
    );
  }

  /// Result of attempting to locate [needle] inside [haystack].
  _MatchResult? _tryMatch(String haystack, String needle) {
    // 1. Exact match.
    int idx = haystack.indexOf(needle);
    if (idx != -1) return _MatchResult(needle);

    // 2. Trimmed match (handles leading / trailing whitespace drift).
    final trimmed = needle.trim();
    if (trimmed != needle) {
      idx = haystack.indexOf(trimmed);
      if (idx != -1) return _MatchResult(trimmed);
    }

    // 3. Whitespace-flexible regex: each whitespace run in needle matches
    //    any whitespace run in haystack (handles indentation / line-ending
    //    differences).
    final flexible = RegExp.escape(needle).replaceAll(RegExp(r'\s+'), r'\s+');
    final regex = RegExp(flexible);
    final match = regex.firstMatch(haystack);
    if (match != null) return _MatchResult(match.group(0)!);

    return null;
  }
}

/// Holds the actual substring found in haystack so the caller can replace
/// it reliably even when a fallback match was used.
class _MatchResult {
  final String matched;
  const _MatchResult(this.matched);
}

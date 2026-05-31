import 'deepseek_proxy.dart';
import '../../features/workspace/domain/game_spec.dart';

class PreviewChatResult {
  /// Modified HTML code, or null if the AI didn't modify the code.
  final String? modifiedHtml;

  /// AI's natural-language explanation of changes.
  final String explanation;

  /// Spec dimension updates detected: {dimKey: newValue}
  final Map<String, String> specUpdates;

  const PreviewChatResult({
    this.modifiedHtml,
    required this.explanation,
    this.specUpdates = const {},
  });
}

/// AI service for the preview-page code modification chat.
///
/// Unlike [WorkspaceAiService], this service focuses on modifying existing
/// game HTML code based on the user's natural-language requests.
class PreviewChatService {
  final AiProxy _proxy;

  PreviewChatService({AiProxy? proxy}) : _proxy = proxy ?? AiProxy();

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

    return '''你是 GameForger，一位资深独立游戏开发者。你正在帮助用户修改已经生成好的游戏 HTML 代码。

## 游戏当前设计
${lines.isEmpty ? '（暂无设定）' : lines.join('\n')}

## 你的职责
用户会提出对当前游戏的小幅度修改请求。你需要：
1. 分析用户的需求，给出修改方案的解释
2. 输出 **完整的新 HTML 代码**（在 ```html 代码块中）
3. 如果用户的修改涉及修改某个设计维度（如把"美术风格从像素风改成卡通风"），在代码块后附加结构化数据

## 修改原则
- 尽量做最小幅度的修改，不要重写整个游戏
- 保持原有的游戏架构和核心机制
- 只改动用户要求的部分
- 确保修改后的代码能正常运行（标签闭合、语法正确）
- 如果用户的要求不合理或会导致游戏无法运行，友好地解释原因

## 输出格式
先自然语言回复，解释你要做的修改。然后附上完整的新 HTML：

```html
<!DOCTYPE html>
<!-- ... 完整的修改后 HTML ... -->
</html>
```

如果用户修改了某个设计维度（玩法类型、主题、美术风格、视角、核心机制、玩家能力、目标、音乐氛围、难度），在代码块后面附加：

---SPEC_UPDATE---
dim_key: genre
new_value: 你提取的新值
---END_SPEC_UPDATE---

注意：只有当用户的请求确实改变了某个维度的定义时才附加 SPEC_UPDATE，不要过度推断。''';
  }

  /// Stream the AI response, returning the final parsed result.
  Future<PreviewChatResult> processModificationStream({
    required String currentHtml,
    required GameSpec gameSpec,
    required String userMessage,
    required List<Map<String, String>> chatHistory,
    required void Function(String fullTextSoFar) onChunk,
  }) async {
    final systemPrompt = _buildSystemPrompt(gameSpec);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user',
       'content': '这是当前游戏的完整 HTML 代码：\n\n```html\n$currentHtml\n```\n\n'},
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
      return PreviewChatResult(
        explanation: '抱歉，AI 服务暂时无法响应。请稍后重试。\n\n错误: $e',
      );
    }
  }

  PreviewChatResult _parseResponse(String content) {
    // Extract spec updates
    final specUpdates = <String, String>{};
    final specMatch = RegExp(
      r'---SPEC_UPDATE---\s*dim_key:\s*(.+?)\s*new_value:\s*(.+?)\s*---END_SPEC_UPDATE---',
      dotAll: true,
    ).firstMatch(content);
    if (specMatch != null) {
      specUpdates[specMatch.group(1)!.trim()] = specMatch.group(2)!.trim();
    }

    // Extract HTML code block
    final htmlMatch = RegExp(
      r'```html\s*\n(.*?)```',
      dotAll: true,
    ).firstMatch(content);
    final modifiedHtml = htmlMatch?.group(1)?.trim();

    // Clean explanation: remove the HTML block and spec update section
    String explanation = content;
    explanation = explanation.replaceAll(RegExp(r'```html[\s\S]*?```'), '').trim();
    explanation = explanation.replaceAll(
      RegExp(r'---SPEC_UPDATE---[\s\S]*?---END_SPEC_UPDATE---'),
      '',
    ).trim();

    return PreviewChatResult(
      modifiedHtml: modifiedHtml,
      explanation: explanation,
      specUpdates: specUpdates,
    );
  }
}

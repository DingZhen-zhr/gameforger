import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/ai/game_gen_service.dart';
import '../../../services/audio/audio_bridge.dart';
import '../../../services/storage/local_db_service.dart';
import '../../../services/supabase/game_build_service.dart';
import '../../../services/supabase/supabase_client.dart';
import '../../workspace/presentation/providers/workspace_provider.dart';
import 'providers/preview_provider.dart';
import 'widgets/code_panel.dart';
import 'widgets/asset_panel.dart';

class PreviewPage extends ConsumerStatefulWidget {
  final String projectId;

  const PreviewPage({super.key, required this.projectId});

  @override
  ConsumerState<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends ConsumerState<PreviewPage>
    with SingleTickerProviderStateMixin {
  InAppWebViewController? _webViewController;
  late TabController _tabController;
  bool _isRegenerating = false;

  // WebView load state tracking
  bool _isWebViewLoading = true;
  bool _webViewHasError = false;
  String _webViewErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(previewProvider(widget.projectId).notifier).setTab(_tabController.index);
      }
    });
    // Consume any pending HTML set by the workspace before navigation.
    // On the first visit this is a no-op ([_init] handles it); on
    // subsequent visits (reused notifier) it picks up freshly generated
    // HTML without stale-cache fallback.
    ref.read(previewProvider(widget.projectId).notifier).consumePending();
  }

  @override
  void dispose() {
    AudioBridge().dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewProvider(widget.projectId));
    final notifier = ref.read(previewProvider(widget.projectId).notifier);

    // Show loading until _init() completes (avoids building WebView with
    // placeholder HTML that gets immediately replaced).
    if (!state.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text('加载游戏中...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (state.isFullscreen) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              _buildWebView(),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white70),
                  onPressed: notifier.toggleFullscreen,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: '返回工作台',
        ),
        title: const Text('游戏预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: () => _showAudioSettings(context),
            tooltip: '音频设置',
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: notifier.toggleFullscreen,
            tooltip: '全屏',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _onShare(context, notifier),
            tooltip: '分享',
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'help') {
                _showHelpDialog(context);
              } else if (v == 'regenerate') {
                await _onRegenerate(notifier);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'regenerate',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('重新生成'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('帮助'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 3, child: _buildWebView()),
              const Divider(height: 1, color: AppTheme.outlineDark),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      color: AppTheme.surfaceDark,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.primary,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        tabs: const [
                          Tab(text: '代码', icon: Icon(Icons.code, size: 18)),
                          Tab(text: '素材', icon: Icon(Icons.image, size: 18)),
                          Tab(text: '信息', icon: Icon(Icons.info, size: 18)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          CodePanel(
                        projectId: widget.projectId,
                        onApplyCode: (newCode) {
                          ref.read(previewProvider(widget.projectId).notifier)
                              .updateCode(newCode);
                          // WebView reloads automatically via hash-based key change
                        },
                      ),
                          AssetPanel(
                            projectId: widget.projectId,
                            onApplyCode: (newCode) {
                              ref
                                  .read(previewProvider(widget.projectId)
                                      .notifier)
                                  .updateCode(newCode);
                              // WebView reloads automatically via hash-based key change
                            },
                          ),
                          _InfoTab(projectId: widget.projectId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isRegenerating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'AI 正在重新生成游戏...',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onShare(BuildContext context, PreviewNotifier notifier) {
    try {
      notifier.shareCode();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享失败: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onRegenerate(PreviewNotifier notifier) async {
    if (_isRegenerating) return;
    setState(() => _isRegenerating = true);

    try {
      final spec = ref.read(workspaceProvider(widget.projectId)).gameSpec;
      final service = GameGenService();
      final html = await service.generateGame(spec).timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw Exception(
          '游戏生成超时（3分钟），请简化游戏设定后重试。',
        ),
      );

      final buildService = GameBuildService(SupabaseManager.client);
      await buildService.saveBuild(widget.projectId, html, spec);
      await LocalDbService().cacheBuild(widget.projectId, html, spec);

      notifier.updateCode(html);
      // WebView will reload automatically via hash-based key change
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重新生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Widget _buildWebView() {
    final state = ref.watch(previewProvider(widget.projectId));
    final htmlCode = state.htmlCode;

    return Stack(
      children: [
        InAppWebView(
          key: ValueKey('preview_${htmlCode.hashCode}'),
          // Use initialData for the initial load (works reliably on iOS).
          // The htmlFilePath is only used as a fallback in _reloadWebView
          // via loadFile(assetFilePath:), which properly handles iOS
          // WKWebView file:// restrictions.
          initialData: InAppWebViewInitialData(
            data: htmlCode,
            mimeType: 'text/html',
            encoding: 'utf8',
          ),
          initialUrlRequest: null,
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            supportZoom: false,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _registerBridgeHandlers(controller);
          },
          onLoadStart: (controller, url) {
            setState(() {
              _isWebViewLoading = true;
              _webViewHasError = false;
            });
          },
          onLoadStop: (controller, url) {
            setState(() => _isWebViewLoading = false);
            _registerBridgeHandlers(controller);
          },
          onReceivedError: (controller, request, error) {
            setState(() {
              _isWebViewLoading = false;
              _webViewHasError = true;
              _webViewErrorMessage = error.description;
            });
          },
        ),
        // Thin loading progress bar at top while WebView loads
        if (_isWebViewLoading && !_webViewHasError)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primary.withValues(alpha: 0.6),
              ),
              minHeight: 2,
            ),
          ),
        // Error overlay with retry button
        if (_webViewHasError)
          Positioned.fill(
            child: GestureDetector(
              onTap: _reloadWebView,
              child: Container(
                color: AppTheme.bgDark.withValues(alpha: 0.95),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 52, color: AppTheme.error),
                        const SizedBox(height: 16),
                        const Text('预览加载失败',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          _webViewErrorMessage,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _reloadWebView,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _reloadWebView() {
    final notifier = ref.read(previewProvider(widget.projectId).notifier);
    final filePath = notifier.htmlFilePath;
    if (_webViewController != null) {
      if (filePath != null) {
        _webViewController!.loadFile(assetFilePath: filePath);
      } else {
        final htmlCode =
            ref.read(previewProvider(widget.projectId)).htmlCode;
        if (htmlCode.isNotEmpty) {
          _webViewController!.loadData(
            data: htmlCode,
            mimeType: 'text/html',
            encoding: 'utf8',
          );
        }
      }
      setState(() {
        _isWebViewLoading = true;
        _webViewHasError = false;
        _webViewErrorMessage = '';
      });
    }
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline,
                    size: 22, color: AppTheme.primary),
                const SizedBox(width: 10),
                const Text('游戏预览帮助',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _helpItem(Icons.sports_esports, '游戏操作',
                '使用键盘方向键或触摸拖动来控制游戏。部分游戏支持自动开火。'),
            _helpItem(Icons.code, '代码标签',
                '查看和编辑生成的 HTML/JS 代码。修改后点击应用即可预览效果。'),
            _helpItem(Icons.palette, '素材标签',
                '查看游戏中使用的颜色、对象和外部资源。点击色块或对象可以编辑替换，还可使用 AI 生成图片素材。'),
            _helpItem(Icons.info, '信息标签', '查看项目基本信息。'),
            _helpItem(Icons.volume_up, '音频设置',
                '右上角音符图标可以调整游戏音频设置。'),
            _helpItem(Icons.refresh, '重新生成',
                '右上角菜单选择"重新生成"，AI 将使用相同设定重新生成游戏。'),
            _helpItem(Icons.arrow_back, '返回工作台',
                '左上角返回箭头可回到工作台，修改游戏设定后再次生成。'),
            _helpItem(Icons.help_outline, '帮助',
                '右上角菜单选择"帮助"查看此说明。'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.outlineDark),
                ),
                child: const Text('知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAudioSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Row(
          children: [
            const Icon(Icons.music_note, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text('游戏音频设置',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '当前游戏的音频由 Web Audio API 驱动。\n\n'
              '音效提示：\n'
              '• 游戏中内置了音效（射击、跳跃、收集等）\n'
              '• 音效通过代码中的 audioCtx / playTone 函数生成\n'
              '• 如需背景音乐，可回到工作台修改"音乐氛围"设定\n'
              '• 素材标签页中可使用 AI 生成音频资源 URL',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                AudioBridge().stop();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已停止所有游戏音频'),
                    backgroundColor: AppTheme.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('停止所有音频'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _registerBridgeHandlers(InAppWebViewController controller) {
    // Audio bridge: game JS calls window.flutter_inappwebview.callHandler('audioPlay', url, loop)
    controller.addJavaScriptHandler(
      handlerName: 'audioPlay',
      callback: (args) {
        if (args.isNotEmpty) {
          final url = args[0] as String?;
          final loop = args.length > 1 && (args[1] == true);
          if (url != null && url.isNotEmpty) {
            AudioBridge().play(url, loop: loop);
          }
        }
      },
    );
    // Stop audio
    controller.addJavaScriptHandler(
      handlerName: 'audioStop',
      callback: (_) {
        AudioBridge().stop();
      },
    );
    // Haptic feedback
    controller.addJavaScriptHandler(
      handlerName: 'haptic',
      callback: (_) {
        AudioBridge().playTone(440, 0.1);
      },
    );

    // Inject the GameForge bridge object into the game's JS context
    controller.evaluateJavascript(source: '''
      if (!window.GameForge) {
        window.GameForge = {
          playAudio: function(url, loop) {
            window.flutter_inappwebview.callHandler('audioPlay', url, loop || false);
          },
          stopAudio: function() {
            window.flutter_inappwebview.callHandler('audioStop');
          },
          haptic: function() {
            window.flutter_inappwebview.callHandler('haptic');
          }
        };
      }
    ''');
    // Inject a fallback fix for games that get stuck on the title screen.
    // On iOS WKWebView, touchstart.preventDefault() suppresses the click
    // event needed for "tap to start".  This patch catches that edge case
    // so touching the canvas restarts the game from any non-playing state.
    controller.evaluateJavascript(source: '''
      (function(){
        var c=document.getElementById('g')||document.querySelector('canvas');
        if(!c)return;
        c.addEventListener('touchstart',function(e){
          try {
            var s=typeof state!=='undefined'?state:'';
            if((s==='title'||s==='gameOver'||s==='win')&&typeof restart==='function'){
              e.preventDefault();restart();
            }
          } catch(_) {}
        },{passive:false});
      })();
    ''');
  }
}

class _InfoTab extends ConsumerWidget {
  final String projectId;
  const _InfoTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppTheme.bgDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, '项目 ID', '${projectId.substring(0, 8)}...'),
          const SizedBox(height: 12),
          _infoRow(context, '游戏引擎', 'Canvas API'),
          const SizedBox(height: 12),
          _infoRow(context, '画面控制', '键盘方向键 / 触摸左右'),
          const SizedBox(height: 12),
          _infoRow(context, '状态', '运行中'),
          const Spacer(),
          Center(
            child: Text(
              '返回工作台可继续修改游戏创意，\n修改后再次生成将更新预览',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textPrimary)),
      ],
    );
  }
}

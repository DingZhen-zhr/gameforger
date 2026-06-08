import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmic_forge.dart';
import '../../../services/credits/credit_service.dart';

class CreditsPage extends ConsumerStatefulWidget {
  const CreditsPage({super.key});

  @override
  ConsumerState<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends ConsumerState<CreditsPage> {
  final _creditService = CreditService();
  int _balance = 0;
  List<CreditTransaction> _transactions = [];
  bool _loading = true;
  String? _error;

  static const _packages = [
    _Package('trial', '试用包', 100, 0.99),
    _Package('starter', '入门包', 500, 3.99),
    _Package('creator', '创作者包', 2000, 12.99),
    _Package('pro', '专业包', 8000, 39.99),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balance = await _creditService.getBalance();
      final transactions = await _creditService.getTransactions();
      if (mounted) {
        setState(() {
          _balance = balance;
          _transactions = transactions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchase(_Package pkg) async {
    setState(() => _loading = true);
    try {
      final result = await _creditService.purchase(pkg.id);
      if (mounted) {
        setState(() {
          _balance = result.balance;
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('购买成功！+${result.added} 点数')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('购买失败: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: StarRingLoader(label: '正在同步点数'))
              : _error != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    children: [
                      const _CreditsHeader(),
                      const SizedBox(height: 16),
                      _buildBalanceCard(),
                      const SizedBox(height: 24),
                      const ForgeSectionLabel(title: '购买点数'),
                      const SizedBox(height: 12),
                      ..._packages.map(
                        (pkg) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPackageCard(pkg),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildRulesCard(),
                      const SizedBox(height: 24),
                      _buildTransactionHistory(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return ForgeGlassCard(
      borderRadius: BorderRadius.circular(24),
      accent: AppTheme.gold,
      accentOpacity: 0.1,
      borderOpacity: 0.14,
      glow: true,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const Icon(Icons.monetization_on, size: 48, color: AppTheme.gold),
            const SizedBox(height: 12),
            Text(
              '$_balance',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text('可用点数', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(_Package pkg) {
    return ForgeGlassCard(
      borderRadius: BorderRadius.circular(20),
      accent: AppTheme.gold,
      accentOpacity: 0.055,
      borderOpacity: 0.1,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stars_rounded, color: AppTheme.gold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pkg.credits} 点数',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '\$${pkg.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _purchase(pkg),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(72, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('购买'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return ForgeGlassCard(
      borderRadius: BorderRadius.circular(20),
      accent: AppTheme.secondary,
      accentOpacity: 0.045,
      borderOpacity: 0.08,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('点数消耗说明', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const _RuleRow(Icons.chat, '文本生成/对话', '1 点 / 次'),
            const _RuleRow(Icons.palette, '图片生成', '5 点 / 次'),
            const _RuleRow(Icons.music_note, '音乐生成', '3 点 / 次'),
            const _RuleRow(Icons.settings, '游戏代码生成', '10 点 / 次'),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '交易记录',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _load,
              child: const Text('刷新', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_transactions.isEmpty)
          ForgeGlassCard(
            borderRadius: BorderRadius.circular(18),
            accent: AppTheme.gold,
            accentOpacity: 0.04,
            child: Padding(
              padding: EdgeInsets.zero,
              child: Center(
                child: Text(
                  '暂无交易记录',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          )
        else
          ..._transactions.take(10).map((t) {
            final isPositive = t.amount > 0;
            final icon = t.type == 'purchase'
                ? Icons.shopping_cart
                : t.type == 'deduction'
                ? Icons.remove_circle
                : Icons.refresh;
            return ForgeGlassCard(
              borderRadius: BorderRadius.circular(16),
              accent: isPositive ? AppTheme.gold : AppTheme.primary,
              accentOpacity: 0.035,
              borderOpacity: 0.07,
              child: ListTile(
                leading: Icon(
                  icon,
                  color: isPositive ? AppTheme.gold : AppTheme.textSecondary,
                  size: 20,
                ),
                title: Text(
                  t.description ?? t.type,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${isPositive ? '+' : ''}${t.amount}',
                  style: TextStyle(
                    color: isPositive ? AppTheme.gold : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                dense: true,
              ),
            );
          }),
      ],
    );
  }
}

class _CreditsHeader extends StatelessWidget {
  const _CreditsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ForgeIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.maybePop(context),
          tooltip: '返回',
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '点数中心',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '余额、购买和使用记录',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Package {
  final String id;
  final String name;
  final int credits;
  final double price;
  const _Package(this.id, this.name, this.credits, this.price);
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String cost;
  const _RuleRow(this.icon, this.label, this.cost);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              cost,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

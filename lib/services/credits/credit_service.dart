import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';

class CreditService {
  final SupabaseClient _client;

  CreditService({SupabaseClient? client})
      : _client = client ?? SupabaseManager.client;

  Future<int> getBalance() async {
    try {
      final response = await _client
          .from('profiles')
          .select('credits')
          .single();
      return (response['credits'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<List<CreditTransaction>> getTransactions({int limit = 20}) async {
    try {
      final response = await _client
          .from('credit_transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => CreditTransaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Deduct credits for an AI operation. Returns the new balance, or throws.
  /// Only call this when using the platform default (not user's custom key).
  Future<DeductResult> deduct(String modelType, String description) async {
    try {
      final response = await _client.functions.invoke(
        'credit-deduct',
        body: {
          'model_type': modelType,
          'description': description,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response from credit-deduct');
      }

      if (data['success'] != true) {
        throw DeductException(
          data['error'] as String? ?? 'Insufficient credits',
          data['balance'] as int? ?? 0,
          data['required'] as int? ?? 0,
        );
      }

      return DeductResult(
        balance: data['balance'] as int,
        deducted: data['deducted'] as int,
      );
    } catch (e) {
      if (e is DeductException) rethrow;
      throw DeductException('点数扣除失败: $e', 0, 0);
    }
  }

  /// Purchase a credit package. Returns the new balance.
  Future<PurchaseResult> purchase(String packageId) async {
    final response = await _client.functions.invoke(
      'credit-purchase',
      body: {'package_id': packageId},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected response from credit-purchase');
    }

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Purchase failed');
    }

    return PurchaseResult(
      balance: data['balance'] as int,
      added: data['added'] as int,
      packageName: data['package'] as String? ?? '',
    );
  }
}

class DeductResult {
  final int balance;
  final int deducted;
  const DeductResult({required this.balance, required this.deducted});
}

class DeductException implements Exception {
  final String message;
  final int balance;
  final int required;
  const DeductException(this.message, this.balance, this.required);

  @override
  String toString() => message;
}

class PurchaseResult {
  final int balance;
  final int added;
  final String packageName;
  const PurchaseResult({
    required this.balance,
    required this.added,
    required this.packageName,
  });
}

class CreditTransaction {
  final String id;
  final int amount;
  final String type;
  final String? description;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      type: json['type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

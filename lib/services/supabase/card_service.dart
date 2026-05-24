import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/workspace/domain/card_model.dart';

class CardService {
  final SupabaseClient _client;

  CardService(this._client);

  Future<List<CardModel>> getCards(String projectId) async {
    final response = await _client
        .from('cards')
        .select()
        .eq('project_id', projectId)
        .order('order_index', ascending: true);
    return (response as List)
        .map((json) => CardModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCard(CardModel card) async {
    await _client.from('cards').upsert(card.toJson()).eq('id', card.id);
  }

  Future<void> saveCards(List<CardModel> cards) async {
    if (cards.isEmpty) return;
    final jsonList = cards.map((c) => c.toJson()).toList();
    await _client.from('cards').upsert(jsonList);
  }

  Future<void> deleteCard(String id) async {
    await _client.from('cards').delete().eq('id', id);
  }

  Future<void> deleteProjectCards(String projectId) async {
    await _client.from('cards').delete().eq('project_id', projectId);
  }
}

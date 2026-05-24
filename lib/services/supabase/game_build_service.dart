import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/workspace/domain/game_spec.dart';

class GameBuildModel {
  final String id;
  final String projectId;
  final int version;
  final String htmlCode;
  final GameSpec specSnapshot;
  final DateTime createdAt;

  const GameBuildModel({
    required this.id,
    required this.projectId,
    required this.version,
    required this.htmlCode,
    required this.specSnapshot,
    required this.createdAt,
  });

  factory GameBuildModel.fromJson(Map<String, dynamic> json) {
    return GameBuildModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      version: (json['version'] as num).toInt(),
      htmlCode: json['html_code'] as String,
      specSnapshot:
          GameSpec.fromJson(json['spec_snapshot'] as Map<String, dynamic>?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'version': version,
        'html_code': htmlCode,
        'spec_snapshot': specSnapshot.toJson(),
        'created_at': createdAt.toIso8601String(),
      };
}

class GameBuildService {
  final SupabaseClient _client;

  GameBuildService(this._client);

  Future<GameBuildModel?> getLatestBuild(String projectId) async {
    final response = await _client
        .from('game_builds')
        .select()
        .eq('project_id', projectId)
        .order('version', ascending: false)
        .limit(1);
    final list = response as List;
    if (list.isEmpty) return null;
    return GameBuildModel.fromJson(list.first as Map<String, dynamic>);
  }

  Future<List<GameBuildModel>> getBuilds(String projectId) async {
    final response = await _client
        .from('game_builds')
        .select()
        .eq('project_id', projectId)
        .order('version', ascending: false);
    return (response as List)
        .map((json) => GameBuildModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> getNextVersion(String projectId) async {
    final response = await _client
        .from('game_builds')
        .select('version')
        .eq('project_id', projectId)
        .order('version', ascending: false)
        .limit(1);
    final list = response as List;
    if (list.isEmpty) return 1;
    return ((list.first as Map)['version'] as int) + 1;
  }

  Future<void> saveBuild(String projectId, String htmlCode, GameSpec spec) async {
    final version = await getNextVersion(projectId);
    final now = DateTime.now();
    await _client.from('game_builds').insert({
      'id': const Uuid().v4(),
      'project_id': projectId,
      'version': version,
      'html_code': htmlCode,
      'spec_snapshot': spec.toJson(),
      'created_at': now.toIso8601String(),
    });
    // Update project's updated_at
    await _client.from('projects').update({
      'updated_at': now.toIso8601String(),
      'status': 'generated',
    }).eq('id', projectId);
  }
}

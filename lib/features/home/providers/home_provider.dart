import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../services/supabase/supabase_client.dart';
import '../../../services/storage/local_db_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProjectModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'draft',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  ProjectModel copyWith({
    String? title,
    String? description,
    String? status,
  }) {
    return ProjectModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class HomeState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? error;
  final bool isOffline;

  const HomeState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
    this.isOffline = false,
  });

  HomeState copyWith({
    List<ProjectModel>? projects,
    bool? isLoading,
    String? error,
    bool? isOffline,
  }) {
    return HomeState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final SupabaseClient _supabase;
  final LocalDbService _localDb = LocalDbService();
  String? _userId;

  HomeNotifier(this._supabase) : super(const HomeState());

  void init(String userId) {
    _userId = userId;
    loadProjects();
  }

  Future<void> loadProjects() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final online = await _localDb.isOnline;
      if (online) {
        try {
          final response = await _supabase
              .from('projects')
              .select()
              .order('created_at', ascending: false);
          final projects = (response as List)
              .map((json) =>
                  ProjectModel.fromJson(json as Map<String, dynamic>))
              .toList();
          // Cache locally for offline access
          await _localDb.cacheProjects(projects);
          state = state.copyWith(
              projects: projects, isLoading: false, isOffline: false);
          return;
        } catch (_) {
          // Supabase failed — try local cache
        }
      }

      // Offline or Supabase error → load from local cache
      final local = await _localDb.getLocalProjects();
      state = state.copyWith(
        projects: local,
        isLoading: false,
        isOffline: !online,
        error: online ? '服务器连接失败，已加载本地缓存' : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ProjectModel?> createProject(String title) async {
    if (_userId == null) return null;
    try {
      final online = await _localDb.isOnline;
      ProjectModel? project;

      if (online) {
        try {
          final response = await _supabase
              .from('projects')
              .insert({'user_id': _userId, 'title': title})
              .select()
              .single();
          project = ProjectModel.fromJson(response);
        } catch (_) {}
      }

      // Fallback: create locally with a generated ID
      project ??= ProjectModel(
        id: const Uuid().v4(),
        userId: _userId!,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _localDb.cacheProject(project);
      state = state.copyWith(projects: [project, ...state.projects]);
      return project;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      final online = await _localDb.isOnline;
      if (online) {
        try {
          await _supabase.from('projects').delete().eq('id', id);
        } catch (_) {}
      }
      await _localDb.deleteLocalProject(id);
      state = state.copyWith(
        projects: state.projects.where((p) => p.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> renameProject(String id, String newTitle) async {
    try {
      final online = await _localDb.isOnline;
      if (online) {
        try {
          await _supabase.from('projects').update({
            'title': newTitle,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id);
        } catch (_) {}
      }
      final updated = state.projects
          .firstWhere((p) => p.id == id)
          .copyWith(title: newTitle);
      await _localDb.cacheProject(updated);
      state = state.copyWith(
        projects: state.projects.map((p) {
          return p.id == id ? updated : p;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final notifier = HomeNotifier(SupabaseManager.client);
  // Check current auth state — ref.listen only fires on changes,
  // so if auth is already authenticated we must init immediately.
  final currentAuth = ref.read(authProvider);
  ref.listen(authProvider, (_, next) {
    if (next.status == AuthStatus.authenticated && next.user != null) {
      notifier.init(next.user!.id);
    }
  });
  if (currentAuth.status == AuthStatus.authenticated && currentAuth.user != null) {
    // Defer to avoid modifying StateNotifier state during widget tree building.
    Future(() => notifier.init(currentAuth.user!.id));
  }
  return notifier;
});

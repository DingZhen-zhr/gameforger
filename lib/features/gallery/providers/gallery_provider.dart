import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase/supabase_client.dart';
import '../../home/providers/home_provider.dart';

final galleryProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final response = await SupabaseManager.client
      .from('projects')
      .select()
      .eq('status', 'generated')
      .order('updated_at', ascending: false);
  return (response as List)
      .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

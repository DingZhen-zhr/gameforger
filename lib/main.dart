import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/ai/providers/ai_provider_registry.dart';
import 'services/supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.initialize();
  await AiProviderRegistry.configureDefaults();
  runApp(const ProviderScope(child: GameForgerApp()));
}

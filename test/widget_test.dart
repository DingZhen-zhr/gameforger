import 'package:flutter_test/flutter_test.dart';
import 'package:gameforge_app/services/ai/model_router.dart';

void main() {
  testWidgets('App smoke test placeholder', (WidgetTester tester) async {
    // App requires Supabase initialization, full test to be added later
    expect(true, isTrue);
  });

  test('DeepSeek sk key is accepted and pasted whitespace is cleaned', () {
    const key = 'sk-92e7b81807cf415a95acbb6324d06c6d';
    expect(ModelRouter.sanitizeApiKey(' $key\n'), key);
    expect(ModelRouter.isValidApiKey(key), isTrue);
    expect(ModelRouter.bearerHeader(key), 'Bearer $key');
  });
}

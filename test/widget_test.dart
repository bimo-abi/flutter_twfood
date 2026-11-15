import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tw_food/main.dart';

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TWFOOD menampilkan halaman login saat token tidak tersedia',
      (WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
      if (call.method == 'read') return null;
      return null;
    });

    await tester.pumpWidget(const TwfoodApp());
    await tester.pumpAndSettle();

    expect(find.text('Login TWFOOD'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });
}

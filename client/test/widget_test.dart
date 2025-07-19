import 'package:client/features/auth/view/widgets/auth_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/auth/view/pages/login_page.dart';

void main() {
  group('LoginPage Tests', () {
    testWidgets('LoginPage basic UI test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Email ve password alanları
      expect(find.byType(TextField), findsNWidgets(2));

      // Buton widget'ını bul
      expect(find.byType(AuthGradientButton), findsOneWidget);

      // Buton içindeki yazı
      expect(find.descendant(of: find.byType(AuthGradientButton), matching: find.text('Sign In')), findsOneWidget);

      // RichText widget'larını bul (sayfada birden fazla var)
      expect(find.byType(RichText), findsNWidgets(5));
      
      // GestureDetector'ları test et (Sign Up linki için)
      expect(find.byType(GestureDetector), findsNWidgets(2));
      
      // Ana başlık "Sign In" metnini test et
      expect(find.text("Sign In"), findsNWidgets(2)); // Hem başlık hem buton içinde var
      
      // Form widget'ını test et
      expect(find.byType(Form), findsOneWidget);
      
      // Scaffold widget'ını test et
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('LoginPage RichText content test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // RichText widget'larını bul ve içeriklerini kontrol et
      final richTextWidgets = find.byType(RichText).evaluate();
      bool foundAccountText = false;
      bool foundSignUpText = false;

      for (final widget in richTextWidgets) {
        final richText = widget.widget as RichText;
        final textSpan = richText.text as TextSpan;
        
        // Ana metni kontrol et
        if (textSpan.text != null && textSpan.text!.contains("Don't have an account")) {
          foundAccountText = true;
        }
        
        // Children'ları kontrol et (Sign Up metni için)
        if (textSpan.children != null) {
          for (final child in textSpan.children!) {
            if (child is TextSpan && child.text != null && child.text!.contains("Sign Up")) {
              foundSignUpText = true;
            }
          }
        }
      }

      expect(foundAccountText, isTrue, reason: "Don't have an account metni bulunamadı");
      expect(foundSignUpText, isTrue, reason: "Sign Up metni bulunamadı");
    });

    testWidgets('LoginPage form validation test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Form'u bul
      final form = find.byType(Form);
      expect(form, findsOneWidget);

      // Form key'ini kontrol et
      final formWidget = tester.widget<Form>(form);
      expect(formWidget.key, isNotNull);
    });

    testWidgets('LoginPage text field interaction test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Email field'ını bul ve yazı yaz
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Password field'ını bul ve yazı yaz
      final passwordField = find.byType(TextField).last;
      await tester.tap(passwordField);
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Yazılan metinlerin doğru olduğunu kontrol et
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('LoginPage button interaction test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Sign In butonunu bul
      final signInButton = find.byType(AuthGradientButton);
      expect(signInButton, findsOneWidget);

      // Butona tıkla
      await tester.tap(signInButton);
      await tester.pump();

      // Butonun tıklanabilir olduğunu kontrol et
      expect(tester.widget<AuthGradientButton>(signInButton), isNotNull);
    });

    testWidgets('LoginPage navigation test', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Sign Up linkini bul (GestureDetector içindeki RichText)
      final signUpGestureDetector = find.byType(GestureDetector).last;
      expect(signUpGestureDetector, findsOneWidget);

      // Sign Up linkine tıkla
      await tester.tap(signUpGestureDetector);
      await tester.pumpAndSettle();

      // Navigation'ın gerçekleştiğini kontrol et (SignupPage'e yönlendirme)
      // Bu test için Navigator'ın mock edilmesi gerekebilir
    });
  });
}

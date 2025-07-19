import 'package:client/features/auth/Service/auth_services.dart';
import 'package:client/features/auth/view/pages/signup_page.dart';
import 'package:client/features/auth/view/widgets/auth_gradient_button.dart';
import 'package:client/features/auth/view/widgets/custom_field.dart';
import 'package:client/features/home/view/pages/home_page.dart';
import 'package:client/features/playlist/service/user_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sign In",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold
                ),
                ),
                const SizedBox(height: 30,),
                CustomField(hintText: "Email",
                controller: emailController,),
                const SizedBox(height: 15,),
                CustomField(hintText: "Password",
                controller: passwordController,
                isObscureText: true,),
                const SizedBox(height: 20,),
                AuthGradientButton(
                  buttonText: "Sign In",
                  isLoading: _isLoading,
                  onTap: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final response = await AuthService().login(
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      if (mounted) {
                        // Backend'den gelen kullanıcı bilgilerini kullan
                        String username = emailController.text.split('@')[0]; // Varsayılan olarak email'den
                        String email = emailController.text;
                        
                        // Eğer response'da kullanıcı bilgileri varsa onları kullan
                        if (response.containsKey('user')) {
                          final userData = response['user'];
                          username = userData['username'] ?? username;
                          email = userData['email'] ?? email;
                        } else if (response.containsKey('username')) {
                          username = response['username'];
                        }
                        
                        // Profil bilgilerini almaya çalış
                        try {
                          final profileData = await AuthService().getUserProfile();
                          if (profileData.containsKey('username')) {
                            username = profileData['username'];
                          }
                          if (profileData.containsKey('email')) {
                            email = profileData['email'];
                          }
                        } catch (e) {
                          print('Profil bilgileri alınamadı: $e');
                          // Hata durumunda varsayılan değerler kullanılır
                        }
                        
                        // Kullanıcı bilgilerini kaydet
                        await UserService.saveUserInfo(
                          username: username,
                          email: email,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Giriş başarılı!'),
                            backgroundColor: Color(0xFF1DB954),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 20,),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                    text: "Don't have an account? ",
                    style: Theme.of(context).textTheme.titleMedium,
                    children: const [
                      TextSpan(text: " Sign Up",
                      style: TextStyle(
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.bold
                      ))
                    ]
                  ),),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
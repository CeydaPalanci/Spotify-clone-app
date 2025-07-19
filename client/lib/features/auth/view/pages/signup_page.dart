import 'package:client/features/auth/Service/auth_services.dart';
import 'package:client/features/auth/view/widgets/auth_gradient_button.dart';
import 'package:client/features/auth/view/widgets/custom_field.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/playlist/service/user_service.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text("Sign Up",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold
                  ),
                  ),
                  const SizedBox(height: 30,),
                  CustomField(hintText: "Name",
                  controller: nameController,),
                  const SizedBox(height: 15,),
                  CustomField(hintText: "Email",
                  controller: emailController,),
                  const SizedBox(height: 15,),
                  CustomField(hintText: "Password",
                  controller: passwordController,
                  isObscureText: true,),
                  const SizedBox(height: 20,),
                  AuthGradientButton(
                    buttonText: "Sign Up",
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        await AuthService().register(
                          email: emailController.text,
                          password: passwordController.text,
                          username: nameController.text,
                          onSuccess: (message) async {
                            // Kullanıcı bilgilerini kaydet
                            await UserService.saveUserInfo(
                              username: nameController.text,
                              email: emailController.text,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Color(0xFF1DB954),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
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
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: Theme.of(context).textTheme.titleMedium,
                        children: const [
                          TextSpan(text: " Sign In",
                          style: TextStyle(
                            color: Color(0xFF1DB954),
                            fontWeight: FontWeight.bold
                          ))
                        ]
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
  }
}
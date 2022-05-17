import 'dart:convert';

import 'package:demo/common/common_snack_bar.dart';
import 'package:demo/screens/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailOrUsernameTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Log In'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Login',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _emailOrUsernameTextController,
                      focusNode: _focusEmail,
                      validator: (value) => Validator.validateUserName(
                        userName: value,
                      ),
                      decoration: InputDecoration(
                        hintText: "Email/Username",
                        errorBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _passwordTextController,
                      focusNode: _focusPassword,
                      obscureText: true,
                      validator: (value) => Validator.validatePassword(
                        password: value,
                      ),
                      decoration: InputDecoration(
                        hintText: "Password",
                        errorBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              _focusEmail.unfocus();
                              _focusPassword.unfocus();

                              if (_formKey.currentState!.validate()) {
                                _login(context);
                              }
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }


  //Login function to verify data from local storage
  void _login(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('userData');
    Map<String, dynamic> userDataMap = {};
    if (data != null) {
      userDataMap = json.decode(data);
      var email = _emailOrUsernameTextController.text.trim();
      bool emailValid = RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(email);
      if (emailValid) {
        if (userDataMap['email'] !=
            _emailOrUsernameTextController.text.trim()) {
          showSnackBar(context: context, message: 'Email does not match!');
          return;
        } else if (userDataMap['password'] != _passwordTextController.text) {
          showSnackBar(context: context, message: 'Password does not match!');
          return;
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
                  (Route<dynamic> route) => false);
        }
      } else if (userDataMap['userName'] !=
          _emailOrUsernameTextController.text.trim()) {
        showSnackBar(context: context, message: 'Username does not match!');
      } else if (userDataMap['password'] != _passwordTextController.text) {
        showSnackBar(context: context, message: 'Password does not match!');
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false);
      }
    } else {
      showSnackBar(context: context, message: 'No User Found!');
    }
  }
}

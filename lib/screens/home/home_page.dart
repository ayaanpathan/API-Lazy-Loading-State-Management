import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo/models/user_model.dart';
import 'package:demo/network/config.dart';
import 'package:dio/dio.dart';
import 'package:demo/screens/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/common_snack_bar.dart';
import '../../common/list_shimmer.dart';
import '../../utils/validator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> userDataMap = {};
  String userName = '';
  int page = 1;
  var dio = Dio();
  late UsersResponse users;
  List<User> usersList = [];

  bool _isLoading = true;
  bool _isMainListLoading = true;

  late ScrollController controller;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _focusName = FocusNode();

  @override
  void initState() {
    _getLoggedInUserData();
    _getUsers(page);
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
              onPressed: () async {
                page = 1;
                usersList.clear();
                users.data!.clear();
                setState(() {
                  _isMainListLoading = true;
                });
                Future.delayed(const Duration(milliseconds: 1500), () {
                  setState(() {
                    _getUsers(page);
                  });
                });
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddUserBottomSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      drawer: _drawer(context),
      body: _isMainListLoading ? listShimmer() : _usersList(context),
    );
  }




  /// Reusable Widgets
  // Renders the list of users from API response
  Widget _usersList(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              final user = usersList[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ListTile(
                      leading: CachedNetworkImage(
                        height: 75,
                        width: 50,
                        fit: BoxFit.cover,
                        imageUrl: user.avatar!,
                        placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                      ),
                      title: Text('${user.firstName!} ${user.lastName!}'),
                      subtitle: Text(user.email!),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _handleClick(
                            value, context, user.firstName!, user.id!),
                        itemBuilder: (BuildContext context) {
                          return {'Edit User', 'Delete User'}
                              .map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  // Drawer for home screen
  Drawer _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Hi, $userName'),
          ),
          ListTile(
            title: const Text('Log Out'),
            trailing: const Icon(Icons.logout),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }





  /// Functions
  // Log out and clear all the local storage data
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RegisterPage()),
            (Route<dynamic> route) => false);
  }

  // Handle on tap for options on 3 dot menu
  void _handleClick(String value, BuildContext context, String name, int id) {
    switch (value) {
      case 'Edit User':
        showEditUserBottomSheet(context, name, id);
        break;
      case 'Delete User':
        _showAlertDialogForDeleteUser(context, name, id);
        break;
    }
  }

  // show alert dialog for deleting a user
  void _showAlertDialogForDeleteUser(BuildContext context, String name, int id) {
    // set up the button
    Widget removeButton = TextButton(
      child: Text(
        "Delete $name",
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
      onPressed: () {
        _deleteUser(name, context, id);
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    Widget cancelButton = TextButton(
      child: const Text(
        "Go Back",
        style: TextStyle(color: Colors.green),
      ),
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete $name?"),
      content:
      const Text("Are you sure you want to delete this user permanently?"),
      actions: [removeButton, cancelButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  //bottom sheet for add user
  void showAddUserBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        focusNode: _focusName,
                        validator: (value) => Validator.validateName(
                          name: value,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter Name",
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
                                _focusName.unfocus();

                                if (_formKey.currentState!.validate()) {
                                  _addUser(
                                      _nameController.text.trim(), context);
                                }
                              },
                              child: const Text(
                                'Add User',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //bottom sheet for edit user
  void showEditUserBottomSheet(BuildContext context, String name, int id) {
    setState(() {
      _nameController.text = name;
    });
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        focusNode: _focusName,
                        validator: (value) => Validator.validateName(
                          name: value,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter Name",
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
                                _focusName.unfocus();

                                if (_formKey.currentState!.validate()) {
                                  _editUser(
                                      _nameController.text.trim(), context, id);
                                }
                              },
                              child: const Text(
                                'Edit User',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // listens to scroll update of the listview
  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      setState(() {
        _isLoading = true;
        if (_isLoading) {
          page = page + 1;
          _getUsers(page);
        }
      });
    }
  }

  // get logged in user's data from local storage
  void _getLoggedInUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('userData');
    if (data != null) {
      userDataMap = json.decode(data);
      userName = userDataMap['userName'];
      setState(() {});
    }
  }



  /// API CALLS
  // Get Users
  Future<void> _getUsers(int page) async {
    try {
      Response response = await dio.get(Config.getUsers + page.toString());
      users = UsersResponse.fromJson(json.decode(response.toString()));
      for (var user in users.data!) {
        usersList.add(user);
      }
      setState(() {
        _isLoading = false;
        _isMainListLoading = false;
      });
    } on DioError catch (e) {
      if (e.response != null) {
        Map<String, dynamic> map;
        map = json.decode(e.response.toString());
        showSnackBar(context: context, message: map['message']);
      } else {
        showSnackBar(
            context: context,
            message: 'Something went wrong, try again later.');
      }
    }
  }

  // Add User
  Future<void> _addUser(String name, BuildContext context) async {
    var formData = FormData.fromMap({'name': name, 'job': 'Demo User'});
    try {
      Response response = await dio.post(Config.addUser, data: formData);
      _nameController.clear();
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: json.decode(response.toString()).toString(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        _isLoading = false;
        _isMainListLoading = false;
      });
    } on DioError catch (e) {
      if (e.response != null) {
        Map<String, dynamic> map;
        map = json.decode(e.response.toString());
        showSnackBar(context: context, message: map['message']);
      } else {
        showSnackBar(
            context: context,
            message: 'Something went wrong, try again later.');
      }
    }
  }

  // Edit User
  Future<void> _editUser(String name, BuildContext context, int id) async {
    var formData = FormData.fromMap({'name': name, 'job': 'Demo User'});
    try {
      Response response =
          await dio.patch(Config.editUser + id.toString(), data: formData);
      _nameController.clear();
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: json.decode(response.toString()).toString(),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        _isLoading = false;
        _isMainListLoading = false;
      });
    } on DioError catch (e) {
      if (e.response != null) {
        Map<String, dynamic> map;
        map = json.decode(e.response.toString());
        showSnackBar(context: context, message: map['message']);
      } else {
        showSnackBar(
            context: context,
            message: 'Something went wrong, try again later.');
      }
    }
  }

  // Delete User
  Future<void> _deleteUser(String name, BuildContext context, int id) async {
    try {
      Response response = await dio.delete(Config.deleteUser + id.toString());
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: json.decode(response.toString()).toString(),
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        showSnackBar(
            context: context,
            message: 'Something went wrong, try again later.');
      }
    } on DioError catch (e) {
      if (e.response != null) {
        Map<String, dynamic> map;
        map = json.decode(e.response.toString());
        showSnackBar(context: context, message: map['message']);
      } else {
        showSnackBar(
            context: context,
            message: 'Something went wrong, try again later.');
      }
    }
  }
}

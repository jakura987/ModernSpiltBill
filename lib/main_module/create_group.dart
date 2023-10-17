import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../constants/palette.dart';

class CreateGroupPage extends StatefulWidget {
  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchUserController = TextEditingController();
  List<String> selectedUsers = [];
  List<String> searchResults = [];

  @override
  void initState() {
    super.initState();
    final userModel = Provider.of<UserModel>(context, listen: false);
    selectedUsers.add(userModel.userName);
  }

  void searchUser(String email) async {
    // Search users by email in the database
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    setState(() {
      searchResults = users.docs.map((doc) => doc['name'] as String).toList();
    });
  }

  void saveGroupToFirebase() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a group name.')),
      );
      return;
    }

    if (selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one member to the group.')),
      );
      return;
    }

    CollectionReference groups =
    FirebaseFirestore.instance.collection('groups');
    await groups.add({
      'groupName': _groupNameController.text,
      'peopleName': selectedUsers,
      'peopleNumber': selectedUsers.length,
    });

    Navigator.pop(context); // Optionally, navigate back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Close the current page
          },
        ),
        title: const Text(
          'Create a Group',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: saveGroupToFirebase,
            child: Text('Done', style: TextStyle(color: Palette.primaryColor)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
            Column(
            crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text('Group Name',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold,fontSize: 16)),
                TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    hintText: "Enter group name",
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Palette.primaryColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                      BorderSide(color: Palette.primaryColor, width: 2.0),
                    ),
                    contentPadding: EdgeInsets.only(top: 20.0, bottom: 0.0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            const Text('Group Members',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...selectedUsers.map((user) => ListTile(
      leading: CircleAvatar(
      backgroundColor: Palette.primaryColor,
        child: Text(
          user[0].toUpperCase(), // This will display the first letter of the user's name
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(user),
      subtitle: user == Provider.of<UserModel>(context).userName ? Text('You must be a member of this group.') : null,
      trailing: user == Provider.of<UserModel>(context).userName
          ? null
          : IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          setState(() {
            selectedUsers.remove(user);
          });
        },
      ),
    )).toList(),
                const SizedBox(height: 20),
                const Text('Add user',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Search User by Email',
                        style: TextStyle(color: Colors.black)),
                    TextField(
                      controller: _searchUserController,
                      decoration: InputDecoration(
                        hintText: "Enter email",
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Palette.primaryColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                          BorderSide(color: Palette.primaryColor, width: 2.0),
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(Icons.search, color: Palette.primaryColor),
                          onPressed: () {
                            searchUser(_searchUserController.text);
                          },
                        ),
                        contentPadding: EdgeInsets.only(top: 20.0, bottom: 0.0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: (searchResults.length * 60.0), // Assuming each ListTile is 60.0 pixels high
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final user = searchResults[index];
                      return ListTile(
                        title: Text(user),
                        trailing: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (!selectedUsers.contains(user)) {
                              setState(() {
                                selectedUsers.add(user);
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
        ),
      ),
    );
  }
}

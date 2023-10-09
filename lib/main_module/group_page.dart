import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../constants/palette.dart';
import 'create_group.dart';
import '../models/user_model.dart';
import 'group_detail_page.dart';

class GroupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      appBar: AppBar(
        title: const Text('Group', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Palette.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                FirebaseFirestore.instance.collection('groups').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong!"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data?.docs ?? [];
                  final groupsWithCurrentUser = groups.where((group) {
                    final members = group['peopleName'] as List<dynamic>;
                    return members.contains(userModel.userName);
                  }).toList();

                  return ListView.builder(
                    itemCount: groupsWithCurrentUser.length,
                    itemBuilder: (context, index) {
                      final group = groupsWithCurrentUser[index];
                      final groupName = group['groupName'] ?? "No name";
                      final memberCount =
                          group['peopleNumber'] ?? "Unknown Count";

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        margin: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 5.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          leading: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Palette.primaryColor,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(Icons.house, color: Colors.white),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(groupName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('$memberCount members',
                                  style: const TextStyle(
                                      color: Palette.secondaryColor,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GroupDetailPage(group: group)),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primaryColor,
                  // Button's background color
                  foregroundColor: Colors.white,
                  // Button's text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0), // Rounded edges
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateGroupPage()),
                  );
                },
                child: const Text(
                  'Start a new group',
                  style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16), //
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

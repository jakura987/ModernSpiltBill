import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupDetailPage extends StatelessWidget {
  final DocumentSnapshot group;

  GroupDetailPage({required this.group});

  @override
  Widget build(BuildContext context) {
    final members = group['peopleName'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(group['groupName'] ?? 'Group Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Name: ${group['groupName']}'),
            SizedBox(height: 20),
            Text('Members:'),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(members[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

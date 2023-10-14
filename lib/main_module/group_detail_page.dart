import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/palette.dart';

class GroupDetailPage extends StatelessWidget {
  final DocumentSnapshot group;

  GroupDetailPage({required this.group});

  Future<void> _confirmAndDelete(BuildContext context) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this group?"),
        actions: [
          TextButton(
            child: Text("Cancel",style: TextStyle(color: Palette.secondaryColor)),
            onPressed: () {
              Navigator.pop(context, false); // Returns false to the calling method
            },
          ),
          TextButton(
            child: Text("Delete",style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context, true); // Returns true to the calling method
            },
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('groups').doc(group.id).delete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = group['peopleName'] as List<dynamic>;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Close the current page
          },
        ),
        title: Text(
          group['groupName'] ?? 'Group Details',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmAndDelete(context), // Call the confirm and delete method when the delete icon is pressed
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Members Card
              Card(
                margin: EdgeInsets.all(15), // Add margin
                shape: RoundedRectangleBorder(
                  // Add rounded corners
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member Names',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ListView.builder(
                        itemCount: members.length,
                        shrinkWrap: true, // 自适应高度
                        physics: NeverScrollableScrollPhysics(), // 阻止内部滚动
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  // 这里，我只是使用默认的背景颜色作为示例，您可以使用 AssetImage 或 NetworkImage 来显示实际的头像。
                                  backgroundColor: Palette.primaryColor,
                                  child: Text(members[index][0], style: TextStyle(color: Colors.white)), // 显示成员名字的第一个字母作为临时头像
                                ),
                                SizedBox(width: 10), // 为头像和文本之间提供一些间距
                                Text(
                                  members[index],
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

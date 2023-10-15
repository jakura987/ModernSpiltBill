import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:SpiltBill/navigate_page.dart';
import '../constants/palette.dart';
import '../bill_created_notification.dart';
import '../dashed_line.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class CreateBill extends StatefulWidget {
  final List<String> selectedGroups;

  CreateBill({required this.selectedGroups});

  @override
  _CreateBillState createState() => _CreateBillState();
}

class PersonStatus {
  final String name;
  final bool status;
  final bool isViewed; // 添加 isViewed 属性

  PersonStatus({
    required this.name,
    this.status = false,
    this.isViewed = false, // 默认值为 false
  });

  // 将对象转换为Map以供Firebase使用
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'isViewed': isViewed, // 添加到 map 中
    };
  }
}

class _CreateBillState extends State<CreateBill> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _selectedPeople = [];
  List<String> allPeopleNames = [];
  Set<String> uniquePeopleNamesSet = Set<String>();
  DateTime? _selectedDate;
  String? _billDescription;
  String _billName = '';
  double? _billPrice;
  String _summaryText = '';
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Choose from gallery. For camera, use `ImageSource.camera`

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _checkDailyLimit() async {
    List<String> exceededUsers = [];
    double currentBillAAPP = _billPrice! / _selectedPeople.length;

    for (var person in _selectedPeople) {
      double peopleSpend = currentBillAAPP;
      QuerySnapshot billsSnapshot = await _firestore
          .collection('bills')
          .where('billDate', isEqualTo: _selectedDate)
          .get();
      for (var bill in billsSnapshot.docs) {
        var billData = bill.data() as Map<String, dynamic>;
        if (billData['peopleName'] is List &&
            (billData['peopleName'] as List).contains(person)) {
          peopleSpend += billData['AAPP']?.toDouble() ?? 0.0;
        }
      }

      // New code for fetching user data based on name
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('name', isEqualTo: person)
          .get();
      Map<String, dynamic>? userData;
      if (userQuery.docs.isNotEmpty) {
        userData = userQuery.docs.first.data() as Map<String, dynamic>;
      } else {
        print('No data found for user $person');
      }

      double dailyLimit = userData?['dailyLimit']?.toDouble() ?? 0.0;
      print("Person: $person, Spend: $peopleSpend, Limit: $dailyLimit");

      if (peopleSpend > dailyLimit) {
        exceededUsers.add(person);
      }
    }

    if (exceededUsers.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            // This makes the column only as tall as its children.
            children: exceededUsers
                .map((user) => Text('$user has exceeded daily limit.'))
                .toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: Palette.primaryColor)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => NavigatePage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _submitBill() async {
    await _checkDailyLimit();
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToFirebase(_selectedImage!);
      if (imageUrl == null) {
        final snackBar = SnackBar(content: Text('Error uploading the image. Please try again.'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }
    }

    try {
      // Prepare the data
      List<PersonStatus> peopleStatus = _selectedPeople
          .map((personName) => PersonStatus(name: personName))
          .toList();
      List<Map<String, dynamic>> peopleStatusMapList =
      peopleStatus.map((e) => e.toMap()).toList();

      Map<String, dynamic> billData = {
        'billName': _billName,
        'billDate': Timestamp.fromDate(_selectedDate!),
        'billPrice': _billPrice,
        'billDescription': _billDescription,
        'peopleNumber': _selectedPeople.length,
        'AAPP': _billPrice! / _selectedPeople.length,
        'peopleName': _selectedPeople,
        'peopleStatus': peopleStatusMapList,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      print("Preparing to submit the following data to Firestore: $billData");

      // Submit the data to Firestore
      await _firestore.collection('bills').add(billData);
      print("Data submitted successfully!");

      // Show snackbar upon successful submission
      final snackBar = SnackBar(content: Text('Submit success'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      //sendNotification
      BillCreatedNotification().dispatch(context);

      // Navigate to HomePage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => NavigatePage()),
            (route) => false, // remove all routes
      );
    } catch (e) {
      print('Error submitting bill: $e');
      final snackBar =
      SnackBar(content: Text('Error submitting bill. Please try again.'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }


  _splitBill() {
    // Check if all the necessary data is provided
    if (_billName.isEmpty ||
        _selectedDate == null ||
        _billPrice == null ||
        _selectedPeople.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please provide all the necessary data.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    int peopleNumber = _selectedPeople.length;
    double avgAmount = _billPrice! / peopleNumber;

    setState(() {
      _summaryText = """
      Bill Name: $_billName
      Date: ${_selectedDate?.toLocal().toString().split(' ')[0]}
      Bill Price: \$${_billPrice?.toStringAsFixed(2) ?? '0'}
      Description: $_billDescription
      People Number: $peopleNumber
      Average Amount Per Person: \$${avgAmount.toStringAsFixed(2)}
    """;
    });
  }

  @override
  void initState() {
    super.initState();

    print('Received Selected Groups: ${widget.selectedGroups}');

    fetchPeopleNames();
  }

  Future<void> fetchPeopleNames() async {
    for (String groupName in widget.selectedGroups) {
      // 使用 where 方法根据 groupName 字段查询
      final QuerySnapshot groupQuery = await _firestore
          .collection('groups')
          .where('groupName', isEqualTo: groupName)
          .get();

      // 检查查询结果是否包含任何文档
      if (groupQuery.docs.isEmpty) {
        print('No document found for group $groupName');
        continue;
      }

      // 获取第一个文档（因为 groupName 应该是唯一的，所以只会有一个匹配的文档）
      final DocumentSnapshot group = groupQuery.docs.first;

      final Map<String, dynamic>? groupData =
          group.data() as Map<String, dynamic>?;

      if (groupData != null && groupData.containsKey('peopleName')) {
        final List<String> peopleNames =
            List<String>.from(groupData['peopleName']);
        uniquePeopleNamesSet.addAll(peopleNames);
      } else {
        print(
            'The document $groupName exists but does not have a peopleName field or data is null.');
      }
    }

    setState(() {
      allPeopleNames = uniquePeopleNamesSet.toList();
    });
  }

  Future<void> fetchPeopleNamesFromSelectedGroups() async {
    for (String groupName in widget.selectedGroups) {
      final group = await _firestore.collection('groups').doc(groupName).get();
      final List<String> peopleNames = List<String>.from(group['peopleName']);
      allPeopleNames.addAll(peopleNames);
    }
    setState(() {}); // update UI
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      // 1. Compress the image
      print("Compressing the image...");
      final Uint8List? compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 600,
        minHeight: 600,
        quality: 88,
      );

      if (compressedImage == null) {
        print('Error compressing the image');
        return null;
      }
      print("Image compressed successfully!");

      // 2. Upload the image to Firebase Storage
      print("Uploading image to Firebase Storage...");
      String filePath = 'billImages/${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageReference = FirebaseStorage.instance.ref().child(filePath);
      final UploadTask uploadTask = storageReference.putData(compressedImage);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      if (snapshot.state != TaskState.success) {
        print('Error uploading the image to Firebase Storage');
        return null;
      }
      print("Image uploaded to Firebase Storage successfully!");

      // 3. Get the download link
      print("Getting download link from Firebase Storage...");
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Download link obtained: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print('Error in _uploadImageToFirebase: $e');
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.primaryColor,
      appBar: AppBar(
        backgroundColor: Palette.primaryColor,
        title: Text("Create your bill"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 返回到 ChooseGroup 页面
          },
        ),
        elevation: 0.0,
      ),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20.0),
            // You can adjust this value as per your need
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First Container
                Container(
                  width: 380,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 1),
                      billInformationSection(),
                      SizedBox(height: 1),
                      sharedToSection(),
                    ],
                  ),
                ),
                // Dashed Line (If you want a separator like in LoginPage)
                DashedLine(width: 380),
                // Second Container
                Container(
                  width: 380,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      billSummarySection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget billInformationSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
          ),


          // Bill Name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bill Name  *", style: TextStyle(fontSize: 16)),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Enter bill name",
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Palette.primaryColor, width: 2.0),
                    ),
                  ),
                  onChanged: (value) {
                    _billName = value;
                  },
                ),
              ],
            ),
          ),

          // Date
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date  *", style: TextStyle(fontSize: 16)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Palette.primaryColor, // 指定按钮背景颜色
                  ),
                  onPressed: () async {
                    DateTime? chosenDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: Palette.primaryColor,
                            colorScheme: ColorScheme.light(
                                primary: Palette.primaryColor),
                            buttonTheme: ButtonThemeData(
                                textTheme: ButtonTextTheme.primary),
                            backgroundColor: Palette.primaryColor,
                            // Background color for header (day, month, year)
                            dialogBackgroundColor: Colors
                                .white, // Background color for the main body of date picker
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (chosenDate != null && chosenDate != _selectedDate) {
                      setState(() {
                        _selectedDate = chosenDate;
                      });
                    }
                  },
                  child: Text(_selectedDate == null
                      ? "Select Date"
                      : "${_selectedDate!.toLocal()}".split(' ')[0]),
                ),
              ],
            ),
          ),

          // Bill Price
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bill Price  *", style: TextStyle(fontSize: 16)),
                TextField(
                  keyboardType: TextInputType.number, // Only allow numbers
                  decoration: InputDecoration(
                    hintText: "Enter bill price",
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Palette.primaryColor, width: 2.0),
                    ),
                  ),
                  onChanged: (value) {
                    _billPrice = double.tryParse(value);
                  },
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Description", style: TextStyle(fontSize: 16)),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Enter bill description",
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Palette.primaryColor, width: 2.0),
                    ),
                  ),
                  onChanged: (value) {
                    _billDescription = value;
                  },
                ),
              ],
            ),
          ),

          // select image
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                if (_selectedImage != null) ...[
                  Image.file(
                    _selectedImage!,
                    width: 150, // You can adjust the width and height as per your need
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_forever, color: Colors.grey),
                    onPressed: _removeImage,
                  )
                ] else ...[
                  ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    onPressed: _pickImage,
                    label: Text("Choose Image"),
                    style: ElevatedButton.styleFrom(
                      primary: Palette.primaryColor,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sharedToSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shared to  *",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 12),
          Container(
            height: 160.0,
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: allPeopleNames.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 0.0),
                          // 与上面的ElevatedButton的左边距相同
                          child: CircleAvatar(
                            radius: 15.0,
                            backgroundColor: Palette.primaryColor,
                            child: Text(allPeopleNames[index][0].toUpperCase(),
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Text(allPeopleNames[index],
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    value: _selectedPeople.contains(allPeopleNames[index]),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedPeople.add(allPeopleNames[index]);
                        } else {
                          _selectedPeople.remove(allPeopleNames[index]);
                        }
                      });
                    },
                    activeColor: Palette.primaryColor,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget billSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_summaryText.isNotEmpty) ...[
              Text("Bill Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(thickness: 1.5),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bill Name: $_billName", style: TextStyle(fontSize: 16)),
                  Text("Bill Price: \$${_billPrice?.toStringAsFixed(2) ?? '0'}",
                      style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Date: ${_selectedDate?.toLocal().toString().split(' ')[0]}",
                      style: TextStyle(fontSize: 16)),
                  Text("People Number: ${_selectedPeople.length}",
                      style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 12),
              Text("Description: $_billDescription", style: TextStyle(fontSize: 16)),
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedPeople.map((person) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(person, style: TextStyle(fontSize: 16)),
                        Text(
                            '\$${(_billPrice! / _selectedPeople.length).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Palette.primaryColor, // Set the button color
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Increase the button size
                  ),
                  onPressed: _submitBill,
                  child: Text(_summaryText.isEmpty ? "Next" : "Submit bill", style: TextStyle(fontSize: 18)),
                ),
              ),
            ] else ...[
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Palette.primaryColor, // Set the button color
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Increase the button size
                  ),
                  onPressed: _splitBill,
                  child: Text("Next", style: TextStyle(fontSize: 18)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

}

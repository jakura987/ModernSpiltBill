import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double? dailyLimit;
  double? weeklyLimit;
  double? monthlyLimit;

  bool isDailyEnabled = false;
  bool isWeeklyEnabled = false;
  bool isMonthlyEnabled = false;

  final _formKey = GlobalKey<FormState>();
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 设置开关默认为关闭
    isDailyEnabled = false;
    isWeeklyEnabled = false;
    isMonthlyEnabled = false;
    // 根据开关的状态来初始化TextFormField的controller的值
    _dailyController.text = isDailyEnabled ? (dailyLimit?.toString() ?? '') : '';
    _weeklyController.text = isWeeklyEnabled ? (weeklyLimit?.toString() ?? '') : '';
    _monthlyController.text = isMonthlyEnabled ? (monthlyLimit?.toString() ?? '') : '';
    // 在页面加载时调用fetchUser方法
    final userModel = Provider.of<UserModel>(context, listen: false);
    userModel.fetchUser(context).then((_) {
      // 从UserModel中获取数据并设置到本地变量
      setState(() {
        dailyLimit = userModel.dailyLimit;
        weeklyLimit = userModel.weeklyLimit;
        monthlyLimit = userModel.monthlyLimit;

        _dailyController.text = dailyLimit?.toString() ?? '';
        _weeklyController.text = weeklyLimit?.toString() ?? '';
        _monthlyController.text = monthlyLimit?.toString() ?? '';

        isDailyEnabled = dailyLimit != null;
        isWeeklyEnabled = weeklyLimit != null;
        isMonthlyEnabled = monthlyLimit != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spending Limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildLimitField('Daily Limit:', _dailyController, isDailyEnabled, (value) {
                setState(() {
                  isDailyEnabled = value;
                });
              }),
              SizedBox(height: 15),
              _buildLimitField('Weekly Limit:', _weeklyController, isWeeklyEnabled, (value) {
                setState(() {
                  isWeeklyEnabled = value;
                });
              }),
              SizedBox(height: 15),
              _buildLimitField('Monthly Limit:', _monthlyController, isMonthlyEnabled, (value) {
                setState(() {
                  isMonthlyEnabled = value;
                });
              }),
              Spacer(),
              ElevatedButton(
                onPressed: _saveLimits,
                child: Text('Save Limits'),
              )
            ],
          ),
        )
      ),
    );
  }

  Widget _buildLimitField(String label, TextEditingController controller, bool isEnabled, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Switch(
          value: isEnabled,
          onChanged: (bool newValue) {
            onChanged(newValue); // 这里调用了onChanged回调，以便更新isXXXEnabled状态
            setState(() {
              if (newValue) {
                // 如果开关被打开了
                if (label == 'Daily Limit:') {
                  controller.text = dailyLimit?.toString() ?? '';
                } else if (label == 'Weekly Limit:') {
                  controller.text = weeklyLimit?.toString() ?? '';
                } else if (label == 'Monthly Limit:') {
                  controller.text = monthlyLimit?.toString() ?? '';
                }
              }
              // 无需其他操作，因为当开关关闭时TextFormField应始终显示数据库中的值，并且由`enabled: isEnabled`确保其不可修改。
            });
          },
        ),
        Text(label, style: TextStyle(fontSize: 16)),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (isEnabled && (value == null || value.isEmpty || double.parse(value) < 0)) {
                return 'Please enter a valid amount';
              }
              return null;
            },
            decoration: InputDecoration(hintText: isEnabled ? '0.00' : ''),
            enabled: isEnabled
          ),
        ),
      ],
    );
  }


  void _saveLimits() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        dailyLimit = isDailyEnabled ? double.tryParse(_dailyController.text) : null;
        weeklyLimit = isWeeklyEnabled ? double.tryParse(_weeklyController.text) : null;
        monthlyLimit = isMonthlyEnabled ? double.tryParse(_monthlyController.text) : null;
      });

      // 调用 UserModel 中的 updateLimits 方法来更新限额
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.updateLimits(dailyLimit, weeklyLimit, monthlyLimit).then((_) {
        // 提示用户数据已经保存
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Limits updated successfully!'))
        );
      }).catchError((error) {
        // 如果出现错误，提示用户
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating limits: $error'))
        );
      });
    } else {
      // 如果验证不通过，你可以选择显示一些提示信息给用户
    }
  }





}




import 'package:flutter/material.dart';

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
          onChanged: onChanged,
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
            enabled: isEnabled,
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

      // 这里你可以保存到本地存储或Firebase
      // 保存到数据库
      Map<String, dynamic> data = {
        'dailyLimit': isDailyEnabled ? dailyLimit : null,
        'weeklyLimit': isWeeklyEnabled ? weeklyLimit : null,
        'monthlyLimit': isMonthlyEnabled ? monthlyLimit : null,
      };

      // ... 这里的代码用于保存数据到数据库
    } else {
      // 如果验证不通过，你可以选择显示一些提示信息给用户
    }
  }

}




import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            title: const Text('AI 服务商配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/provider'),
          ),
          ListTile(
            title: const Text('科目管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/subjects'),
          ),
          ListTile(
            title: const Text('提示词设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/prompts'),
          ),
          ListTile(
            title: const Text('导出当前题库'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/data'),
          ),
        ],
      ),
    );
  }
}

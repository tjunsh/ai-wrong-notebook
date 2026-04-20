import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // Appearance
          Text('外观', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('深色模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _ThemeButton(label: '系统', icon: CupertinoIcons.device_phone_portrait, isSelected: themeMode == ThemeMode.system, onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system)),
                    const SizedBox(width: 8),
                    _ThemeButton(label: '浅色', icon: CupertinoIcons.sun_max, isSelected: themeMode == ThemeMode.light, onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light)),
                    const SizedBox(width: 8),
                    _ThemeButton(label: '深色', icon: CupertinoIcons.moon, isSelected: themeMode == ThemeMode.dark, onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Notifications
          Text('提醒', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(CupertinoIcons.bell, size: 18, color: Color(0xFFF97316)),
              ),
              title: const Text('复习提醒', style: TextStyle(fontSize: 14)),
              subtitle: Text('发送待复习错题通知', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  final svc = ref.read(notificationServiceProvider);
                  await svc.checkAndNotify();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送复习提醒')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('发送', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // AI Service
          Text('AI 服务', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: <Widget>[
                _SettingsListItem(
                  icon: CupertinoIcons.sparkles,
                  iconColor: const Color(0xFF6366F1),
                  iconBg: const Color(0xFFEEF2FF),
                  title: 'AI 服务商配置',
                  onTap: () => context.go('/settings/provider'),
                ),
                Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                _SettingsListItem(
                  icon: CupertinoIcons.pencil,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFFBEB),
                  title: '提示词设置',
                  onTap: () => context.go('/settings/prompts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Content
          Text('内容', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: <Widget>[
                _SettingsListItem(
                  icon: CupertinoIcons.folder,
                  iconColor: const Color(0xFF16A34A),
                  iconBg: const Color(0xFFF0FDF4),
                  title: '科目管理',
                  onTap: () => context.go('/settings/subjects'),
                ),
                Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                _SettingsListItem(
                  icon: CupertinoIcons.tray,
                  iconColor: const Color(0xFFEA580C),
                  iconBg: const Color(0xFFFFF7ED),
                  title: '数据管理',
                  subtitle: '导入 / 导出 / 清空',
                  onTap: () => context.go('/settings/data'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  const _SettingsListItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontSize: 14)),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 22, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.label, required this.icon, required this.isSelected, required this.onTap});

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

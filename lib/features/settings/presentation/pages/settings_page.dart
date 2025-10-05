import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../../../../shared/widgets/loading_indicator.dart';

/// 个人设置中心页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('设置中心'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ExerciseProvider>(
        builder: (context, exerciseProvider, child) {
          final user = exerciseProvider.currentUser;
          
          if (user == null) {
            return const LoadingIndicator();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(user),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildSettingsSection('个人信息', [
                  _buildSettingsItem(
                    icon: Icons.edit,
                    title: '编辑资料',
                    subtitle: '修改个人信息和身体数据',
                    onTap: () => _showEditProfileDialog(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.fitness_center,
                    title: '运动目标',
                    subtitle: '设置每日运动目标',
                    onTap: () => _showGoalDialog(),
                  ),
                ]),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildSettingsSection('偏好设置', [
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: '通知设置',
                    subtitle: '管理运动提醒和通知',
                    trailing: Switch(value: true, onChanged: (v) {}),
                  ),
                  _buildSettingsItem(
                    icon: Icons.dark_mode,
                    title: '主题模式',
                    subtitle: '选择亮色或深色主题',
                    trailing: const Text('系统跟随'),
                    onTap: () => _showThemeDialog(),
                  ),
                ]),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildSettingsSection('数据管理', [
                  _buildSettingsItem(
                    icon: Icons.backup,
                    title: '数据备份',
                    subtitle: '备份运动数据到云端',
                    onTap: () => _showComingSoonDialog('数据备份'),
                  ),
                  _buildSettingsItem(
                    icon: Icons.delete_forever,
                    title: '清空数据',
                    subtitle: '删除所有运动记录（不可恢复）',
                    textColor: AppConstants.errorColor,
                    onTap: () => _showClearDataDialog(),
                  ),
                ]),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildSettingsSection('其他', [
                  _buildSettingsItem(
                    icon: Icons.help,
                    title: '帮助与反馈',
                    subtitle: '查看帮助文档或反馈问题',
                    onTap: () => _showHelpDialog(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: '关于应用',
                    subtitle: '版本 1.0.0',
                    onTap: () => _showAboutDialog(),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppConstants.primaryColor,
              child: Text(
                user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? '未设置姓名',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.age ?? 0}岁 • ${user.gender == 'male' ? '男' : '女'} • ${user.weight ?? 0}kg',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppConstants.primaryColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑资料'),
        content: const Text('个人资料编辑功能将在后续版本中提供，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置运动目标'),
        content: const Text('运动目标功能将在后续版本中提供，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: const Text('主题切换功能将在后续版本中提供，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature功能将在后续版本中提供，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text('警告：此操作将永久删除所有运动记录，且无法恢复。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
            child: const Text('确定删除'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('帮助与反馈'),
        content: const Text('如遇到问题，请联系：developer@fitness.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于健身记录应用'),
        content: const Text('版本：1.0.0\n一款基于传感器的智能健身记录应用'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
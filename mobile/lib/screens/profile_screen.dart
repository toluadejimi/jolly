// ignore: file_names
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/widget_utils.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/constants/pref_data.dart';
import 'package:giftfr/providers/auth_provider.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/login/change_password_screen.dart';
import 'package:giftfr/ui/login/login_screen.dart';

/// Profile screen: shows name, email, Change password, and Delete account.
/// Addresses App Review: "My Profile" button was unresponsive + account deletion (Guideline 5.1.1(v)).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  bool _loading = false;
  bool _deleteLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await PrefData.getUserName();
    final email = await PrefData.getUserEmail();
    if (mounted) {
      setState(() {
        _name = name ?? '';
        _email = email ?? '';
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? '
          'This cannot be undone. Your order history will be kept for our records but you will no longer have access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom( foregroundColor: Colors.red),
            child: const Text('Delete my account'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deleteLoading = true);
    final api = context.read<ApiService>();
    final res = await api.deleteAccount();
    if (!mounted) return;
    setState(() => _deleteLoading = false);

    if (res.success) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to delete account')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final theme = Theme.of(context);
    double appBarPadding = getAppBarPadding();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: Constant.getPercentSize(SizeConfig.safeBlockVertical! * 100, 2.2),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(appBarPadding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            getSpace(appBarPadding),
            Text(
              _name.isNotEmpty ? _name : 'Account',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_email.isNotEmpty) ...[
              getSpace(appBarPadding * 0.5),
              Text(
                _email,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            getSpace(appBarPadding * 2),
            ElevatedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                      if (mounted) setState(() => _loading = false);
                    },
              icon: const Icon(Icons.lock_outline, size: 20),
              label: const Text('Change password'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: appBarPadding),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
            getSpace(appBarPadding * 2),
            const Divider(),
            getSpace(appBarPadding),
            Text(
              'Delete account',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            getSpace(appBarPadding * 0.5),
            Text(
              'Permanently delete your account and all associated data. This cannot be undone.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            getSpace(appBarPadding),
            OutlinedButton.icon(
              onPressed: _deleteLoading ? null : _deleteAccount,
              icon: _deleteLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.error),
                    )
                  : Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
              label: Text(
                _deleteLoading ? 'Deleting…' : 'Delete my account',
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: appBarPadding),
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

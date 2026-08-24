// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/constants/color_data.dart';
import 'package:giftfr/constants/constant.dart';
import 'package:giftfr/constants/app_theme.dart';
import 'package:giftfr/providers/auth_provider.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/ui/home/home_screen.dart';
import 'package:giftfr/ui/login/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, this.initialTab = 0}) : super(key: key);
  final int initialTab;

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _tabFadeController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _tabFade;

  final emailSignInController = TextEditingController();
  final passSignInController = TextEditingController();
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailRegController = TextEditingController();
  final passRegController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool _showSignInPass = false;
  bool _showRegPass = false;
  bool _showConfirmPass = false;
  bool _isLoading = false;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 1);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tabFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _sheetFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    ));
    _tabFade = CurvedAnimation(
      parent: _tabFadeController,
      curve: Curves.easeOut,
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _tabFadeController.dispose();
    emailSignInController.dispose();
    passSignInController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    emailRegController.dispose();
    passRegController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _switchTab(int index) async {
    if (_selectedTab == index) return;
    await _tabFadeController.reverse();
    if (!mounted) return;
    setState(() => _selectedTab = index);
    await _tabFadeController.forward();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signIn() async {
    final username = emailSignInController.text.trim();
    final password = passSignInController.text;
    if (username.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    final result = await api.login(username: username, password: password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.data != null) {
      await auth.setFromLogin(
        apiKey: result.data!.apiKey,
        email: result.data!.user.email,
        name: result.data!.user.displayName,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      _showMessage(result.error ?? 'Login failed');
    }
  }

  Future<void> _register() async {
    final email = emailRegController.text.trim();
    final password = passRegController.text;
    final confirm = confirmPassController.text;

    if (email.isEmpty) {
      _showMessage('Please enter email');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showMessage('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    final result = await api.register(
      email: email,
      password: password,
      passwordConfirmation: confirm,
      firstname: firstnameController.text.trim().isEmpty
          ? null
          : firstnameController.text.trim(),
      lastname: lastnameController.text.trim().isEmpty
          ? null
          : lastnameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.data != null) {
      await auth.setFromLogin(
        apiKey: result.data!.apiKey,
        email: result.data!.user.email,
        name: result.data!.user.displayName,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      _showMessage(result.error ?? 'Registration failed');
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Constant.closeApp();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF7F2),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.neonOrange.withOpacity(0.22),
                        const Color(0xFFFFF7F2),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -80,
                right: -60,
                child: _GlowOrb(
                  size: 220,
                  color: AppTheme.neonOrange.withOpacity(0.18),
                ),
              ),
              Positioned(
                top: 120,
                left: -70,
                child: _GlowOrb(
                  size: 160,
                  color: AppTheme.neonOrangeLight.withOpacity(0.14),
                ),
              ),
              SafeArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
                  child: Column(
                    children: [
                      SizedBox(height: topPad > 0 ? 8 : 18),
                      FadeTransition(
                        opacity: _headerFade,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: _BrandHeader(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: FadeTransition(
                          opacity: _sheetFade,
                          child: SlideTransition(
                            position: _sheetSlide,
                            child: _AuthSheet(
                              selectedTab: _selectedTab,
                              onTabChanged: _switchTab,
                              tabFade: _tabFade,
                              isLoading: _isLoading,
                              child: _selectedTab == 0
                                  ? _SignInForm(
                                      emailController: emailSignInController,
                                      passwordController: passSignInController,
                                      showPassword: _showSignInPass,
                                      onTogglePassword: () => setState(
                                          () => _showSignInPass = !_showSignInPass),
                                      isLoading: _isLoading,
                                      onForgotPassword: () =>
                                          Constant.sendToScreen(
                                              const ForgotPasswordScreen(),
                                              context),
                                      onSubmit: _signIn,
                                      onGuest: _continueAsGuest,
                                    )
                                  : _RegisterForm(
                                      firstnameController: firstnameController,
                                      lastnameController: lastnameController,
                                      emailController: emailRegController,
                                      passwordController: passRegController,
                                      confirmController: confirmPassController,
                                      showPassword: _showRegPass,
                                      showConfirmPassword: _showConfirmPass,
                                      onTogglePassword: () => setState(
                                          () => _showRegPass = !_showRegPass),
                                      onToggleConfirmPassword: () => setState(
                                          () => _showConfirmPass =
                                              !_showConfirmPass),
                                      isLoading: _isLoading,
                                      onSubmit: _register,
                                    ),
                            ),
                          ),
                        ),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Image.asset(
            '${Constant.assetImagePath}jellyboxfr_logo.png',
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Text(
            'JollyBox',
            style: TextStyle(
              fontSize: 34,
              height: 1.05,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w800,
              color: fontBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gifting made easy',
            style: TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: greyFont,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSheet extends StatelessWidget {
  const _AuthSheet({
    required this.selectedTab,
    required this.onTabChanged,
    required this.tabFade,
    required this.isLoading,
    required this.child,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final Animation<double> tabFade;
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonOrange.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: _SegmentedTabs(
                selectedIndex: selectedTab,
                onChanged: isLoading ? (_) {} : onTabChanged,
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: tabFade,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppTheme.transition,
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SegmentTab(
                      label: 'Sign in',
                      selected: selectedIndex == 0,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  Expanded(
                    child: _SegmentTab(
                      label: 'Register',
                      selected: selectedIndex == 1,
                      onTap: () => onChanged(1),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: AppTheme.transition,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? fontBlack : greyFont,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onForgotPassword,
    required this.onSubmit,
    required this.onGuest,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: fontBlack,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to track orders and save your favourites.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: greyFont,
          ),
        ),
        const SizedBox(height: 22),
        _AuthField(
          controller: emailController,
          hint: 'Email or username',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: passwordController,
          hint: 'Password',
          obscure: !showPassword,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffix: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 22,
              color: greyFont,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : onForgotPassword,
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PrimaryButton(
          label: isLoading ? 'Signing in…' : 'Sign In',
          loading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: 'Continue as guest',
          onPressed: isLoading ? null : onGuest,
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.firstnameController,
    required this.lastnameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController firstnameController;
  final TextEditingController lastnameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create your account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: fontBlack,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join JollyBox and start sending thoughtful gifts.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: greyFont,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _AuthField(
                controller: firstnameController,
                hint: 'First name',
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AuthField(
                controller: lastnameController,
                hint: 'Last name',
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: emailController,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: passwordController,
          hint: 'Password',
          obscure: !showPassword,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.next,
          suffix: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 22,
              color: greyFont,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: confirmController,
          hint: 'Confirm password',
          obscure: !showConfirmPassword,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffix: IconButton(
            onPressed: onToggleConfirmPassword,
            icon: Icon(
              showConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 22,
              color: greyFont,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: isLoading ? 'Creating account…' : 'Create account',
          loading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscure = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscure,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 16,
        color: fontBlack,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: greyFont.withOpacity(0.75),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(prefixIcon, size: 22, color: primaryColor),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAFAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E8EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.6),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.55), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

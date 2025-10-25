import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
import 'package:collective/digital_assets/auth_bg.dart';
import 'package:collective/utils/system_ui_helper.dart';
import '../services/auth_manager.dart';
import '../services/user_profile_service.dart';
import 'package:collective/constant/colors.dart';
import 'package:collective/widgets/floating_tooltip.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collective/screens/journal_screen.dart';// Import JournalScreen

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  String email = '';
  String password = '';
  String firstName = '';
  String lastName = '';
  bool _isSubmitting = false;
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _firstNameFieldKey = GlobalKey();
  final GlobalKey _lastNameFieldKey = GlobalKey();
  late AnimationController _borderAnimController;
  late Animation<Color?> _borderColorAnim;

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _borderColorAnim = ColorTween(
      begin: AppColors.secondaryButtonBorderLight,
      end: AppColors.secondaryButtonBorderDark,
    ).animate(CurvedAnimation(
      parent: _borderAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      _isSubmitting = true;
    });
    _borderAnimController.repeat(reverse: true);
    try {
      if (isLogin) {
        await authManager.signIn(email, password);
        goToJournalScreen(context); // Force navigation after email/password login
      } else {
        if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
          FloatingTooltip.show(
            context: context,
            targetKey: _firstNameFieldKey,
            message: 'Please enter your first and last name.',
          );
          return;
        }
        await authManager.signUp(email, password, firstName.trim(), lastName.trim());
        goToJournalScreen(context); // Force navigation after registration
      }
    } on FirebaseAuthException catch (e) {
      String? emailError;
      String? passwordError;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          emailError = 'Wrong email or password.';
          passwordError = 'Wrong email or password.';
          break;
        case 'email-already-in-use':
          emailError = 'This email is already registered.';
          break;
        case 'invalid-email':
          emailError = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          passwordError = 'Password is too short.';
          break;
        case 'missing-password':
          passwordError = 'Please enter your password.';
          break;
        default:
          emailError = 'Could not authenticate. Please try again.';
      }
      if (emailError != null) {
        FloatingTooltip.show(
          context: context,
          targetKey: _emailFieldKey,
          message: emailError,
        );
      }
      if (passwordError != null) {
        FloatingTooltip.show(
          context: context,
          targetKey: _passwordFieldKey,
          message: passwordError,
        );
      }
      // Removed redundant nameError check and tooltip, as nameError is always null
    } finally {
      _borderAnimController.stop();
      setState(() => _isSubmitting = false);
    }
  }
  void goToJournalScreen(BuildContext context) {
    UserProfileService.instance.loadProfile();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => JournalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    updateSystemUiOverlay(context);
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [                  //add top padding
                  const SizedBox(height: 190), // Increased padding from 48 to 64                  // Logo and Title on same line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/logo/collective_logo.svg',
                        height: 40,
                        width: 40,
                        colorFilter: ColorFilter.mode(
                          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'collective',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 64), // Increased padding from 48 to 64
                  // Registration fields (first/last name)
                  if (!isLogin) ...[
                    const SizedBox(height: 30),
                    Container(
                      key: _firstNameFieldKey,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => firstName = val,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        cursorColor: isDark ? AppColors.cursorDark : AppColors.cursorLight,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          hintText: 'First Name',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Container(
                      key: _lastNameFieldKey,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => lastName = val,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        cursorColor: isDark ? AppColors.cursorDark : AppColors.cursorLight,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          hintText: 'Last Name',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                  // Email TextField
                  const SizedBox(height: 0), // Added padding
                  Container(
                    key: _emailFieldKey,
                    margin: const EdgeInsets.symmetric(vertical: 8), // Adjusted margin
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => email = val,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      cursorColor: isDark ? AppColors.cursorDark : AppColors.cursorLight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Added vertical padding
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ), // Theme-responsive hint
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Password TextField
                  Container(
                    key: _passwordFieldKey,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => password = val,
                      obscureText: true,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      cursorColor: isDark ? AppColors.cursorDark : AppColors.cursorLight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Added vertical padding
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ), // Theme-responsive hint
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                    // Forgot Password
                    Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 20, right: 8, top: 0, bottom: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                      // TODO: Implement forgot password logic
                      },
                      child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400, // Decreased text weight
                      ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 10),
                    // add horizontal separator with increased bottom padding
                    const Padding(
                      padding: EdgeInsets.only(top:10, bottom: 25.0), // 12 top, 40+12=52 bottom
                      child: Divider(
                      color: Color.fromARGB(255, 121, 121, 121),
                      height: 1,
                      thickness: 0.15, // Separator thickness
                      indent: 0,      // No indent, full width
                      endIndent: 0,   // No endIndent, full width
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _borderAnimController,
                      builder: (context, child) {
                        final borderColor = _isSubmitting
                            ? _borderColorAnim.value ?? (isDark ? AppColors.secondaryButtonBorderDark : AppColors.secondaryButtonBorderLight)
                            : (isDark ? AppColors.secondaryButtonBorderDark : AppColors.secondaryButtonBorderLight);
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.buttonBackgroundDark : AppColors.buttonBackgroundLight,
                            foregroundColor: isDark ? AppColors.buttonTextDark : AppColors.buttonTextLight,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 0,
                            side: BorderSide(color: borderColor, width: 1.2),
                          ),
                          onPressed: _isSubmitting ? null : submit,
                          child: SizedBox(
                            height: 28, // Match or slightly exceed the button's normal text height + padding
                            child: Center(
                              child: _isSubmitting
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      isLogin ? 'Login' : 'Register',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20), // Added padding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Text('Login with'),
                          label: SvgPicture.asset(
                            'assets/logo/google_logo.svg',
                            height: 20.0,
                            colorFilter: ColorFilter.mode(
                              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  setState(() => _isSubmitting = true);
                                  try {
                                    final credential = await authManager.signInWithGoogle();
                                    if (credential == null) {
                                      FloatingTooltip.show(
                                        context: context,
                                        targetKey: _emailFieldKey,
                                        message: 'Google sign-in cancelled.',
                                      );
                                    } else {
                                      goToJournalScreen(context);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    FloatingTooltip.show(
                                      context: context,
                                      targetKey: _emailFieldKey,
                                      message: e.message ?? 'Google sign-in failed.',
                                    );
                                  } finally {
                                    setState(() => _isSubmitting = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            backgroundColor: AppColors.secondaryButtonBackground,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isDark ? AppColors.secondaryButtonBorderDark : AppColors.secondaryButtonBorderLight,
                                width: 1.2,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Text('Login with'),
                          label: SvgPicture.asset(
                            'assets/logo/x_logo.svg',
                            height: 19.0,
                            colorFilter: ColorFilter.mode(
                              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  setState(() => _isSubmitting = true);
                                  try {
                                    final credential = await authManager.signInWithTwitter();
                                    if (credential == null) {
                                      FloatingTooltip.show(
                                        context: context,
                                        targetKey: _emailFieldKey,
                                        message: 'Twitter sign-in cancelled or failed.',
                                      );
                                    } else {
                                      goToJournalScreen(context);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    FloatingTooltip.show(
                                      context: context,
                                      targetKey: _emailFieldKey,
                                      message: e.message ?? 'Twitter sign-in failed.',
                                    );
                                  } catch (e) {
                                    FloatingTooltip.show(
                                      context: context,
                                      targetKey: _emailFieldKey,
                                      message: 'An unexpected error occurred during Twitter sign-in.',
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isSubmitting = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            backgroundColor: AppColors.secondaryButtonBackground,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isDark ? AppColors.secondaryButtonBorderDark : AppColors.secondaryButtonBorderLight,
                                width: 1.2,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(), // Added Spacer to push the following to the bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0), // Added padding to lift it from the absolute bottom
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).hintColor, // Subtler color
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => isLogin = !isLogin),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isLogin ? 'Sign up' : 'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, // Use primary color for emphasis
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Removed the old TextButton for toggling auth mode
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

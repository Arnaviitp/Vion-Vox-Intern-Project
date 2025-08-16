import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // If you haven't already initialized Firebase elsewhere, uncomment:
  // await Firebase.initializeApp();
  runApp(const MyApp());
}

//////////////////// APP ROOT ////////////////////
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vion Arogya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const LoginPage(),
    );
  }
}

//////////////////// REUSABLE GRADIENT BG ////////////////////
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0f2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

//////////////////// LOGIN PAGE ////////////////////
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      // Attempt Firebase Auth sign-in
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // check email verification
      final user = cred.user;
      await user?.reload();
      final reloadedUser = FirebaseAuth.instance.currentUser;
      if (reloadedUser != null && !reloadedUser.emailVerified) {
        // If not verified, sign out and show message with option to resend
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please verify your email before login.'),
            action: SnackBarAction(
              label: 'Resend',
              onPressed: () async {
                try {
                  await cred.user?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email resent.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ),
        );
        return;
      }

      // Fetch registration info from real-time DB to check existence & names
      final dbRef = FirebaseDatabase.instance.ref().child("registrations");
      final snapshot = await dbRef
          .orderByChild("email")
          .equalTo(emailController.text.trim())
          .get();

      if (snapshot.exists) {
        // ✅ OPEN MOOD TRACKER AFTER LOGIN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MoodTrackerPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No registration details found for this account.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Invalid credentials";
      if (e.code == 'user-not-found') message = 'No user found for this email.';
      if (e.code == 'wrong-password') message = 'Wrong password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Vion Arogya",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon:
                                Icon(Icons.email, color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter email";
                            }
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.lock, color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) => value == null || value.isEmpty
                              ? "Enter password"
                              : null,
                        ),
                        const SizedBox(height: 20),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.blue)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: loginUser,
                                child: const Text("Login",
                                    style: TextStyle(color: Colors.white)),
                              ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegistrationForm()),
                                );
                              },
                              child: const Text("Register (New User)",
                                  style: TextStyle(color: Colors.blueAccent)),
                            ),
                            TextButton(
                              onPressed: () {
                                // password reset flow
                                showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    final resetController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Reset Password'),
                                      content: TextField(
                                        controller: resetController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                            hintText: 'Enter your email'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            final email =
                                                resetController.text.trim();
                                            if (email.isEmpty) return;
                                            try {
                                              await FirebaseAuth.instance
                                                  .sendPasswordResetEmail(
                                                      email: email);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Password reset email sent.')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text('Error: $e')),
                                              );
                                            } finally {
                                              Navigator.of(ctx).pop();
                                            }
                                          },
                                          child: const Text('Send'),
                                        )
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text("Forgot?",
                                  style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////// REGISTRATION PAGE ////////////////////
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final dbRef = FirebaseDatabase.instance.ref().child("registrations");
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  // controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  String? selectedRole;
  bool isLoading = false;
  bool otpSent = false;
  String? _verificationId; // for phone verification
  bool mobileVerified = false;

  final roles = ["Student", "Counselor", "Life Coach", "Admin (Vion)"];

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    otpController.dispose();
    addressController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.dispose();
  }

  // Send OTP (phone verification).
  Future<void> sendOtp() async {
    final phone = mobileController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter mobile number first')));
      return;
    }
    setState(() {
      otpSent = false;
    });

    String phoneNumber = phone;
    if (!phoneNumber.startsWith('+')) {
      if (phoneNumber.length == 10) {
        phoneNumber = '+91$phoneNumber';
      } else {
        phoneNumber = '+$phoneNumber';
      }
    }

    final completer = Completer<void>();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          mobileVerified = true;
          setState(() {});
          completer.complete();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Phone verification failed: ${e.message}')));
          completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          setState(() => otpSent = true);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('OTP sent')));
          completer.complete();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      await completer.future;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP typed by user and mark mobileVerified
  Future<void> verifyOtpLocally() async {
    final code = otpController.text.trim();
    if (_verificationId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please send OTP first')));
      return;
    }
    if (code.length < 4) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter valid OTP')));
      return;
    }
    try {
      final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: code);
      final _ = await FirebaseAuth.instance.signInWithCredential(credential);
      mobileVerified = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone verified')));
      await FirebaseAuth.instance.signOut();
      setState(() {});
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP verify error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OTP error: $e')));
    }
  }

  // Submit registration
  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a role')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final createdUser = userCred.user!;
      await createdUser.sendEmailVerification();

      bool phoneLinked = false;
      if (mobileVerified &&
          _verificationId != null &&
          otpController.text.trim().isNotEmpty) {
        try {
          final phoneCredential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: otpController.text.trim(),
          );
          await createdUser.linkWithCredential(phoneCredential);
          phoneLinked = true;
        } on FirebaseAuthException catch (e) {
          debugPrint('Link phone error: ${e.code} ${e.message}');
        } catch (e) {
          debugPrint('Link phone other error: $e');
        }
      }

      await FirebaseDatabase.instance
          .ref()
          .child("registrations")
          .child(createdUser.uid)
          .set({
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "address": addressController.text.trim(),
        "city": cityController.text.trim(),
        "country": countryController.text.trim(),
        "email": emailController.text.trim(),
        "mobile": mobileController.text.trim(),
        "role": selectedRole,
        "phoneLinked": phoneLinked,
      });

      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Registered. Verification email sent. Please verify and then login.'),
        duration: Duration(seconds: 4),
      ));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Registration error';
      if (e.code == 'email-already-in-use') message = 'Email already in use';
      if (e.code == 'weak-password') message = 'Password too weak';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildInput(TextEditingController controller, String label,
      IconData icon, bool obscure,
      {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: const OutlineInputBorder(),
      ),
      obscureText: obscure,
      validator: (value) {
        if (value == null || value.isEmpty) return "Enter $label";
        if (label == "Email") {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) return "Enter valid email";
        }
        if (label == "Mobile") {
          final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleaned.length < 10) return "Enter valid mobile";
        }
        if (label == "Password" && value.length < 6) {
          return "Password must be >=6 chars";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Vion Arogya",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        buildInput(firstNameController, "First Name",
                            Icons.person, false),
                        const SizedBox(height: 12),
                        buildInput(lastNameController, "Last Name",
                            Icons.person_outline, false),
                        const SizedBox(height: 12),
                        buildInput(emailController, "Email", Icons.email, false,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        buildInput(
                            passwordController, "Password", Icons.lock, true),
                        const SizedBox(height: 12),
                        buildInput(
                            addressController, "Address", Icons.home, false),
                        const SizedBox(height: 12),
                        buildInput(
                            cityController, "City", Icons.location_city, false),
                        const SizedBox(height: 12),
                        buildInput(
                            countryController, "Country", Icons.flag, false),
                        const SizedBox(height: 12),
                        // Mobile + send otp
                        Row(
                          children: [
                            Expanded(
                              child: buildInput(mobileController, "Mobile",
                                  Icons.phone, false,
                                  keyboardType: TextInputType.phone),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await sendOtp();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Send OTP error: $e')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                              child: const Text('Send OTP'),
                            )
                          ],
                        ),
                        if (otpSent) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Enter OTP',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon:
                                  Icon(Icons.message, color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: verifyOtpLocally,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Verify OTP'),
                              ),
                              const SizedBox(width: 12),
                              if (mobileVerified)
                                const Text('Phone verified',
                                    style: TextStyle(
                                        color: Colors.lightGreenAccent))
                              else
                                const Text('Not verified',
                                    style:
                                        TextStyle(color: Colors.orangeAccent)),
                            ],
                          )
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          dropdownColor: const Color(0xFF203A43),
                          value: selectedRole,
                          hint: const Text("Select Role",
                              style: TextStyle(color: Colors.white70)),
                          items: roles
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedRole = v),
                          validator: (v) => v == null ? "Select a role" : null,
                        ),
                        const SizedBox(height: 18),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.blue)
                            : Column(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    onPressed: submitForm,
                                    child: const Text("Register",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const LoginPage()),
                                      );
                                    },
                                    child: const Text("Sign In (Old User)",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////// HOME PAGE (optional) ////////////////////
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String firstName = '';
  String lastName = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    try {
      final dbRef = FirebaseDatabase.instance.ref().child("registrations");
      final snapshot = await dbRef.child(user.uid).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          firstName = (data['firstName'] ?? '') as String;
          lastName = (data['lastName'] ?? '') as String;
        });
      } else {
        final snap =
            await dbRef.orderByChild('email').equalTo(user.email).get();
        if (snap.exists) {
          final map = snap.value as Map<dynamic, dynamic>;
          final firstEntry = map.entries.first.value as Map<dynamic, dynamic>;
          setState(() {
            firstName = (firstEntry['firstName'] ?? '') as String;
            lastName = (firstEntry['lastName'] ?? '') as String;
          });
        }
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? 'Welcome Student Portfolio - $firstName $lastName'
        : 'Welcome!';

    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.blue)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Vion Arogya",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MoodTrackerPage()),
                        );
                      },
                      child: const Text("Open Mood Tracker",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text("Logout",
                          style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}

//////////////////// MOOD TRACKER PAGE (NEW) ////////////////////
class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});
  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage>
    with SingleTickerProviderStateMixin {
  String? selectedMood;
  String? moodMessage;
  int streak = 0;

  // ADDED: Keys for persistence
  static const _kStreakKey = 'streak_count';
  static const _kLastDateKey = 'last_logged_date'; // yyyy-MM-dd
  String _todayStr() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now()); // ADDED

  final Map<String, String> moods = {
    "Happy 😄": "That’s awesome! 🎉 Keep spreading positivity ✨",
    "Okay 🙂": "Nice! 🌸 Stay balanced and positive 🌈",
    "Neutral 😐": "Hope something fun comes your way today 🎶",
    "Stressed 😟": "Take a deep breath 💛 You got this 💪",
    "Sad 😢": "It’s okay 💙 Remember, brighter days are coming ☀️",
    "Angry 😡": "Chill vibes only 😌 Try music or a walk 🎧",
    "Tired 😴": "You deserve rest 💤 Recharge your energy 🔋",
  };

  final Map<String, int> moodValues = {
    "Happy 😄": 6,
    "Okay 🙂": 5,
    "Neutral 😐": 4,
    "Stressed 😟": 3,
    "Sad 😢": 2,
    "Angry 😡": 1,
    "Tired 😴": 0,
  };

  final List<int?> weeklyMoods = List.filled(7, null);
  final TextEditingController noteCtrl = TextEditingController();

  // ADDED: Load streak on startup
  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  // ADDED: Persist helpers
  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStreak = prefs.getInt(_kStreakKey) ?? 0;
    final lastDate = prefs.getString(_kLastDateKey);

    if (lastDate == null) {
      setState(() => streak = savedStreak);
      return;
    }

    final today = DateTime.now();
    final last = DateTime.parse(lastDate);
    final diffDays = DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;

    if (diffDays > 1) {
      setState(() => streak = 0); // missed a day -> reset display
    } else {
      setState(() => streak = savedStreak);
    }
  }

  Future<void> _saveStreak(int newStreak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStreakKey, newStreak);
    await prefs.setString(_kLastDateKey, _todayStr());
  }

  void _selectMood(String mood) async {
    // Update mood UI immediately
    setState(() {
      selectedMood = mood;
      moodMessage = moods[mood];
      final today = DateTime.now().weekday % 7;
      weeklyMoods[today] = moodValues[mood];
    });

    // Streak logic with calendar days
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_kLastDateKey);

    int newStreak = streak;
    if (lastDate == null) {
      newStreak = 1; // first log ever
    } else {
      final last = DateTime.parse(lastDate);
      final now = DateTime.now();
      final diffDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;

      if (diffDays == 0) {
        // already logged today -> no change
      } else if (diffDays == 1) {
        newStreak = streak + 1; // consecutive day
      } else if (diffDays > 1) {
        newStreak = 1; // missed one or more days
      }
    }

    await _saveStreak(newStreak);
    if (mounted) {
      setState(() => streak = newStreak);
    }
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFF0f2027);
    const colorBg2 = Color(0xFF203a43);
    const colorBg3 = Color(0xFF2c5364);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Mood Tracker - Vion Arogya",
          style: TextStyle(
            color: Colors.lightGreenAccent, // light green title
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.lightGreenAccent),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [colorBg, colorBg2, colorBg3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final left = _buildLeftColumn();
                final right = _buildRightColumn();

                if (!isWide) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        left,
                        const SizedBox(height: 16),
                        right,
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: left),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: right),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // LEFT COLUMN: header, mood row, input, weekly chart
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Welcome back!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "How are you feeling today?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 18),

        // Mood picker row (emojis)
        _moodRow(),

        const SizedBox(height: 14),

        // “What’s on your mind?” input
        _mindInput(),

        const SizedBox(height: 24),

        // Weekly mood header
        const Text(
          "Weekly mood",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        _weeklyChart(),
      ],
    );
  }

  // RIGHT COLUMN: today's mood, encouragement, resources
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _todayMoodCard(),
        const SizedBox(height: 12),
        _encouragementCard(),
        const SizedBox(height: 12),
        _resourcesCard(),
      ],
    );
  }

  Widget _cardShell({
    required Widget child,
    List<Color>? gradientColors,
    Color? solidColor,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final BoxDecoration decoration;
    if (gradientColors != null) {
      decoration = BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: solidColor ?? Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  Widget _moodRow() {
    final moodKeys = [
      "Happy 😄",
      "Okay 🙂",
      "Neutral 😐",
      "Stressed 😟",
      "Sad 😢",
      "Tired 😴",
    ];
    return _cardShell(
      gradientColors: [Colors.grey.shade900, Colors.grey.shade800],
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: moodKeys.map((mood) {
            final isSelected = selectedMood == mood;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => _selectMood(mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Colors.pinkAccent, Colors.orangeAccent],
                          )
                        : LinearGradient(colors: [
                            Colors.grey.shade900,
                            Colors.grey.shade800
                          ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.orangeAccent.withOpacity(0.6)
                            : Colors.transparent,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Text(
                    mood.split(' ').last, // emoji only
                    style: TextStyle(
                      fontSize: 22,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _mindInput() {
    return _cardShell(
      gradientColors: [Colors.grey.shade900, Colors.grey.shade800],
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white70,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            tooltip: "Save note",
            onPressed: () {
              FocusScope.of(context).unfocus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Saved note."),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 900),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _weeklyChart() {
    return _cardShell(
      gradientColors: [Colors.grey.shade900, Colors.grey.shade800],
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 6,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  const FlLine(color: Colors.white12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    const days = ["S", "M", "T", "W", "T", "F", "S"];
                    if (value >= 0 && value < 7) {
                      return Text(
                        days[value.toInt()],
                        style: const TextStyle(color: Colors.white70),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                gradient:
                    const LinearGradient(colors: [Colors.cyan, Colors.blue]),
                spots: weeklyMoods
                    .asMap()
                    .entries
                    .where((e) => e.value != null)
                    .map((e) => FlSpot(
                          e.key.toDouble(),
                          e.value!.toDouble(),
                        ))
                    .toList(),
                barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.3),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayMoodCard() {
    final moodLabel = selectedMood?.split(' ').first ?? "Happy";
    final emoji = selectedMood?.split(' ').last ?? "😄";
    final colorPanel = selectedMood == null
        ? [Colors.teal, Colors.cyan]
        : [Colors.orangeAccent, Colors.pinkAccent];

    return _cardShell(
      gradientColors: [Colors.grey.shade900, Colors.grey.shade800],
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colorPanel),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorPanel.first.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's mood",
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  moodLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (moodMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    moodMessage!,
                    style: const TextStyle(
                        color: Colors.white70, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  "🔥 Streak: $streak days logged",
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _encouragementCard() {
    final line = moodMessage ?? "You got this! Keep going!";
    return _cardShell(
      gradientColors: const [Colors.deepPurple, Colors.indigo],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourcesCard() {
    return _cardShell(
      gradientColors: [Colors.grey.shade900, Colors.grey.shade800],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resources",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _resourceTile("Meditation", Icons.self_improvement, () {}),
          const Divider(color: Colors.white12, height: 1),
          // CHANGED: Open CounsellorPage on tap
          _resourceTile("Counselor", Icons.support_agent, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CounsellorPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _resourceTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      dense: true,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
    );
  }
}

// --------- Simple Counsellor Page (matches theme) ----------
class CounsellorPage extends StatelessWidget {
  const CounsellorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Choose a counsellor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Find a counsellor that suits your needs",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: const [
                      _CounsellorTile(
                        name: "Alex Johnson",
                        role: "Counsellor",
                        price: "\$50/session",
                        avatarColor: Colors.blueAccent,
                      ),
                      SizedBox(height: 12),
                      _CounsellorTile(
                        name: "Jamie Anderson",
                        role: "Counsellor",
                        price: "\$50/session",
                        avatarColor: Colors.teal,
                      ),
                      SizedBox(height: 12),
                      _CounsellorTile(
                        name: "Taylor Davis",
                        role: "Counsellor",
                        price: "\$50/session",
                        avatarColor: Colors.purpleAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounsellorTile extends StatelessWidget {
  final String name;
  final String role;
  final String price;
  final Color avatarColor;

  const _CounsellorTile({
    required this.name,
    required this.role,
    required this.price,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selected $name")),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: avatarColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

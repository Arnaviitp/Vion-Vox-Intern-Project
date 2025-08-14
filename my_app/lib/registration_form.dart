// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
        // Navigate to HomePage and pass UID (we will fetch names there)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // If no registration entry found, still allow access? previously code let it through.
        // For stricter flow, show error. We'll show invalid credentials here.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No registration details found for this account.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Friendly error messages for common cases
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
                                // password reset flow: open dialog to send reset email
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
    super.dispose();
  }

  // Send OTP (phone verification). This uses FirebaseAuth.verifyPhoneNumber
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

    // Ensure phone includes country code — for demonstration, assume user enters full +91... or we prefix +91 if 10 digits
    String phoneNumber = phone;
    if (!phoneNumber.startsWith('+')) {
      // naive prefix if 10-digit
      if (phoneNumber.length == 10) {
        phoneNumber = '+91$phoneNumber';
      } else {
        // let Firebase process as-is
        phoneNumber = '+$phoneNumber';
      }
    }

    final completer = Completer<void>();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification on some devices
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
          // timed out: user must enter OTP
        },
      );

      await completer.future;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP typed by user and mark mobileVerified (we will link later)
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
      // Try to sign in with credential temporarily to validate OTP, then sign out to restore flow.
      // This step is just to validate OTP correctness and avoid linking complexities if user isn't created yet.
      final _ = await FirebaseAuth.instance.signInWithCredential(credential);
      // If success, mark verified and then sign out to let registration create the intended user.
      mobileVerified = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone verified')));
      // if this temporary sign-in changed currentUser, sign out now (we want to create user with email/password after)
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

  // Submit registration: create user, send email verification, link phone (if verified), save to DB, redirect to login
  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a role')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create user with email/password
      final userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final createdUser = userCred.user!;
      // send email verification
      await createdUser.sendEmailVerification();

      // If mobile was verified by OTP earlier (we used temporary sign-in to check OTP),
      // we can attempt to link phone credential now using the verification id + otp.
      bool phoneLinked = false;
      if (mobileVerified &&
          _verificationId != null &&
          otpController.text.trim().isNotEmpty) {
        try {
          final phoneCredential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: otpController.text.trim(),
          );
          // Link with created user
          await createdUser.linkWithCredential(phoneCredential);
          phoneLinked = true;
        } on FirebaseAuthException catch (e) {
          // linking might fail if credential already used — ignore but show message
          debugPrint('Link phone error: ${e.code} ${e.message}');
        } catch (e) {
          debugPrint('Link phone other error: $e');
        }
      }

      // Save user details in DB under UID
      await dbRef.child(createdUser.uid).set({
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "mobile": mobileController.text.trim(),
        "role": selectedRole,
        "phoneLinked": phoneLinked,
      });

      // Sign out the newly created user to require email verification before login
      await FirebaseAuth.instance.signOut();

      // Seamless transition to login page with a message asking to verify email
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
                                  // >>> NEW BUTTON ADDED — works and routes to LoginPage <<<
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

//////////////////// HOME PAGE ////////////////////
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
      // If no current user (signed out), try to require login
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
        // fallback: try to search by email
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

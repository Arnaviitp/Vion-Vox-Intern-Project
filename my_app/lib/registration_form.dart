import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final dbRef = FirebaseDatabase.instance.ref().child("registrations");

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  String? selectedRole;
  bool isLoading = false;

  final List<String> roles = [
    "Student",
    "Counselor",
    "Life Coach",
    "Admin (Vion)"
  ];

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate() && selectedRole != null) {
      setState(() => isLoading = true);

      try {
        await dbRef.push().set({
          "firstName": firstNameController.text.trim(),
          "lastName": lastNameController.text.trim(),
          "email": emailController.text.trim(),
          "mobile": mobileController.text.trim(),
          "address": addressController.text.trim(),
          "city": cityController.text.trim(),
          "country": countryController.text.trim(),
          "role": selectedRole,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );
        _formKey.currentState!.reset();
        setState(() => selectedRole = null);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Registration Form"),
          backgroundColor: Colors.purple),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: "First Name"),
                validator: (value) =>
                    value!.isEmpty ? "Enter first name" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: "Last Name"),
                validator: (value) => value!.isEmpty ? "Enter last name" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email ID"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? "Enter email" : null,
              ),
              TextFormField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: "Mobile Number"),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? "Enter mobile number" : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Enter address" : null,
              ),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: "City"),
                validator: (value) => value!.isEmpty ? "Enter city" : null,
              ),
              TextFormField(
                controller: countryController,
                decoration: const InputDecoration(labelText: "Country"),
                validator: (value) => value!.isEmpty ? "Enter country" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                hint: const Text("Select Role"),
                items: roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) => setState(() => selectedRole = value),
                validator: (value) => value == null ? "Select a role" : null,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submitForm,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple),
                      child: const Text("Register"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

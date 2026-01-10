import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // Import the package
import 'package:new_packers_application/lib/constant/app_color.dart';
import 'package:new_packers_application/lib/models/app_policy_model.dart';

class AppInfoScreen extends StatelessWidget {
  final PolicyItem policyItem;

  const AppInfoScreen({super.key, required this.policyItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          policyItem.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColor.darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView to prevent overflow
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        // Use the Html widget to render the content
        child: Html(
          data: policyItem.content, // Your HTML content string
          style: {
            // You can style all tags, like p for paragraph
            "body": Style(
              fontSize: FontSize(16.0),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.normal,
              color: AppColor.darkBlue,
            ),
            // Style for links
            "a": Style(
              color: Colors.blue,
              textDecoration: TextDecoration.none,
            ),
          },
        ),
      ),
    );
  }
}

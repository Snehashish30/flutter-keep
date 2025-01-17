
import 'package:flt_keep/api/local_auth_api.dart';
import 'package:flt_keep/main.dart';
//import 'package:fingerprint_auth_example/page/home_page.dart';
import 'package:flt_keep/screens.dart' show HomeScreen;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FingerprintPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Flutter Keep'),
      centerTitle: true,
    ),
    body: Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildAvailability(context),
            SizedBox(height: 24),
            buildAuthenticate(context),
          ],
        ),
      ),
    ),
  );

  Widget buildAvailability(BuildContext context) => buildButton(
    text: 'Check Availability',
    icon: Icons.event_available,
    onClicked: () async {
      final isAvailable = await LocalAuthApi.hasBiometrics();
      final biometrics = await LocalAuthApi.getBiometrics();

      final hasFingerprint = biometrics.contains(BiometricType.fingerprint);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Availability'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildText('Biometrics', isAvailable),
              buildText('Fingerprint', hasFingerprint),
            ],
          ),
        ),
      );
    },
  );

  Widget buildText(String text, bool checked) => Container(
    margin: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        checked
            ? Icon(Icons.check, color: Colors.green, size: 24)
            : Icon(Icons.close, color: Colors.red, size: 24),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 24)),
      ],
    ),
  );

  Widget buildAuthenticate(BuildContext context) => buildButton(
    text: 'Authenticate',
    icon: Icons.lock_open,
    onClicked: () async {
      final isAuthenticated = await LocalAuthApi.authenticate();

      if (isAuthenticated) {
        User user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection("appUsers").doc(user.uid).update({
          'lastLoginTime': DateTime.now(),
          'currentStatus' : 'Logged In'
        });
        //Navigator.pop(context, true);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    },
  );

  Widget buildButton({
    @required String text,
    @required IconData icon,
    @required VoidCallback onClicked,
  }) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(50),
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          text,
          style: TextStyle(fontSize: 20),
        ),
        onPressed: onClicked,
      );
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryBlue = Color(0xFF3563E9);
  static const Color darkText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in again.'),
        ),
      );
    }

    final email = user.email ?? 'No email available';

    final displayName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : 'DoseMate User';

    final initial = displayName
            .trim()
            .isNotEmpty
        ? displayName
            .trim()
            .substring(0, 1)
            .toUpperCase()
        : 'D';

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: darkText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Profile',
          style: TextStyle(
            color: darkText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          20,
          24,
          30,
        ),
        child: Column(
          children: [
            // PROFILE HEADER
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF1FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Text(
              displayName,
              style: const TextStyle(
                color: darkText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 35),

            // ACCOUNT
            _sectionTitle('Account'),

            const SizedBox(height: 10),

            _profileTile(
              icon: Icons.person_outline_rounded,
              title: 'Personal information',
              subtitle: 'Manage your account details',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Personal information coming soon.',
                    ),
                  ),
                );
              },
            ),

            _profileTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Manage medication reminders',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notification settings coming soon.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            _sectionTitle('Support'),

            const SizedBox(height: 10),

            _profileTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & support',
              subtitle: 'Get help using DoseMate',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Help & support coming soon.',
                    ),
                  ),
                );
              },
            ),

            _profileTile(
              icon: Icons.info_outline_rounded,
              title: 'About DoseMate',
              subtitle: 'Version 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'DoseMate',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.medication_rounded,
                    color: primaryBlue,
                    size: 35,
                  ),
                  children: const [
                    Text(
                      'Your simple medication reminder companion.',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),

            // SIGN OUT
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(
                  Icons.logout_rounded,
                ),
                label: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(
                    color: Color(0xFFFFB4B4),
                  ),
                  backgroundColor:
                      const Color(0xFFFFF6F6),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        onTap: onTap,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 5,
        ),

        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF1FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: primaryBlue,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            color: darkText,
            fontWeight: FontWeight.w700,
          ),
        ),

        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 12,
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: secondaryText,
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'Are you sure you want to sign out of DoseMate?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    // Your auth flow should normally redirect
    // automatically based on FirebaseAuth state.
  }
}
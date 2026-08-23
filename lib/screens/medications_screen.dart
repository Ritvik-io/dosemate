import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_medicine_screen.dart';
import 'home_screen.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  static const Color primaryBlue = Color(0xFF3563E9);
  static const Color darkText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color lightBlue = Color(0xFFF1F6FF);
  static const Color borderColor = Color(0xFFDCE5F5);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in again.',
            style: TextStyle(
              color: secondaryText,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final medicationsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),

      // ============================================================
      // APP BAR
      // ============================================================

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

        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'DOSE',
                style: TextStyle(
                  color: darkText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'MATE',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: medicationsQuery.snapshots(),

        builder: (context, snapshot) {
          // ERROR
          if (snapshot.hasError) {
            return _errorState();
          }

          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // EMPTY
          if (docs.isEmpty) {
            return _emptyState(context);
          }

          // MEDICATION LIST
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              25,
              20,
              35,
            ),
            children: [
              const Text(
                'Your Medications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                '${docs.length} medication${docs.length == 1 ? '' : 's'} saved',
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 22),

              ...docs.map(
                (doc) => MedicationCard(
                  doc: doc,
                ),
              ),

              const SizedBox(height: 10),

              _addMedicineButton(context),
            ],
          );
        },
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _bottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                context: context,
                icon: Icons.home_rounded,
                label: 'Home',
                selected: false,
              ),

              _navItem(
                context: context,
                icon: Icons.medication_rounded,
                label: 'Medications',
                selected: true,
              ),

              _navItem(
                context: context,
                icon: Icons.history_rounded,
                label: 'History',
                selected: false,
              ),

              _navItem(
                context: context,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // NAV ITEM
  // ================================================================

  Widget _navItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        // HOME
        if (label == 'Home') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
            (route) => false,
          );
          return;
        }

        // MEDICATIONS
        if (label == 'Medications') {
          return;
        }

        // HISTORY / PROFILE
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label will be added next.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },

      behavior: HitTestBehavior.opaque,

      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 27,
              color: selected
                  ? primaryBlue
                  : const Color(0xFF94A3B8),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? primaryBlue
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 65,
              color: Color(0xFFCBD5E1),
            ),

            SizedBox(height: 18),

            Text(
              'Could not load medications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 95,
              height: 95,
              decoration: const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 48,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'No medications yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add your first medication to start managing your doses.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
              ),
            ),

            const SizedBox(height: 28),

            _addMedicineButton(context),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ADD MEDICINE BUTTON
  // ================================================================

  Widget _addMedicineButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
            ),
          );
        },

        icon: const Icon(
          Icons.add_rounded,
          size: 25,
        ),

        label: const Text(
          'Add medicine',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryBlue.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// MEDICATION CARD
// ==================================================================

class MedicationCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;

  const MedicationCard({
    super.key,
    required this.doc,
  });

  static const Color primaryBlue = Color(0xFF3563E9);
  static const Color darkText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color lightBlue = Color(0xFFF1F6FF);
  static const Color borderColor = Color(0xFFDCE5F5);

  @override
  Widget build(BuildContext context) {
    final data = doc.data();

    final String name =
        data?['name']?.toString() ?? 'Unknown medication';

    final String dosage =
        data?['dosage']?.toString() ?? '';

    final String unit =
        data?['unit']?.toString() ?? '';

    final String form =
        data?['form']?.toString() ?? 'Pill';

    final String frequency =
        data?['frequency']?.toString() ?? 'Daily';

    final List<String> times =
        List<String>.from(data?['times'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: borderColor,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: [
          // ========================================================
          // TOP ROW
          // ========================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,

                decoration: const BoxDecoration(
                  color: lightBlue,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  _getMedicationIcon(form),
                  color: primaryBlue,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '$dosage $unit • $form',

                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // THREE DOT MENU
              // ==================================================

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: secondaryText,
                ),

                onSelected: (value) {
                  if (value == 'edit') {
                    _editMedication(
                      context,
                      doc,
                    );
                  }

                  if (value == 'delete') {
                    _deleteMedication(
                      context,
                      doc,
                      name,
                    );
                  }
                },

                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'edit',

                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                          ),

                          SizedBox(width: 10),

                          Text(
                            'Edit Medication',
                          ),
                        ],
                      ),
                    ),

                    PopupMenuItem<String>(
                      value: 'delete',

                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.red,
                          ),

                          SizedBox(width: 10),

                          Text(
                            'Delete Medication',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ========================================================
          // INFORMATION CHIPS
          // ========================================================

          Align(
            alignment: Alignment.centerLeft,

            child: Wrap(
              spacing: 7,
              runSpacing: 7,

              children: [
                _infoChip(
                  Icons.repeat_rounded,
                  frequency,
                ),

                ...times.map(
                  (time) => _infoChip(
                    Icons.access_time_rounded,
                    time,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFO CHIP
  // ================================================================

  Widget _infoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(9),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 14,
            color: secondaryText,
          ),

          const SizedBox(width: 5),

          Text(
            text,

            style: const TextStyle(
              fontSize: 11,
              color: secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MEDICATION ICON
  // ================================================================

  IconData _getMedicationIcon(String form) {
    switch (form.toLowerCase()) {
      case 'liquid':
        return Icons.local_drink_outlined;

      case 'inhaler':
        return Icons.air_rounded;

      default:
        return Icons.medication_rounded;
    }
  }

  // ================================================================
  // EDIT MEDICATION
  // ================================================================

  Future<void> _editMedication(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          medicationDoc: doc,
        ),
      ),
    );
  }

  // ================================================================
  // DELETE MEDICATION
  // ================================================================

  Future<void> _deleteMedication(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete medication?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          content: Text(
            'Are you sure you want to delete $name?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await doc.reference.delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medication deleted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete medication.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
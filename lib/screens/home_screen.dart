import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_medicine_screen.dart';
import 'medications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const Color primaryBlue = Color(0xFF3563E9);
  static const Color darkText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color lightBlue = Color(0xFFF1F6FF);

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
      backgroundColor: Colors.white,

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: Column(
          children: [
            // ========================================================
            // HEADER
            // ========================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                18,
                24,
                16,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'DOSE',
                          style: TextStyle(
                            color: darkText,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: 'MATE',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF1FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: darkText,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // ========================================================
            // FIRESTORE CONTENT
            // ========================================================

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: medicationsQuery.snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'Could not load medications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryBlue,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      25,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // GREETING
                        // ==================================================

                        const Text(
                          'Good morning, user 👋',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: darkText,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _formatCurrentDate(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // NEXT DOSE
                        // ==================================================

                        if (docs.isNotEmpty)
                          _nextDoseCard(docs)
                        else
                          _emptyNextDoseCard(),

                        const SizedBox(height: 30),

                        // ==================================================
                        // TODAY'S MEDICATION HEADER
                        // ==================================================

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's Medication",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: darkText,
                              ),
                            ),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MedicationsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'View all  ›',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ==================================================
                        // MEDICATION LIST
                        // ==================================================

                        if (docs.isEmpty)
                          _emptyMedicationState()
                        else
                          ...docs.take(3).map(
                            (doc) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 14,
                                ),
                                child:
                                    _homeMedicationCard(doc),
                              );
                            },
                          ),

                        const SizedBox(height: 8),

                        // ==================================================
                        // ADD MEDICINE BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 82,
                          child: OutlinedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddMedicineScreen(),
                                ),
                              );
                            },
                            style:
                                OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFB9D0FF),
                                width: 1.5,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration:
                                      const BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 29,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                const Text(
                                  'Add medicine',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ==============================================================
      // BOTTOM NAVIGATION
      // ==============================================================

      bottomNavigationBar: Container(
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
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),

                _navItem(
                  icon: Icons.medication_rounded,
                  label: 'Medications',
                  index: 1,
                ),

                _navItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  index: 2,
                ),

                _navItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // NEXT DOSE CARD
  // ================================================================

  Widget _nextDoseCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final nextDose = _findNextDose(docs);

    if (nextDose == null) {
      return _emptyNextDoseCard();
    }

    final medicineName =
        nextDose['name'] ?? 'Medication';

    final dosage =
        nextDose['dosage'] ?? '';

    final unit =
        nextDose['unit'] ?? '';

    final time =
        nextDose['time'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD6E5FF),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medicine icon
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 38,
              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 18),

          // Dose information
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Dose',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$medicineName $dosage $unit',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                const Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 17,
                      color: secondaryText,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Scheduled time',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  time,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Arrow
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: darkText,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HOME MEDICATION CARD
  // ================================================================

 Widget _homeMedicationCard(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();

  final name =
      data['name']?.toString() ?? 'Unknown medication';

  final dosage =
      data['dosage']?.toString() ?? '';

  final unit =
      data['unit']?.toString() ?? '';

  final form =
      data['form']?.toString() ?? 'Pill';

  final times = List<String>.from(
    data['times'] ?? [],
  );

  final firstTime =
      times.isNotEmpty ? times.first : 'No time';

  // ------------------------------------------------------------
  // STATUS FOR TODAY
  // ------------------------------------------------------------

  final today = DateTime.now();

  final dateKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final statusKey = '${dateKey}_$firstTime';

  final doseStatus =
      Map<String, dynamic>.from(
    data['doseStatus'] ?? {},
  );

  final status =
      doseStatus[statusKey]?.toString() ?? 'upcoming';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0xFFE2E8F0),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // TOP
        // ========================================================

        Row(
          children: [
            // Blue accent
            Container(
              width: 5,
              height: 82,
              decoration: BoxDecoration(
                color: status == 'taken'
                    ? const Color(0xFF22A865)
                    : status == 'skipped'
                        ? Colors.orange
                        : primaryBlue,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 14),

            // Medicine icon
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: status == 'taken'
                    ? const Color(0xFFE9F9F0)
                    : status == 'skipped'
                        ? const Color(0xFFFFF4E5)
                        : const Color(0xFFEAF1FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getMedicationIcon(form),
                color: status == 'taken'
                    ? const Color(0xFF22A865)
                    : status == 'skipped'
                        ? Colors.orange
                        : primaryBlue,
                size: 32,
              ),
            ),

            const SizedBox(width: 15),

            // Medicine information
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
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
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF3F6FA),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 17,
                          color: secondaryText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          firstTime,
                          style:
                              const TextStyle(
                            color: darkText,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // ========================================================
        // STATUS
        // ========================================================

        if (status == 'upcoming')
          Row(
            children: [
              // TAKEN
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _updateDoseStatus(
                      doc,
                      firstTime,
                      'taken',
                    );
                  },
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Taken',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF22A865),
                    side: const BorderSide(
                      color: Color(0xFF9DDBBA),
                    ),
                    backgroundColor:
                        const Color(0xFFF3FCF7),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // SKIP
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _updateDoseStatus(
                      doc,
                      firstTime,
                      'skipped',
                    );
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Skip',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.orange,
                    side: const BorderSide(
                      color: Color(0xFFF2C48A),
                    ),
                    backgroundColor:
                        const Color(0xFFFFFAF2),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // ======================================================
          // ALREADY TAKEN / SKIPPED
          // ======================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: status == 'taken'
                  ? const Color(0xFFE9F9F0)
                  : const Color(0xFFFFF4E5),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'taken'
                      ? Icons.check_circle_rounded
                      : Icons
                          .remove_circle_outline_rounded,
                  size: 20,
                  color: status == 'taken'
                      ? const Color(0xFF22A865)
                      : Colors.orange,
                ),

                const SizedBox(width: 7),

                Text(
                  status == 'taken'
                      ? 'Taken'
                      : 'Skipped',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color: status == 'taken'
                        ? const Color(0xFF22A865)
                        : Colors.orange,
                  ),
                ),

                const Spacer(),

                // Allow changing status
                GestureDetector(
                  onTap: () {
                    _updateDoseStatus(
                      doc,
                      firstTime,
                      'upcoming',
                    );
                  },
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color: status == 'taken'
                          ? const Color(0xFF22A865)
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
Future<void> _updateDoseStatus(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  String time,
  String status,
) async {
  final now = DateTime.now();

  final dateKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final statusKey = '${dateKey}_$time';

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .doc(doc.id)
        .update({
      'doseStatus.$statusKey': status,
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'taken'
              ? 'Dose marked as taken ✓'
              : status == 'skipped'
                  ? 'Dose skipped'
                  : 'Dose marked as upcoming',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not update dose status.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
  // ================================================================
  // EMPTY NEXT DOSE
  // ================================================================

  Widget _emptyNextDoseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD6E5FF),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 40,
            color: primaryBlue,
          ),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming dose',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Add a medication and schedule a time.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13,
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
  // EMPTY MEDICATION STATE
  // ================================================================

  Widget _emptyMedicationState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 40,
            color: Color(0xFF94A3B8),
          ),

          SizedBox(height: 10),

          Text(
            'No medications added yet.',
            style: TextStyle(
              color: secondaryText,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FIND NEXT DOSE
  // ================================================================

  Map<String, String>? _findNextDose(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = TimeOfDay.now();

    final currentMinutes =
        now.hour * 60 + now.minute;

    Map<String, String>? bestDose;
    int? bestMinutes;

    for (final doc in docs) {
      final data = doc.data();

      final name =
          data['name']?.toString() ??
              'Medication';

      final dosage =
          data['dosage']?.toString() ?? '';

      final unit =
          data['unit']?.toString() ?? '';

      final times = List<String>.from(
        data['times'] ?? [],
      );

      for (final timeString in times) {
        final parsed =
            _parseTimeToMinutes(timeString);

        if (parsed == null) {
          continue;
        }

        if (parsed >= currentMinutes) {
          if (bestMinutes == null ||
              parsed < bestMinutes) {
            bestMinutes = parsed;

            bestDose = {
              'name': name,
              'dosage': dosage,
              'unit': unit,
              'time': timeString,
            };
          }
        }
      }
    }

    // If today's doses are finished,
    // show the earliest dose tomorrow.
    if (bestDose == null) {
      bestMinutes = null;

      for (final doc in docs) {
        final data = doc.data();

        final name =
            data['name']?.toString() ??
                'Medication';

        final dosage =
            data['dosage']?.toString() ?? '';

        final unit =
            data['unit']?.toString() ?? '';

        final times = List<String>.from(
          data['times'] ?? [],
        );

        for (final timeString in times) {
          final parsed =
              _parseTimeToMinutes(timeString);

          if (parsed == null) {
            continue;
          }

          if (bestMinutes == null ||
              parsed < bestMinutes) {
            bestMinutes = parsed;

            bestDose = {
              'name': name,
              'dosage': dosage,
              'unit': unit,
              'time': timeString,
            };
          }
        }
      }
    }

    return bestDose;
  }

  // ================================================================
  // PARSE TIME
  // ================================================================

  int? _parseTimeToMinutes(String value) {
    try {
      final parts =
          value.trim().split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timeParts =
          parts[0].split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour =
          int.parse(timeParts[0]);

      final minute =
          int.parse(timeParts[1]);

      final period =
          parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      if (hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // CURRENT DATE
  // ================================================================

  String _formatCurrentDate() {
    final now = DateTime.now();

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final day = now.day;

    String suffix;

    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    return '${weekdays[now.weekday - 1]}, '
        '$day$suffix ${months[now.month - 1]}';
  }

  // ================================================================
  // MEDICATION ICON
  // ================================================================

  IconData _getMedicationIcon(
    String form,
  ) {
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
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected =
        selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          setState(() {
            selectedIndex = 0;
          });
          return;
        }

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const MedicationsScreen(),
            ),
          );
          return;
        }

        // History and Profile will be connected later.
      },

      behavior: HitTestBehavior.opaque,

      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 27,
              color: selected
                  ? primaryBlue
                  : const Color(
                      0xFF94A3B8,
                    ),
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
                    : const Color(
                        0xFF64748B,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
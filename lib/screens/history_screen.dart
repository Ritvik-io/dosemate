import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const Color primaryBlue = Color(0xFF3563E9);
  static const Color darkText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);

  static const Color takenGreen = Color(0xFF22A865);
  static const Color takenBackground = Color(0xFFE9F9F0);

  static const Color skippedOrange = Color(0xFFF59E0B);
  static const Color skippedBackground = Color(0xFFFFF4E5);

  static const Color missedRed = Color(0xFFEF4444);
  static const Color missedBackground = Color(0xFFFFEEEE);

  static const Color borderColor = Color(0xFFE2E8F0);

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
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    final medicationsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications');

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
          'History',
          style: TextStyle(
            color: darkText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: medicationsQuery.snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          if (snapshot.hasError) {
            return _errorState();
          }

          final docs = snapshot.data?.docs ?? [];

          final history = _buildHistory(docs);

          if (history.isEmpty) {
            return _emptyHistory();
          }

          final grouped = _groupHistory(history);

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: () async {
              // Firestore stream automatically updates.
              // This small delay gives RefreshIndicator
              // something to animate against.
              await Future.delayed(
                const Duration(
                  milliseconds: 400,
                ),
              );
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                30,
              ),

              children: [
                _summaryHeader(history),

                const SizedBox(
                  height: 22,
                ),

                ...grouped.entries.map(
                  (entry) {
                    return _historySection(
                      title: entry.key,
                      items: entry.value,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD HISTORY DATA
  // ============================================================

  List<Map<String, dynamic>> _buildHistory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final history = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data();

      final name =
          data['name']?.toString() ?? 'Medication';

      final dosage =
          data['dosage']?.toString() ?? '';

      final unit =
          data['unit']?.toString() ?? '';

      final rawDoseStatus =
          data['doseStatus'];

      if (rawDoseStatus is! Map) {
        continue;
      }

      final doseStatus =
          Map<String, dynamic>.from(rawDoseStatus);

      doseStatus.forEach(
        (key, value) {
          final status = value.toString().toLowerCase();

          if (status != 'taken' &&
              status != 'skipped' &&
              status != 'missed') {
            return;
          }

          final parts = key.split('*');

          if (parts.length < 2) {
            return;
          }

          final date = parts[0];

          final time = parts
              .sublist(1)
              .join('*');

          final dateTime =
              _parseDateTime(
            date,
            time,
          );

          history.add({
            'medicationId': doc.id,
            'name': name,
            'dosage': dosage,
            'unit': unit,
            'date': date,
            'time': time,
            'status': status,
            'dateTime': dateTime,
          });
        },
      );
    }

    // ----------------------------------------------------------
    // NEWEST FIRST
    // ----------------------------------------------------------

    history.sort(
      (a, b) {
        final aDate =
            a['dateTime'] as DateTime?;

        final bDate =
            b['dateTime'] as DateTime?;

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      },
    );

    return history;
  }

  // ============================================================
  // PARSE DATE + TIME
  // ============================================================

  DateTime? _parseDateTime(
    String date,
    String time,
  ) {
    try {
      final parsedDate =
          DateTime.parse(date);

      final timeParts =
          time.trim().split(' ');

      if (timeParts.length != 2) {
        return DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
      }

      final clock =
          timeParts[0].split(':');

      if (clock.length != 2) {
        return null;
      }

      int hour =
          int.parse(clock[0]);

      final minute =
          int.parse(clock[1]);

      final period =
          timeParts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // GROUP HISTORY
  // ============================================================

  Map<String, List<Map<String, dynamic>>>
      _groupHistory(
    List<Map<String, dynamic>> history,
  ) {
    final result =
        <String, List<Map<String, dynamic>>>{};

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    for (final item in history) {
      final date =
          item['dateTime'] as DateTime?;

      if (date == null) {
        result
            .putIfAbsent(
              'Earlier',
              () => [],
            )
            .add(item);

        continue;
      }

      final itemDay = DateTime(
        date.year,
        date.month,
        date.day,
      );

      String section;

      if (itemDay == today) {
        section = 'Today';
      } else if (itemDay == yesterday) {
        section = 'Yesterday';
      } else {
        section = _formatDateHeading(
          itemDay,
        );
      }

      result
          .putIfAbsent(
            section,
            () => [],
          )
          .add(item);
    }

    return result;
  }

  // ============================================================
  // SUMMARY HEADER
  // ============================================================

  Widget _summaryHeader(
    List<Map<String, dynamic>> history,
  ) {
    final takenCount = history
        .where(
          (item) =>
              item['status'] == 'taken',
        )
        .length;

    final skippedCount = history
        .where(
          (item) =>
              item['status'] == 'skipped',
        )
        .length;

    final missedCount = history
        .where(
          (item) =>
              item['status'] == 'missed',
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFDCE5F5),
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              icon: Icons.check_circle_rounded,
              color: takenGreen,
              backgroundColor:
                  takenBackground,
              value: takenCount.toString(),
              label: 'Taken',
            ),
          ),

          Container(
            width: 1,
            height: 42,
            color: borderColor,
          ),

          Expanded(
            child: _summaryItem(
              icon: Icons.remove_circle_rounded,
              color: skippedOrange,
              backgroundColor:
                  skippedBackground,
              value: skippedCount.toString(),
              label: 'Skipped',
            ),
          ),

          Container(
            width: 1,
            height: 42,
            color: borderColor,
          ),

          Expanded(
            child: _summaryItem(
              icon: Icons.warning_rounded,
              color: missedRed,
              backgroundColor:
                  missedBackground,
              value: missedCount.toString(),
              label: 'Missed',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,

          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          value,
          style: const TextStyle(
            color: darkText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HISTORY SECTION
  // ============================================================

  Widget _historySection({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
            bottom: 10,
          ),

          child: Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        ...items.map(
          (item) {
            return _historyCard(item);
          },
        ),

        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _historyCard(
    Map<String, dynamic> item,
  ) {
    final status =
        item['status']?.toString() ?? '';

    final isTaken =
        status == 'taken';

    final isSkipped =
        status == 'skipped';

    final color = isTaken
        ? takenGreen
        : isSkipped
            ? skippedOrange
            : missedRed;

    final backgroundColor = isTaken
        ? takenBackground
        : isSkipped
            ? skippedBackground
            : missedBackground;

    final icon = isTaken
        ? Icons.check_circle_rounded
        : isSkipped
            ? Icons.remove_circle_outline_rounded
            : Icons.warning_rounded;

    final statusText = isTaken
        ? 'Taken'
        : isSkipped
            ? 'Skipped'
            : 'Missed';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: borderColor,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.035),

            blurRadius: 12,

            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          // ------------------------------------------------------
          // STATUS ICON
          // ------------------------------------------------------

          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // ------------------------------------------------------
          // MEDICATION INFO
          // ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  item['name']?.toString() ??
                      'Medication',

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${item['dosage']} ${item['unit']}',
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: secondaryText,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Text(
                      item['time']
                              ?.toString() ??
                          '',
                      style:
                          const TextStyle(
                        color:
                            secondaryText,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ------------------------------------------------------
          // STATUS
          // ------------------------------------------------------

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: backgroundColor,

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Text(
              statusText,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE HEADING
  // ============================================================

  String _formatDateHeading(
    DateTime date,
  ) {
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

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 84,
              height: 84,

              decoration:
                  const BoxDecoration(
                color: Color(0xFFEAF1FF),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.history_rounded,
                color: primaryBlue,
                size: 44,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'No history yet',
              style: TextStyle(
                color: darkText,
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Once you take or skip a dose, '
              'your medication activity will '
              'appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration:
                  const BoxDecoration(
                color: Color(0xFFFFEEEE),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.error_outline_rounded,
                color: missedRed,
                size: 36,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Could not load history',
              style: TextStyle(
                color: darkText,
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Please check your connection '
              'and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
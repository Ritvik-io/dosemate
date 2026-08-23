import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'medications_screen.dart';
import '../notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  // null = Add new medication
  // document = Edit existing medication
  final DocumentSnapshot? medicationDoc;

  const AddMedicineScreen({
    super.key,
    this.medicationDoc,
  });

  bool get isEditing => medicationDoc != null;

  @override
  State<AddMedicineScreen> createState() =>
      _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  static const Color primaryBlue = Color(0xFF3563E9);
  static const Color darkText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color lightBlue = Color(0xFFF1F6FF);
  static const Color borderColor = Color(0xFFDCE5F5);

  final TextEditingController medicineNameController =
      TextEditingController();

  final TextEditingController dosageController =
      TextEditingController();

  final TextEditingController noteController =
      TextEditingController();

  final TextEditingController amountController =
      TextEditingController();

  String selectedUnit = 'mg';
  String selectedForm = 'Pill';
  String selectedFrequency = 'Daily';

  List<TimeOfDay> scheduleTimes = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
  ];

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadExistingMedication();
  }

  // ============================================================
  // LOAD EXISTING MEDICATION
  // ============================================================

  void _loadExistingMedication() {
    final doc = widget.medicationDoc;

    if (doc == null) {
      return;
    }

    final data = doc.data() as Map<String, dynamic>;

    medicineNameController.text =
        data['name']?.toString() ?? '';

    dosageController.text =
        data['dosage']?.toString() ?? '';

    noteController.text =
        data['note']?.toString() ?? '';

    amountController.text =
        data['amountPerDose']?.toString() ?? '';

    selectedUnit =
        data['unit']?.toString() ?? 'mg';

    selectedForm =
        data['form']?.toString() ?? 'Pill';

    selectedFrequency =
        data['frequency']?.toString() ?? 'Daily';

    final savedTimes = List<String>.from(
      data['times'] ?? [],
    );

    if (savedTimes.isNotEmpty) {
      final parsedTimes = savedTimes
          .map(_parseTime)
          .whereType<TimeOfDay>()
          .toList();

      if (parsedTimes.isNotEmpty) {
        scheduleTimes = parsedTimes;
      }
    }
  }

  // ============================================================
  // PARSE FIRESTORE TIME
  // ============================================================

  TimeOfDay? _parseTime(String value) {
    try {
      final parts = value.trim().split(' ');

      if (parts.length != 2) {
        return null;
      }

      final timeParts = parts[0].split(':');

      if (timeParts.length != 2) {
        return null;
      }

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    medicineNameController.dispose();
    dosageController.dispose();
    noteController.dispose();
    amountController.dispose();

    super.dispose();
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> selectTime(int index) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: scheduleTimes[index],
    );

    if (pickedTime != null) {
      setState(() {
        scheduleTimes[index] = pickedTime;
      });
    }
  }

  Future<void> addTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        scheduleTimes.add(pickedTime);
      });
    }
  }

  void removeTime(int index) {
    if (scheduleTimes.length <= 1) {
      _showMessage(
        'You need at least one schedule time.',
      );
      return;
    }

    setState(() {
      scheduleTimes.removeAt(index);
    });
  }

  String formatTime(TimeOfDay time) {
    final hour =
        time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // SAVE / UPDATE MEDICATION
  // ============================================================

  Future<void> saveMedication() async {
    final medicineName =
        medicineNameController.text.trim();

    final dosage =
        dosageController.text.trim();

    final note =
        noteController.text.trim();

    final amount =
        amountController.text.trim();

    // ========================================================
// SCHEDULE NOTIFICATIONS
// ========================================================

final notificationBaseId =
    widget.medicationDoc?.id.hashCode ??
        DateTime.now().millisecondsSinceEpoch;

for (int i = 0; i < scheduleTimes.length; i++) {
  await NotificationService.instance.scheduleDailyReminder(
    id: notificationBaseId + i,
    medicineName: medicineName,
    dosage: '$dosage $selectedUnit',
    time: formatTime(scheduleTimes[i]),
  );
}

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (medicineName.isEmpty) {
      _showMessage(
        'Please enter a medication name.',
      );
      return;
    }

    if (dosage.isEmpty) {
      _showMessage(
        'Please enter the dosage.',
      );
      return;
    }

    if (scheduleTimes.isEmpty) {
      _showMessage(
        'Please add at least one schedule time.',
      );
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in again.',
      );
      return;
    }

    // ----------------------------------------------------------
    // FIRESTORE
    // ----------------------------------------------------------

    try {
      final medicationData = {
        'name': medicineName,
        'dosage': dosage,
        'unit': selectedUnit,
        'form': selectedForm,
        'frequency': selectedFrequency,

        'times': scheduleTimes
            .map((time) => formatTime(time))
            .toList(),

        'note': note,
        'amountPerDose': amount,

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      final medicationsRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('medications');

      // ========================================================
      // EDIT EXISTING MEDICATION
      // ========================================================

      if (widget.medicationDoc != null) {
        await medicationsRef
            .doc(widget.medicationDoc!.id)
            .update(medicationData);
      }

      // ========================================================
      // ADD NEW MEDICATION
      // ========================================================

      else {
        await medicationsRef.add({
          ...medicationData,
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SUCCESS MESSAGE
      // --------------------------------------------------------

      _showMessage(
        widget.isEditing
            ? 'Medication updated successfully!'
            : 'Medication saved successfully!',
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) {
        return;
      }

      // Return to medications screen.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        'FIRESTORE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        widget.isEditing
            ? 'Could not update medication.'
            : 'Could not save medication.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // TOP BAR
            // ======================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                15,
                20,
                15,
              ),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  Expanded(
                    child: Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'DOSE',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                              text: 'MATE',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  _circleButton(
                    icon:
                        Icons.person_outline_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TITLE
                    // ==================================================

                    Text(
                      widget.isEditing
                          ? 'Edit Medication'
                          : 'Add New Medication',
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight:
                            FontWeight.w800,
                        color: darkText,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      widget.isEditing
                          ? 'Update your medication details'
                          : 'Fill in the details to set smart reminders',
                      style: const TextStyle(
                        fontSize: 14,
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // FORM CARD
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(18),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(28),
                        border: Border.all(
                          color: borderColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue
                                .withOpacity(0.06),
                            blurRadius: 25,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // ==================================================
                          // MEDICATION NAME
                          // ==================================================

                          _sectionTitle(
                            'Medication Name',
                            Icons.medication_outlined,
                          ),

                          const SizedBox(height: 10),

                          _textField(
                            controller:
                                medicineNameController,
                            hint:
                                'Enter brand or chemical name',
                            icon:
                                Icons.medication_outlined,
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // DOSAGE
                          // ==================================================

                          _sectionTitle(
                            'Strength / Dosage',
                            Icons
                                .monitor_weight_outlined,
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  controller:
                                      dosageController,
                                  hint:
                                      'Enter strength',
                                  keyboardType:
                                      TextInputType
                                          .number,
                                ),
                              ),

                              const SizedBox(width: 8),

                              _unitButton('mg'),

                              const SizedBox(width: 7),

                              _unitButton('mcg'),

                              const SizedBox(width: 7),

                              _unitButton('mL'),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // FORM
                          // ==================================================

                          const Text(
                            'Medication Form',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                              color: darkText,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _formButton(
                                  icon: Icons
                                      .medication_rounded,
                                  label: 'Pill',
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: _formButton(
                                  icon: Icons
                                      .local_drink_outlined,
                                  label: 'Liquid',
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: _formButton(
                                  icon:
                                      Icons.air_rounded,
                                  label: 'Inhaler',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // FREQUENCY
                          // ==================================================

                          const Text(
                            'Frequency',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                              color: darkText,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    _frequencyButton(
                                  'Daily',
                                ),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child:
                                    _frequencyButton(
                                  'Specific Days',
                                ),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child:
                                    _frequencyButton(
                                  'As Needed',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // SCHEDULE + NOTE
                          // ==================================================

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Schedule Times',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color: darkText,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 10,
                                    ),

                                    ...List.generate(
                                      scheduleTimes.length,
                                      (index) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets
                                                  .only(
                                            bottom: 8,
                                          ),
                                          child:
                                              _timeTile(
                                            index,
                                          ),
                                        );
                                      },
                                    ),

                                    SizedBox(
                                      width:
                                          double.infinity,
                                      height: 48,
                                      child:
                                          OutlinedButton
                                              .icon(
                                        onPressed:
                                            addTime,
                                        icon:
                                            const Icon(
                                          Icons
                                              .add_rounded,
                                          size: 22,
                                        ),
                                        label:
                                            const Text(
                                          'Add time',
                                        ),
                                        style:
                                            OutlinedButton
                                                .styleFrom(
                                          foregroundColor:
                                              primaryBlue,
                                          side:
                                              const BorderSide(
                                            color:
                                                primaryBlue,
                                            width: 1.3,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Text(
                                      'Note',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color: darkText,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 10,
                                    ),

                                    TextField(
                                      controller:
                                          noteController,
                                      maxLines: 6,
                                      decoration:
                                          InputDecoration(
                                        hintText:
                                            'Add note',
                                        hintStyle:
                                            const TextStyle(
                                          color:
                                              secondaryText,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor:
                                            const Color(
                                          0xFFFAFBFF,
                                        ),
                                        contentPadding:
                                            const EdgeInsets
                                                .all(
                                          14,
                                        ),
                                        border:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            15,
                                          ),
                                          borderSide:
                                              const BorderSide(
                                            color:
                                                borderColor,
                                          ),
                                        ),
                                        enabledBorder:
                                            OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            15,
                                          ),
                                          borderSide:
                                              const BorderSide(
                                            color:
                                                borderColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // ==================================================
                          // AMOUNT PER DOSE
                          // ==================================================

                          _sectionTitle(
                            'Amount per Dose',
                            Icons
                                .local_pharmacy_outlined,
                          ),

                          const SizedBox(height: 10),

                          _textField(
                            controller:
                                amountController,
                            hint:
                                'e.g. 1 pill, 2 tablets',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // SAVE / UPDATE BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
onPressed: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('BUTTON WORKS!'),
    ),
  );
},           style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryBlue,
                          foregroundColor:
                              Colors.white,
                          elevation: 5,
                          shadowColor:
                              primaryBlue
                                  .withOpacity(0.3),
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
                            Icon(
                              widget.isEditing
                                  ? Icons
                                      .check_circle_outline_rounded
                                  : Icons
                                      .add_circle_outline_rounded,
                              size: 29,
                            ),

                            const SizedBox(width: 10),

                            Text(
                              widget.isEditing
                                  ? 'Update Medication'
                                  : 'Save Medication',
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar:
          _bottomNavigation(),
    );
  }

  // ============================================================
  // TOP CIRCLE BUTTON
  // ============================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(
          color: lightBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: darkText,
          size: 25,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 21,
          ),
        ),

        const SizedBox(width: 11),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        color: darkText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
        ),

        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                color: secondaryText,
              ),

        filled: true,
        fillColor:
            const Color(0xFFFAFBFF),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UNIT BUTTON
  // ============================================================

  Widget _unitButton(String unit) {
    final selected =
        selectedUnit == unit;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUnit = unit;
        });
      },
      child: Container(
        height: 54,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? lightBlue
              : const Color(0xFFF3F5F9),

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? primaryBlue
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            unit,
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
              color: selected
                  ? primaryBlue
                  : darkText,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORM BUTTON
  // ============================================================

  Widget _formButton({
    required IconData icon,
    required String label,
  }) {
    final selected =
        selectedForm == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedForm = label;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        height: 62,
        decoration:
            BoxDecoration(
          color: selected
              ? lightBlue
              : const Color(0xFFF8FAFD),

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? primaryBlue
                : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? primaryBlue
                  : darkText,
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
                color: selected
                    ? primaryBlue
                    : darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FREQUENCY BUTTON
  // ============================================================

  Widget _frequencyButton(
    String frequency,
  ) {
    final selected =
        selectedFrequency == frequency;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFrequency = frequency;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        height: 52,
        decoration:
            BoxDecoration(
          color: selected
              ? lightBlue
              : const Color(0xFFF8FAFD),

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? primaryBlue
                : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            frequency,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: selected
                  ? primaryBlue
                  : darkText,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TIME TILE
  // ============================================================

  Widget _timeTile(int index) {
    return GestureDetector(
      onTap: () =>
          selectTime(index),
      child: Container(
        height: 52,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFFAFBFF),

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 19,
              color: secondaryText,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                formatTime(
                  scheduleTimes[index],
                ),
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color: darkText,
                ),
              ),
            ),

            GestureDetector(
              onTap: () =>
                  removeTime(index),
              child: const Icon(
                Icons.close_rounded,
                size: 19,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _bottomNavigation() {
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
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset:
                const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,

            children: [
              _navItem(
                Icons.home_rounded,
                'Home',
                false,
              ),

              _navItem(
                Icons.medication_rounded,
                'Medications',
                true,
              ),

              _navItem(
                Icons.history_rounded,
                'History',
                false,
              ),

              _navItem(
                Icons.person_outline_rounded,
                'Profile',
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _navItem(
  IconData icon,
  String label,
  bool selected,
) {
  return GestureDetector(
    onTap: () {
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

      if (label == 'Medications') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MedicationsScreen(),
          ),
          (route) => false,
        );
        return;
      }

      // History and Profile can be connected later.
    },

    behavior: HitTestBehavior.opaque,

    child: SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: selected
                ? primaryBlue
                : const Color(0xFF94A3B8),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
}
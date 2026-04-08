import 'package:flutter/material.dart';
import '../modules/medication_reminder/medication_reminder_screen.dart';

// Global static memory so it can be synced across Dashboard & MedicationScreen
final List<MedicationV2> globalSampleMeds = [
  MedicationV2(
    id: 'med_3',
    name: 'Valsartan',
    dose: '80 mg',
    note: 'Untuk tekanan darah. Setelah makan.',
    time: const TimeOfDay(hour: 7, minute: 0),
    period: 'Pagi',
    totalStock: 30,
    stock: 30,
    isActive: true,
    taken: false,
    alarmSound: 'chime',
  ),
  MedicationV2(
    id: 'med_4',
    name: 'Atorvastatin',
    dose: '20 mg',
    note: 'Untuk kolesterol. Diminum malam hari.',
    time: const TimeOfDay(hour: 20, minute: 0),
    period: 'Malam',
    totalStock: 15,
    stock: 15,
    isActive: true,
    taken: true,
    alarmSound: 'chime',
  ),
  MedicationV2(
    id: 'med_5',
    name: 'Clopidogrel',
    dose: '75 mg',
    note: 'Pengencer darah. Setelah makan pagi.',
    time: const TimeOfDay(hour: 8, minute: 0),
    period: 'Pagi',
    totalStock: 20,
    stock: 20,
    isActive: false,
    taken: false,
    alarmSound: 'chime',
  ),
];

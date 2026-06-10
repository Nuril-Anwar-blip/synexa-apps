/// Daftar obat stroke oral berdasarkan PNPK 2019 (Kemenkes).
class CommonMedication {
  final String name;
  final String? defaultDose;
  final String category;
  final String? dosageForm;
  final String? indication;

  const CommonMedication({
    required this.name,
    this.defaultDose,
    required this.category,
    this.dosageForm,
    this.indication,
  });
}

class CommonMedications {
  static const List<CommonMedication> list = [
    // 1. Antiplatelet — stroke iskemik non-kardioemboli
    CommonMedication(
      name: 'Aspirin',
      defaultDose: '80–100 mg',
      category: 'Antiplatelet',
      dosageForm: 'Tablet',
      indication: 'Pencegahan sekunder stroke',
    ),
    CommonMedication(
      name: 'Clopidogrel',
      defaultDose: '75 mg',
      category: 'Antiplatelet',
      dosageForm: 'Tablet',
      indication: 'Alternatif bila alergi aspirin',
    ),
    CommonMedication(
      name: 'Dipiridamol',
      defaultDose: '200 mg',
      category: 'Antiplatelet',
      dosageForm: 'Tablet',
      indication: 'Kombinasi dengan aspirin',
    ),
    CommonMedication(
      name: 'Aspirin + Dipiridamol',
      defaultDose: '25/200 mg',
      category: 'Antiplatelet',
      dosageForm: 'Tablet kombinasi',
      indication: 'Pencegahan sekunder stroke',
    ),

    // 2. Antikoagulan — stroke kardioemboli (mis. fibrilasi atrium)
    CommonMedication(
      name: 'Warfarin',
      defaultDose: '2–5 mg',
      category: 'Antikoagulan',
      dosageForm: 'Tablet',
      indication: 'Vitamin K antagonist',
    ),
    CommonMedication(
      name: 'Dabigatran',
      defaultDose: '110–150 mg',
      category: 'Antikoagulan',
      dosageForm: 'Kapsul',
      indication: 'NOAC',
    ),
    CommonMedication(
      name: 'Apixaban',
      defaultDose: '5 mg',
      category: 'Antikoagulan',
      dosageForm: 'Tablet',
      indication: 'NOAC',
    ),
    CommonMedication(
      name: 'Rivaroxaban',
      defaultDose: '15–20 mg',
      category: 'Antikoagulan',
      dosageForm: 'Tablet',
      indication: 'NOAC',
    ),

    // 3. Antihipertensi
    CommonMedication(
      name: 'Captopril',
      defaultDose: '25 mg',
      category: 'Antihipertensi',
      dosageForm: 'Tablet',
      indication: 'ACE inhibitor',
    ),
    CommonMedication(
      name: 'Lisinopril',
      defaultDose: '10 mg',
      category: 'Antihipertensi',
      dosageForm: 'Tablet',
      indication: 'ACE inhibitor',
    ),
    CommonMedication(
      name: 'Amlodipin',
      defaultDose: '5 mg',
      category: 'Antihipertensi',
      dosageForm: 'Tablet',
      indication: 'Calcium channel blocker',
    ),
    CommonMedication(
      name: 'Diltiazem',
      defaultDose: '60 mg',
      category: 'Antihipertensi',
      dosageForm: 'Tablet',
      indication: 'Calcium channel blocker',
    ),

    // 4. Statin — pencegahan stroke primer/sekunder pada dislipidemia
    CommonMedication(
      name: 'Simvastatin',
      defaultDose: '20 mg',
      category: 'Statin',
      dosageForm: 'Tablet',
      indication: 'Penurun lipid',
    ),
    CommonMedication(
      name: 'Atorvastatin',
      defaultDose: '20 mg',
      category: 'Statin',
      dosageForm: 'Tablet',
      indication: 'Penurun lipid',
    ),

    // 5. Antikonvulsan — kejang pasca stroke
    CommonMedication(
      name: 'Karbamazepin',
      defaultDose: '200 mg',
      category: 'Antiepileptik',
      dosageForm: 'Tablet',
      indication: 'Kejang pasca stroke',
    ),
    CommonMedication(
      name: 'Fenitoin',
      defaultDose: '100 mg',
      category: 'Antiepileptik',
      dosageForm: 'Tablet',
      indication: 'Kejang pasca stroke',
    ),

    // 6. Nyeri neuropatik pasca stroke
    CommonMedication(
      name: 'Amitriptilin',
      defaultDose: '25 mg',
      category: 'Nyeri Neuropatik',
      dosageForm: 'Tablet',
      indication: 'Antidepresan trisiklik',
    ),
    CommonMedication(
      name: 'Gabapentin',
      defaultDose: '300 mg',
      category: 'Nyeri Neuropatik',
      dosageForm: 'Tablet/Kapsul',
      indication: 'Antikonvulsan',
    ),
    CommonMedication(
      name: 'Lamotrigin',
      defaultDose: '25 mg',
      category: 'Nyeri Neuropatik',
      dosageForm: 'Tablet',
      indication: 'Antikonvulsan',
    ),

    // 7. Laksatif — konstipasi pada pasien stroke
    CommonMedication(
      name: 'Senna',
      defaultDose: '7.5 mg',
      category: 'Laksatif',
      dosageForm: 'Tablet',
      indication: 'Laksatif stimulan',
    ),
    CommonMedication(
      name: 'Laktulosa',
      defaultDose: '15 mL',
      category: 'Laksatif',
      dosageForm: 'Sirup',
      indication: 'Laksatif osmotik',
    ),
    CommonMedication(
      name: 'Polyethylene glycol',
      defaultDose: '17 g',
      category: 'Laksatif',
      dosageForm: 'Sachet',
      indication: 'Laksatif osmotik',
    ),

    // Catatan: Sickle Cell Disease
    CommonMedication(
      name: 'Hydroxyurea',
      defaultDose: '500 mg',
      category: 'Pencegahan Risiko',
      dosageForm: 'Kapsul',
      indication: 'Mengurangi risiko stroke (sickle cell)',
    ),
  ];

  static List<String> get names => list.map((m) => m.name).toList();

  static List<String> get categories =>
      list.map((m) => m.category).toSet().toList()..sort();

  static List<CommonMedication> byCategory(String category) =>
      list.where((m) => m.category == category).toList();

  static CommonMedication? findByName(String name) {
    try {
      return list.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

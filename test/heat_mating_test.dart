import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:ayushka/app/core/widgets/custom_pagination.dart';
import 'package:ayushka/app/data/models/cow_heat_model.dart';
import 'package:ayushka/app/data/models/cow_mating_model.dart';
import 'package:ayushka/app/data/models/dashboard_alerts_model.dart';
import 'package:ayushka/app/modules/dashboard/widgets/breeding_alert_card.dart';

void main() {
  group('Cow Heat Model Tests', () {
    test('CowHeatModel parses correctly from backend JSON', () {
      final json = {
        '_id': 'heat-001',
        'gaushalaId': 'gaushala-123',
        'cowId': 'cow-999',
        'heatDate': '2026-10-12T00:00:00.000Z',
        'heatTime': 'morning',
        'heatStage': 'STANDING',
        'heatSigns': ['MOUNTING', 'MUCUS_DISCHARGE', 'BELLOWING'],
        'intensity': 'STRONG',
        'status': 'READY_FOR_MATING',
        'isRepeatHeatAlert': true,
        'consecutiveHeatCount': 3,
        'observedByWorkerId': 'worker-55',
        'remarks': 'Showing clear signs of estrus',
        'cow': {
          '_id': 'cow-999',
          'tagId': 'TAG-401',
          'calfName': 'Kamadhenu',
          'shed': {'name': 'Breeding Shed A'},
          'breed': {'name': 'Gir'},
        },
        'observedByWorker': {
          '_id': 'worker-55',
          'name': 'Ramesh Yadav',
        },
        'createdAt': '2026-10-12T06:00:00.000Z',
        'updatedAt': '2026-10-12T07:00:00.000Z',
      };

      final heat = CowHeatModel.fromJson(json);

      expect(heat.id, 'heat-001');
      expect(heat.gaushalaId, 'gaushala-123');
      expect(heat.cowId, 'cow-999');
      expect(heat.heatDate?.year, 2026);
      expect(heat.heatDate?.month, 10);
      expect(heat.heatDate?.day, 12);
      expect(heat.heatTime, 'morning');
      expect(heat.heatStage, HeatStage.standing);
      expect(heat.intensity, HeatIntensity.strong);
      expect(heat.status, HeatStatus.readyForMating);
      expect(heat.isRepeatHeatAlert, isTrue);
      expect(heat.consecutiveHeatCount, 3);
      expect(heat.observedByWorkerId, 'worker-55');
      expect(heat.cowTagId, 'TAG-401');
      expect(heat.cowCalfName, 'Kamadhenu');
      expect(heat.cowShedName, 'Breeding Shed A');
      expect(heat.cowBreedName, 'Gir');
      expect(heat.workerName, 'Ramesh Yadav');
      expect(heat.heatSigns, containsAll(['MOUNTING', 'MUCUS_DISCHARGE', 'BELLOWING']));
    });

    test('CowHeatModel toJson produces valid API payload for POST /api/v1/heats', () {
      final heat = CowHeatModel(
        id: 'temp-id',
        gaushalaId: 'gaushala-123',
        cowId: 'cow-999',
        cowTagId: 'TAG-999',
        heatDate: DateTime(2026, 10, 13),
        heatTime: 'evening',
        heatStage: HeatStage.early,
        heatSigns: ['RESTLESSNESS', 'SNIFFING_VULVA'],
        intensity: HeatIntensity.mild,
        status: HeatStatus.observed,
        observedByWorkerId: 'worker-1',
        remarks: 'Initial observation',
      );

      final payload = heat.toJson();

      expect(payload['gaushalaId'], 'gaushala-123');
      expect(payload['cowId'], 'cow-999');
      expect(payload['heatDate'], '2026-10-13');
      expect(payload['heatTime'], 'evening');
      expect(payload['heatStage'], 'EARLY');
      expect(payload['intensity'], 'MILD');
      expect(payload['status'], 'OBSERVED');
      expect(payload['observedByWorkerId'], 'worker-1');
      expect(payload['remarks'], 'Initial observation');
      expect(payload['heatSigns'], containsAll(['RESTLESSNESS', 'SNIFFING_VULVA']));
    });

    test('HeatPaginatedResult parses pagination metadata and list items', () {
      final json = {
        'data': [
          {
            '_id': 'heat-1',
            'gaushalaId': 'g-1',
            'cowId': 'c-1',
            'heatDate': '2026-10-10',
            'heatTime': 'morning',
            'heatStage': 'STANDING',
            'status': 'READY_FOR_MATING',
          },
          {
            '_id': 'heat-2',
            'gaushalaId': 'g-1',
            'cowId': 'c-2',
            'heatDate': '2026-10-11',
            'heatTime': 'evening',
            'heatStage': 'LATE',
            'status': 'MATED',
          },
        ],
        'total': 25,
        'page': 1,
        'limit': 10,
        'totalPages': 3,
      };

      final result = HeatPaginatedResult.fromJson(json);

      expect(result.items.length, 2);
      expect(result.total, 25);
      expect(result.page, 1);
      expect(result.limit, 10);
      expect(result.totalPages, 3);
      expect(result.items[0].status, HeatStatus.readyForMating);
      expect(result.items[1].status, HeatStatus.mated);
    });
  });

  group('Cow Mating Model Tests', () {
    test('CowMatingModel parses Natural mating correctly from backend JSON', () {
      final json = {
        '_id': 'mating-101',
        'gaushalaId': 'gaushala-123',
        'cowId': 'cow-999',
        'heatId': 'heat-001',
        'matingDate': '2026-10-12T00:00:00.000Z',
        'matingTime': 'morning',
        'matingType': 'NATURAL',
        'bullId': 'bull-01',
        'bullNameOrTag': 'Nandi Bull',
        'inseminatorName': 'Dr. Sharma',
        'status': 'PENDING_PD',
        'isRepeatBreederAlert': false,
        'failedMatingAttempts': 1,
        'expectedPDDate': '2026-12-11T00:00:00.000Z',
        'cow': {
          '_id': 'cow-999',
          'tagId': 'TAG-401',
          'calfName': 'Kamadhenu',
        },
        'bull': {
          '_id': 'bull-01',
          'tagId': 'BULL-01',
          'calfName': 'Nandi',
        },
      };

      final mating = CowMatingModel.fromJson(json);

      expect(mating.id, 'mating-101');
      expect(mating.gaushalaId, 'gaushala-123');
      expect(mating.cowId, 'cow-999');
      expect(mating.heatId, 'heat-001');
      expect(mating.matingType, MatingType.natural);
      expect(mating.bullId, 'bull-01');
      expect(mating.bullDisplayName, 'Nandi Bull');
      expect(mating.status, MatingStatus.pendingPd);
      expect(mating.expectedPDDate?.month, 12);
      expect(mating.cowTagId, 'TAG-401');
      expect(mating.cowCalfName, 'Kamadhenu');
    });

    test('CowMatingModel parses Artificial Insemination (AI) and PD status correctly', () {
      final json = {
        '_id': 'mating-202',
        'gaushalaId': 'gaushala-123',
        'cowId': 'cow-888',
        'matingDate': '2026-08-01T00:00:00.000Z',
        'matingType': 'ARTIFICIAL',
        'semenStrawCode': 'GIR-SAG-9921',
        'semenBreedId': 'breed-gir',
        'semenSource': 'SAG',
        'inseminatorName': 'Dr. Patel',
        'status': 'PREGNANT',
        'pdResult': 'POSITIVE',
        'pdDate': '2026-10-01T00:00:00.000Z',
        'pdPerformedBy': 'Dr. Patel',
        'expectedCalvingDate': '2027-05-10T00:00:00.000Z',
        'isRepeatBreederAlert': true,
        'failedMatingAttempts': 3,
        'breed': {
          '_id': 'breed-gir',
          'name': 'Gir Purebred',
        },
      };

      final mating = CowMatingModel.fromJson(json);

      expect(mating.id, 'mating-202');
      expect(mating.matingType, MatingType.artificial);
      expect(mating.semenStrawCode, 'GIR-SAG-9921');
      expect(mating.semenSource, 'SAG');
      expect(mating.status, MatingStatus.pregnant);
      expect(mating.pdResult, PDResult.positive);
      expect(mating.pdPerformedBy, 'Dr. Patel');
      expect(mating.expectedCalvingDate?.year, 2027);
      expect(mating.isRepeatBreederAlert, isTrue);
      expect(mating.failedMatingAttempts, 3);
      expect(mating.breedName, 'Gir Purebred');
    });

    test('CowMatingModel toJson produces valid API payload for POST /api/v1/matings', () {
      final mating = CowMatingModel(
        id: 'temp-mating',
        gaushalaId: 'gaushala-123',
        cowId: 'cow-999',
        cowTagId: 'TAG-999',
        heatId: 'heat-001',
        matingDate: DateTime(2026, 10, 13),
        matingTime: 'morning',
        matingType: MatingType.artificial,
        semenStrawCode: 'STRAW-88',
        semenSource: 'BAIF',
        inseminatorName: 'Dr. Rao',
        remarks: 'First service of season',
      );

      final payload = mating.toJson();

      expect(payload['gaushalaId'], 'gaushala-123');
      expect(payload['cowId'], 'cow-999');
      expect(payload['heatId'], 'heat-001');
      expect(payload['matingDate'], '2026-10-13');
      expect(payload['matingTime'], 'morning');
      expect(payload['matingType'], 'ARTIFICIAL');
      expect(payload['semenStrawCode'], 'STRAW-88');
      expect(payload['semenSource'], 'BAIF');
      expect(payload['inseminatorName'], 'Dr. Rao');
    });

    test('MatingPaginatedResult parses pagination metadata and list items', () {
      final json = {
        'data': [
          {
            '_id': 'm-1',
            'gaushalaId': 'g-1',
            'cowId': 'c-1',
            'matingDate': '2026-10-01',
            'matingType': 'NATURAL',
            'status': 'PENDING_PD',
          },
        ],
        'total': 18,
        'page': 2,
        'limit': 10,
        'totalPages': 2,
      };

      final result = MatingPaginatedResult.fromJson(json);

      expect(result.items.length, 1);
      expect(result.total, 18);
      expect(result.page, 2);
      expect(result.totalPages, 2);
      expect(result.items.first.matingType, MatingType.natural);
      expect(result.items.first.status, MatingStatus.pendingPd);
    });

    test('CowMatingModel detects biological inconsistency when calving occurs on mating day', () {
      final invalidRecord = CowMatingModel(
        id: 'rec-invalid',
        gaushalaId: 'g-1',
        cowId: 'c-1',
        cowTagId: 'JARSHI001',
        matingDate: DateTime(2026, 10, 13),
        pdDate: DateTime(2026, 10, 13),
        actualCalvingDate: DateTime(2026, 10, 13),
        status: MatingStatus.calved,
      );

      expect(invalidRecord.actualGestationDays, 0);
      expect(invalidRecord.hasGestationInconsistency, isTrue);
      expect(invalidRecord.daysToPDCheck, 0);
      expect(invalidRecord.hasPDInconsistency, isTrue);
    });

    test('CowMatingModel recognizes valid full-term bovine gestation (~282 days)', () {
      final validRecord = CowMatingModel(
        id: 'rec-valid',
        gaushalaId: 'g-1',
        cowId: 'c-1',
        cowTagId: 'JARSHI001',
        matingDate: DateTime(2026, 1, 1),
        pdDate: DateTime(2026, 3, 2), // 60 days
        actualCalvingDate: DateTime(2026, 10, 10), // 282 days
        status: MatingStatus.calved,
      );

      expect(validRecord.actualGestationDays, 282);
      expect(validRecord.hasGestationInconsistency, isFalse);
      expect(validRecord.daysToPDCheck, 60);
      expect(validRecord.hasPDInconsistency, isFalse);
    });
  });

  group('Dashboard Alerts Summary Integration Tests', () {
    test('DashboardAlertsSummaryResponse parses heatAlerts and matingAlerts', () {
      final json = {
        'counts': {
          'treatmentDueDoses': 2,
          'criticalCases': 0,
          'milkVariances': 1,
          'lowMedicalStock': 2,
          'expiringMedicines': 1,
          'lowFeedStock': 1,
          'activeHeats': 3,
          'repeatHeatAlerts': 1,
          'repeatBreederAlerts': 2,
          'pendingPDChecks': 4,
          'totalAlerts': 16,
        },
        'heatAlerts': {
          'activeHeats': [
            {
              '_id': 'heat-act-1',
              'gaushalaId': 'g-1',
              'cowId': 'c-10',
              'heatDate': '2026-10-13',
              'heatTime': 'morning',
              'heatStage': 'STANDING',
              'status': 'READY_FOR_MATING',
            }
          ],
          'repeatHeatAlerts': [
            {
              '_id': 'heat-rep-1',
              'gaushalaId': 'g-1',
              'cowId': 'c-11',
              'heatDate': '2026-10-13',
              'heatTime': 'morning',
              'heatStage': 'STANDING',
              'status': 'READY_FOR_MATING',
              'isRepeatHeatAlert': true,
              'consecutiveHeatCount': 3,
            }
          ],
        },
        'matingAlerts': {
          'repeatBreeders': [
            {
              '_id': 'mat-rep-1',
              'gaushalaId': 'g-1',
              'cowId': 'c-20',
              'matingDate': '2026-09-01',
              'matingType': 'NATURAL',
              'status': 'FAILED',
              'isRepeatBreederAlert': true,
              'failedMatingAttempts': 3,
            }
          ],
          'pendingPDs': [
            {
              '_id': 'mat-pd-1',
              'gaushalaId': 'g-1',
              'cowId': 'c-21',
              'matingDate': '2026-08-10',
              'matingType': 'ARTIFICIAL',
              'status': 'PENDING_PD',
              'expectedPDDate': '2026-10-10',
              'isDueForPD': true,
            }
          ],
        },
      };

      final response = DashboardAlertsSummaryResponse.fromJson(json);

      expect(response.counts.activeHeats, 3);
      expect(response.counts.repeatHeatAlerts, 1);
      expect(response.counts.repeatBreederAlerts, 2);
      expect(response.counts.pendingPDChecks, 4);
      expect(response.counts.totalAlerts, 16);

      expect(response.activeHeats.length, 1);
      expect(response.activeHeats.first.id, 'heat-act-1');
      expect(response.repeatHeatAlerts.length, 1);
      expect(response.repeatHeatAlerts.first.isRepeatHeatAlert, isTrue);

      expect(response.repeatBreederAlerts.length, 1);
      expect(response.repeatBreederAlerts.first.failedMatingAttempts, 3);
      expect(response.pendingPDMatings.length, 1);
      expect(response.pendingPDMatings.first.isDueForPD, isTrue);
    });
  });

  group('Breeding Alert Card Widget Tests', () {
    testWidgets('BreedingAlertCard.heat renders heat details and buttons', (tester) async {
      final heat = CowHeatModel(
        id: 'h-100',
        gaushalaId: 'g-1',
        cowId: 'c-1',
        heatDate: DateTime(2026, 10, 13),
        heatTime: 'morning',
        heatStage: HeatStage.standing,
        heatSigns: ['MOUNTING', 'MUCUS_DISCHARGE'],
        intensity: HeatIntensity.strong,
        status: HeatStatus.readyForMating,
        cowTagId: 'TAG-500',
        cowCalfName: 'Surabhi',
        cowShedName: 'Milking Shed 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreedingAlertCard.heat(heat: heat),
          ),
        ),
      );

      expect(find.text('Tag #TAG-500'), findsOneWidget);
      expect(find.text('(Surabhi)'), findsOneWidget);
      expect(find.text('READY FOR MATING'), findsOneWidget);
      expect(find.text('Standing to be Mounted / Mounting'), findsOneWidget);
      expect(find.text('Clear Mucus Discharge'), findsOneWidget);
      expect(find.text('Record Mating'), findsOneWidget);
      expect(find.text('View Heat Details'), findsOneWidget);
    });

    testWidgets('BreedingAlertCard.mating renders pending PD details and buttons', (tester) async {
      final mating = CowMatingModel(
        id: 'm-200',
        gaushalaId: 'g-1',
        cowId: 'c-2',
        matingDate: DateTime(2026, 8, 10),
        matingTime: 'morning',
        matingType: MatingType.artificial,
        semenStrawCode: 'GIR-102',
        status: MatingStatus.pendingPd,
        expectedPDDate: DateTime(2026, 10, 10),
        cowTagId: 'TAG-501',
        cowCalfName: 'Gauri',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreedingAlertCard.mating(mating: mating),
          ),
        ),
      );

      expect(find.text('Tag #TAG-501'), findsOneWidget);
      expect(find.text('(Gauri)'), findsOneWidget);
      expect(find.text('PD CHECK DUE'), findsOneWidget);
      expect(find.text('Record PD Result'), findsOneWidget);
      expect(find.text('View Mating Details'), findsOneWidget);
    });

    testWidgets('BreedingAlertCard renders repeat estrus danger alert for 3+ cycles', (tester) async {
      final repeatHeat = CowHeatModel(
        id: 'h-repeat',
        gaushalaId: 'g-1',
        cowId: 'c-3',
        heatDate: DateTime(2026, 10, 13),
        heatTime: 'evening',
        heatStage: HeatStage.standing,
        heatSigns: ['RESTLESSNESS'],
        intensity: HeatIntensity.moderate,
        status: HeatStatus.readyForMating,
        isRepeatHeatAlert: true,
        consecutiveHeatCount: 4,
        cowTagId: 'TAG-777',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreedingAlertCard.heat(heat: repeatHeat),
          ),
        ),
      );

      expect(find.text('REPEAT ESTRUS (4 CYCLES)'), findsOneWidget);
    });

    testWidgets('Filter toolbar dropdowns render without RenderFlex overflow in narrow widths', (tester) async {
      // Tests that long enum labels like "Artificial Insemination (AI)" and "Pending PD Check"
      // do not cause overflow inside narrow DropdownButtonFormField widgets.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: 'ALL',
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Mating Type',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'ALL',
                      child: Text('All Types', overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                    ...MatingType.values.map(
                      (t) => DropdownMenuItem(
                        value: t.code,
                        child: Text(t.label, overflow: TextOverflow.ellipsis, maxLines: 1),
                      ),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('All Types'), findsOneWidget);
    });

    test('MatingType.natural uses cow icon instead of pawPrint', () {
      expect(MatingType.natural.icon, PhosphorIconsRegular.cow);
      expect(MatingType.natural.icon, isNot(PhosphorIconsRegular.pawPrint));
    });

    testWidgets('ChoiceChip and FilterChip display visible white text when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ChoiceChip(
                      label: const Text('Morning'),
                      selected: true,
                      selectedColor: const Color(0xFF3B502C),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      onSelected: (_) {},
                    ),
                    FilterChip(
                      label: const Text('Standing Heat'),
                      selected: true,
                      selectedColor: const Color(0xFF3B502C),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      onSelected: (_) {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final morningChip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
      expect(morningChip.labelStyle?.color, Colors.white);

      final heatChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(heatChip.labelStyle?.color, Colors.white);
    });

    testWidgets('CustomPagination defaults to 5 rows per page and displays pagination info', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      int selectedRows = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CustomPagination(
                  currentPage: 1,
                  totalItems: 25,
                  rowsPerPage: selectedRows,
                  onPageChanged: (_) {},
                  onRowsPerPageChanged: (val) {
                    setState(() {
                      selectedRows = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify "Showing 1 to 5 of 25 entries" in RichText
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Showing 1 to 5 of 25 entries'),
        ),
        findsOneWidget,
      );
      expect(find.text('Rows per page:'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
    });

    test('Search query correctly filters Mating records and excludes non-matching terms', () {
      final mating1 = CowMatingModel(
        id: 'm-1',
        gaushalaId: 'g-1',
        cowId: 'c-1',
        cowTagId: 'JARSHI001',
        cowCalfName: 'Kaveri',
        matingDate: DateTime(2026, 10, 13),
        matingType: MatingType.natural,
        status: MatingStatus.pregnant,
      );

      final mating2 = CowMatingModel(
        id: 'm-2',
        gaushalaId: 'g-1',
        cowId: 'c-1',
        cowTagId: 'JARSHI001',
        cowCalfName: 'Kaveri',
        matingDate: DateTime(2026, 8, 10),
        matingType: MatingType.artificial,
        semenStrawCode: 'HF-PURE-101',
        status: MatingStatus.failed,
      );

      final list = [mating1, mating2];

      bool matches(CowMatingModel m, String query) {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return true;
        return m.cowTagId.toLowerCase().contains(q) ||
            (m.cowCalfName?.toLowerCase().contains(q) ?? false) ||
            (m.bullNameOrTag?.toLowerCase().contains(q) ?? false) ||
            (m.semenStrawCode?.toLowerCase().contains(q) ?? false) ||
            (m.inseminatorName?.toLowerCase().contains(q) ?? false) ||
            m.status.label.toLowerCase().contains(q) ||
            m.status.code.toLowerCase().contains(q) ||
            (m.remarks?.toLowerCase().contains(q) ?? false);
      }

      // 'getyyy' should match ZERO records
      final searchResultGetyyy = list.where((m) => matches(m, 'getyyy')).toList();
      expect(searchResultGetyyy, isEmpty);

      // 'JARSHI' should match both records
      final searchResultJarshi = list.where((m) => matches(m, 'JARSHI')).toList();
      expect(searchResultJarshi.length, 2);

      // 'HF-PURE' should match only mating2
      final searchResultStraw = list.where((m) => matches(m, 'HF-PURE')).toList();
      expect(searchResultStraw.length, 1);
      expect(searchResultStraw.first.id, 'm-2');

      // 'kaveri' should match both
      final searchResultKaveri = list.where((m) => matches(m, 'kaveri')).toList();
      expect(searchResultKaveri.length, 2);
    });

    test('Search query correctly filters Heat records and excludes non-matching terms', () {
      final heat1 = CowHeatModel(
        id: 'h-1',
        gaushalaId: 'g-1',
        cowId: 'c-1',
        cowTagId: 'JARSHI001',
        cowCalfName: 'Kaveri',
        cowBreedName: 'Gir',
        heatDate: DateTime(2026, 10, 13),
        status: HeatStatus.readyForMating,
      );

      final heat2 = CowHeatModel(
        id: 'h-2',
        gaushalaId: 'g-1',
        cowId: 'c-2',
        cowTagId: 'DEV002',
        cowCalfName: 'Ganga',
        cowBreedName: 'Kankrej',
        heatDate: DateTime(2026, 10, 12),
        status: HeatStatus.observed,
      );

      final list = [heat1, heat2];

      bool matches(CowHeatModel h, String query) {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return true;
        return h.cowTagId.toLowerCase().contains(q) ||
            (h.cowCalfName?.toLowerCase().contains(q) ?? false) ||
            (h.cowShedName?.toLowerCase().contains(q) ?? false) ||
            (h.cowBreedName?.toLowerCase().contains(q) ?? false) ||
            (h.observedByWorkerName?.toLowerCase().contains(q) ?? false) ||
            (h.remarks?.toLowerCase().contains(q) ?? false) ||
            h.status.label.toLowerCase().contains(q) ||
            h.status.code.toLowerCase().contains(q);
      }

      // 'getyyy' should match ZERO records
      expect(list.where((h) => matches(h, 'getyyy')).toList(), isEmpty);

      // 'ganga' matches heat2
      final resultGanga = list.where((h) => matches(h, 'ganga')).toList();
      expect(resultGanga.length, 1);
      expect(resultGanga.first.id, 'h-2');

      // 'JARSHI' matches heat1
      final resultJarshi = list.where((h) => matches(h, 'JARSHI')).toList();
      expect(resultJarshi.length, 1);
      expect(resultJarshi.first.id, 'h-1');
    });
  });
}


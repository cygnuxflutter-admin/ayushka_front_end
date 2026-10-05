import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/data/models/dashboard_alerts_model.dart';
import 'package:ayushka/app/modules/dashboard/widgets/dashboard_kpi_strip.dart';
import 'package:ayushka/app/modules/dashboard/widgets/treatment_alert_card.dart';
import 'package:ayushka/app/modules/dashboard/widgets/milk_alert_card.dart';
import 'package:ayushka/app/modules/dashboard/widgets/medical_alert_card.dart';
import 'package:ayushka/app/modules/dashboard/widgets/feed_alert_card.dart';

void main() {
  group('Dashboard Alert Models Tests', () {
    test('DashboardAlertsSummaryResponse parsing from JSON', () {
      final json = {
        'counts': {
          'treatmentDueDoses': 3,
          'criticalCases': 1,
          'milkVariances': 2,
          'lowMedicalStock': 4,
          'expiringMedicines': 2,
          'lowFeedStock': 1,
          'totalAlerts': 13,
        },
        'treatmentAlerts': [
          {
            'treatmentId': 'treat-1',
            'cowTag': 'TAG-101',
            'calfName': 'Gauri',
            'shedNumber': 'Shed 1',
            'diseaseName': 'Mastitis',
            'severity': 'CRITICAL',
            'dueDoseNumber': 2,
            'totalDoses': 5,
            'nextDoseDate': '2026-10-03T10:00:00Z',
          }
        ],
        'milkAlerts': [
          {
            'notificationId': 'notif-1',
            'cowTag': 'TAG-204',
            'shift': 'MORNING',
            'message': 'Milk drop >15% detected',
            'createdAt': '2026-10-03T06:30:00Z',
          }
        ],
        'medicalAlerts': {
          'lowStock': [
            {
              'itemId': 'med-1',
              'itemName': 'Oxytetracycline',
              'category': 'INJECTION',
              'totalStock': 2.0,
              'minStockAlert': 10.0,
              'unit': 'VIAL',
            }
          ],
          'expiring': [
            {
              'itemId': 'med-2',
              'itemName': 'Paracetamol Bolus',
              'batchNumber': 'B104',
              'expiryDate': '2026-10-25T00:00:00Z',
              'daysRemaining': 22,
            }
          ],
        },
        'feedAlerts': [
          {
            'itemId': 'feed-1',
            'itemName': 'Green Fodder (Napier)',
            'currentStock': 40.0,
            'minStockAlert': 200.0,
            'unit': 'KG',
          }
        ],
      };

      final response = DashboardAlertsSummaryResponse.fromJson(json);

      expect(response.counts.treatmentDueDoses, 3);
      expect(response.counts.criticalCases, 1);
      expect(response.counts.milkVariances, 2);
      expect(response.counts.lowMedicalStock, 4);
      expect(response.counts.expiringMedicines, 2);
      expect(response.counts.lowFeedStock, 1);
      expect(response.counts.totalAlerts, 13);

      expect(response.treatmentAlerts.length, 1);
      expect(response.treatmentAlerts.first.cowTag, 'TAG-101');
      expect(response.treatmentAlerts.first.isCritical, isTrue);

      expect(response.milkAlerts.length, 1);
      expect(response.milkAlerts.first.cowTag, 'TAG-204');
      expect(response.milkAlerts.first.message, 'Milk drop >15% detected');

      expect(response.medicalLowStock.length, 1);
      expect(response.medicalLowStock.first.itemName, 'Oxytetracycline');

      expect(response.medicalExpiring.length, 1);
      expect(response.medicalExpiring.first.batchNumber, 'B104');
      expect(response.medicalExpiring.first.daysRemaining, 22);

      expect(response.feedAlerts.length, 1);
      expect(response.feedAlerts.first.itemName, 'Green Fodder (Napier)');
      expect(response.feedAlerts.first.currentStock, 40.0);
    });
  });

  group('Dashboard Widgets Tests', () {
    testWidgets('DashboardKpiStrip renders all 4 metric cards and responds to tab change', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DashboardKpiStrip(
                  counts: const DashboardAlertCounts(
                    treatmentDueDoses: 7,
                    criticalCases: 2,
                    milkVariances: 3,
                    lowMedicalStock: 4,
                    expiringMedicines: 1,
                    lowFeedStock: 2,
                    totalAlerts: 17,
                  ),
                  selectedTabIndex: selectedTab,
                  onTabSelected: (index) {
                    setState(() => selectedTab = index);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify counts and titles rendered in English
      expect(find.text('Treatment Doses Due'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('2 Critical Condition'), findsOneWidget);

      expect(find.text('Milk Drops Detected'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      expect(find.text('Medicines Low / Expiring'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // 4 + 1

      expect(find.text('Feed Stock Low'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Tap on Milk tab (index 1)
      await tester.tap(find.text('Milk Drops Detected'));
      await tester.pumpAndSettle();

      expect(selectedTab, 1);
    });

    testWidgets('TreatmentAlertCard renders correctly and triggers onAdminister', (tester) async {
      bool administered = false;

      final alert = TreatmentAlertItem(
        treatmentId: 'treat-1',
        cowTag: 'TAG-101',
        calfName: 'Lakshmi',
        shedNumber: 'Shed 3',
        diseaseName: 'Foot and Mouth Disease',
        severity: 'CRITICAL',
        dueDoseNumber: 3,
        totalDoses: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TreatmentAlertCard(
              alert: alert,
              onAdminister: () => administered = true,
            ),
          ),
        ),
      );

      expect(find.text('TAG-101'), findsOneWidget);
      expect(find.text('Lakshmi'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('Foot and Mouth Disease'), findsOneWidget);
      expect(find.text('Dose #3 of 5'), findsOneWidget);
      expect(find.text('Administer Dose'), findsOneWidget);

      await tester.tap(find.text('Administer Dose'));
      await tester.pump();

      expect(administered, isTrue);
    });

    testWidgets('MilkAlertCard renders alert message and triggers onDismiss', (tester) async {
      bool dismissed = false;

      final alert = MilkAlertItem(
        notificationId: 'notif-99',
        cowTag: 'COW-402',
        shift: 'EVENING',
        message: 'Milk drop detected: Evening yield was down by 18%',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilkAlertCard(
              alert: alert,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('COW-402'), findsOneWidget);
      expect(find.text('EVENING'), findsOneWidget);
      expect(find.text('Milk drop detected: Evening yield was down by 18%'), findsOneWidget);
      expect(find.text('Dismiss Alert'), findsOneWidget);

      await tester.tap(find.text('Dismiss Alert'));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('MedicalAlertCard renders low stock details and triggers inward callback', (tester) async {
      bool inwardClicked = false;

      final lowStockItem = MedicalLowStockAlertItem(
        itemId: 'med-7',
        itemName: 'Amoxicillin Trihydrate',
        category: 'ANTIBIOTIC',
        totalStock: 3.0,
        minStockAlert: 15.0,
        unit: 'VIAL',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalAlertCard(
              lowStockItem: lowStockItem,
              onQuickInward: () => inwardClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Amoxicillin Trihydrate'), findsOneWidget);
      expect(find.text('ANTIBIOTIC'), findsOneWidget);
      expect(find.text('LOW STOCK'), findsOneWidget);
      expect(find.text('Quick Inward'), findsOneWidget);

      await tester.tap(find.text('Quick Inward'));
      await tester.pump();

      expect(inwardClicked, isTrue);
    });

    testWidgets('FeedAlertCard renders feed stock details and triggers inward callback', (tester) async {
      bool feedInwardClicked = false;

      final feedAlert = FeedStockAlertItem(
        itemId: 'feed-8',
        itemName: 'Lucerne Grass',
        currentStock: 50.0,
        minStockAlert: 300.0,
        unit: 'KG',
        category: 'GREEN_FODDER',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedAlertCard(
              alert: feedAlert,
              onQuickInward: () => feedInwardClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Lucerne Grass'), findsOneWidget);
      expect(find.text('GREEN_FODDER'), findsOneWidget);
      expect(find.textContaining('SHORTFALL'), findsOneWidget);
      expect(find.text('Quick Inward'), findsOneWidget);

      await tester.tap(find.text('Quick Inward'));
      await tester.pump();

      expect(feedInwardClicked, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ayushka/app/core/utils/responsive_layout.dart';
import 'package:ayushka/app/core/widgets/custom_pagination.dart';
import 'package:ayushka/app/data/models/user_model.dart';
import 'package:ayushka/app/data/models/treatment_model.dart';
import 'package:ayushka/app/modules/dashboard/widgets/mobile_drawer.dart';
import 'package:ayushka/app/modules/treatment/widgets/dose_timeline_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile & Multi-Breakpoint UI Responsiveness Tests', () {
    const mobileWidths = [320.0, 360.0, 375.0, 390.0, 414.0];
    const tabletWidths = [768.0, 1024.0];
    const desktopWidths = [1280.0, 1440.0];

    testWidgets('ResponsiveLayout selects correct builders across all required breakpoints', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 800.0);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveLayout(
              mobileBuilder: (ctx) => const Text('MobileView'),
              tabletBuilder: (ctx) => const Text('TabletView'),
              desktopBuilder: (ctx) => const Text('DesktopView'),
            ),
          ),
        );
        expect(find.text('MobileView'), findsOneWidget, reason: 'Failed at width $width');
        expect(find.text('DesktopView'), findsNothing);
      }

      for (final width in tabletWidths) {
        tester.view.physicalSize = Size(width, 900.0);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveLayout(
              mobileBuilder: (ctx) => const Text('MobileView'),
              tabletBuilder: (ctx) => const Text('TabletView'),
              desktopBuilder: (ctx) => const Text('DesktopView'),
            ),
          ),
        );
        expect(find.text('TabletView'), findsOneWidget, reason: 'Failed at width $width');
      }

      for (final width in desktopWidths) {
        tester.view.physicalSize = Size(width, 900.0);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveLayout(
              mobileBuilder: (ctx) => const Text('MobileView'),
              tabletBuilder: (ctx) => const Text('TabletView'),
              desktopBuilder: (ctx) => const Text('DesktopView'),
            ),
          ),
        );
        expect(find.text('DesktopView'), findsOneWidget, reason: 'Failed at width $width');
      }
    });

    testWidgets('CustomPagination renders without RenderFlex overflow across all mobile screen widths (320px - 414px)', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 700.0);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomPagination(
                  totalItems: 125,
                  currentPage: 1,
                  rowsPerPage: 10,
                  onPageChanged: (_) {},
                  onRowsPerPageChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CustomPagination), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Overflow occurred on width $width');
      }
    });

    testWidgets('MobileDrawer fits and scrolls smoothly without overflow across 320px - 414px', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final user = UserModel(
        id: 'USR-MOBILE',
        name: 'Gaupalak Senior Admin',
        email: 'gaupalak@gaushala.org',
        role: 'Farm Admin',
      );

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 950.0);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              drawer: MobileDrawer(
                currentUser: user,
                onLogout: () {},
              ),
              body: const Text('Body'),
            ),
          ),
        );

        final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.byType(MobileDrawer), findsOneWidget);
        expect(find.text('Gaupalak Senior Admin'), findsOneWidget);
        expect(find.text('MASTER CATALOGS'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Overflow in drawer on width $width');

        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('DoseTimelineWidget renders without overflow across 320px - 414px and desktop', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleTreatment = CowTreatmentModel(
        id: 'TRT-001',
        treatmentNumber: 'TRT-2026-001',
        gaushalaId: 'GAU-01',
        cowId: 'COW-01',
        cowTagId: 'TAG-8821',
        cowCalfName: 'Nandini',
        cowBreedName: 'Gir',
        diseaseName: 'Mastitis Acute',
        doctorName: 'Dr. Rameshchandra Mukhopadhyay',
        severity: TreatmentSeverity.critical,
        status: TreatmentStatus.underTreatment,
        totalDoses: 5,
        completedDoses: 2,
        nextDoseDate: DateTime.now(),
        nextDoseNumber: 3,
        doses: [
          TreatmentDoseModel(
            id: 'DOSE-1',
            doseNumber: 1,
            status: DoseStatus.given,
            scheduledDate: DateTime.now().subtract(const Duration(days: 2)),
            administeredDate: DateTime.now().subtract(const Duration(days: 2)),
            administeredBy: 'Dr. Rameshchandra',
            medicines: const [
              DoseMedicineModel(
                medicineName: 'Amoxicillin Fortified',
                dosage: '25 ml',
                isStockItem: true,
              ),
            ],
          ),
          TreatmentDoseModel(
            id: 'DOSE-2',
            doseNumber: 2,
            status: DoseStatus.given,
            scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
            administeredDate: DateTime.now().subtract(const Duration(days: 1)),
            administeredBy: 'Dr. Rameshchandra',
            medicines: const [
              DoseMedicineModel(
                medicineName: 'Flunixin Meglumine',
                dosage: '15 ml',
                isStockItem: true,
              ),
            ],
          ),
          TreatmentDoseModel(
            id: 'DOSE-3',
            doseNumber: 3,
            status: DoseStatus.pending,
            scheduledDate: DateTime.now(),
            medicines: const [
              DoseMedicineModel(
                medicineName: 'Ceftiofur Sodium Sterile',
                dosage: '20 ml',
                isStockItem: true,
              ),
            ],
          ),
        ],
      );

      // Verify mobile widths
      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 850.0);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DoseTimelineWidget(
                  treatment: sampleTreatment,
                  onAdministerDose: (_) {},
                  isMobile: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DoseTimelineWidget), findsOneWidget);
        expect(find.text('Protocol Progress:'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'DoseTimelineWidget overflowed at $width px');
      }

      // Verify desktop width remains intact
      tester.view.physicalSize = const Size(1280.0, 900.0);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: DoseTimelineWidget(
                treatment: sampleTreatment,
                onAdministerDose: (_) {},
                isMobile: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DoseTimelineWidget), findsOneWidget);
      expect(find.text('Protocol Progress:'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'DoseTimelineWidget overflowed at 1280 px');
    });

    testWidgets('Treatment details profile pills row wraps without overflow on 320px screen', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      tester.view.physicalSize = const Size(320.0, 700.0);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 18,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: const Text('TAG-8821'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: const Text('Nandini'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: const Text('Gir Cattle'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: const Text('North Shed A'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: const Text('380 kg'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TAG-8821'), findsOneWidget);
      expect(find.text('380 kg'), findsOneWidget);
    });

    testWidgets('Milk module alert notification card layout renders with zero RenderFlex overflow on 320px - 414px', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 700.0);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top line: Alert Icon, Cow Tag, Drop Badge, and TimeAgo on the far right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.warning_amber_rounded, size: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  child: const Text('Cow #GIR03'),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  child: const Text('-22% Drop'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('2h ago'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Middle line: Shift Badge, Yield Transition, and View Details button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  child: const Text('Morning'),
                                ),
                                const Text('(13.5 L ➔ 10.5 L)'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View Details'),
                                SizedBox(width: 3),
                                Icon(Icons.open_in_new_rounded, size: 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Bottom line: Message description
                      const Text(
                        'Cow GIR03 dropped yield from 13.5L to 10.5L (-22.2%) in Morning shift. Immediate inspection recommended.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Alert card overflowed on width $width px');
        expect(find.text('Cow #GIR03'), findsOneWidget);
        expect(find.text('-22% Drop'), findsOneWidget);
        expect(find.text('View Details'), findsOneWidget);
      }
    });

    testWidgets('Milk module quick actions strip (+ Yield, + Distribute, + Waste) fits side-by-side on 320px mobile', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 700.0);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('+ Yield'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('+ Distribute'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('+ Waste'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Quick actions strip overflowed on width $width px');
        expect(find.text('+ Yield'), findsOneWidget);
        expect(find.text('+ Distribute'), findsOneWidget);
        expect(find.text('+ Waste'), findsOneWidget);
      }
    });

    testWidgets('Milk module production card layout renders cleanly without overflow on 320px - 414px', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 700.0);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  child: const Text('GIR-042'),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text('Gauri', overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            child: const Text('Morning'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('14.5 L'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: const Text('Normal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Ramesh Patel', overflow: TextOverflow.ellipsis),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text('Regular milking', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Production card overflowed on width $width px');
        expect(find.text('GIR-042'), findsOneWidget);
        expect(find.text('14.5 L'), findsOneWidget);
      }
    });

    testWidgets('Milk module distribution card layout renders cleanly without overflow on 320px - 414px', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 700.0);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 15),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Kailash Dairy Store', overflow: TextOverflow.ellipsis),
                                      Text('Regular Customer', overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            child: const Text('Morning'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('12.0 L'),
                              Text('₹65.00 / L'),
                            ],
                          ),
                          Text('₹780.00'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('2026-10-03', overflow: TextOverflow.ellipsis),
                          ),
                          SizedBox(width: 8),
                          Text('Direct Shift'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Distribution card overflowed on width $width px');
        expect(find.text('Kailash Dairy Store'), findsOneWidget);
        expect(find.text('₹780.00'), findsOneWidget);
      }
    });
  });
}

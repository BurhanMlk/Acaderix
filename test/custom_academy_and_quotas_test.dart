import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/admissions/application/student_repository_provider.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/admissions/domain/student_repository.dart';
import 'package:academy_management/features/admissions/presentation/screens/add_student_screen.dart';
import 'package:academy_management/features/branches/application/branch_repository_provider.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/branches/domain/branch_repository.dart';
import 'package:academy_management/features/branches/presentation/screens/add_branch_screen.dart';
import 'package:academy_management/features/super_admin/application/academy_repository_provider.dart';
import 'package:academy_management/features/super_admin/domain/academy.dart';
import 'package:academy_management/features/super_admin/domain/academy_repository.dart';
import 'package:academy_management/features/super_admin/domain/subscription_models.dart';
import 'package:academy_management/features/super_admin/presentation/screens/create_custom_academy_screen.dart';
import 'package:academy_management/shared/current_academy_provider.dart';

class _FakeAcademyRepo implements AcademyRepository {
  final List<Map<String, dynamic>> customCreatedAcademies = [];

  @override
  Stream<List<Academy>> watchAll() => Stream.value([]);
  @override
  Future<List<Academy>> getAll() async => [];
  @override
  Future<Academy?> getById(String id) async => null;
  @override
  Future<void> create(Academy academy) async {}
  @override
  Future<void> updateStatus(String id, String status) async {}
  @override
  Future<void> updateOwnerEmail(String id, String newEmail) async {}
  @override
  Future<void> delete(String id) async {}

  @override
  Future<String> createCustomAcademyWithPackage({
    required String academyName,
    required String academyCode,
    required String address,
    required String city,
    required String province,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerPhone,
    required int maxBranches,
    required int maxStudents,
    required int monthlyFee,
    String billingCycle = 'monthly',
    String status = 'active',
    String paymentStatus = 'paid',
    String? logoUrl,
    String? cnic,
  }) async {
    customCreatedAcademies.add({
      'academyName': academyName,
      'academyCode': academyCode,
      'address': address,
      'city': city,
      'province': province,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPassword': ownerPassword,
      'ownerPhone': ownerPhone,
      'maxBranches': maxBranches,
      'maxStudents': maxStudents,
      'monthlyFee': monthlyFee,
      'billingCycle': billingCycle,
      'status': status,
      'paymentStatus': paymentStatus,
    });
    return 'custom_acad_123';
  }
}

class _FakeBranchRepo implements BranchRepository {
  final List<Branch> branches = [];

  @override
  Stream<List<Branch>> watchAll(String academyId) => Stream.value(branches);
  @override
  Future<void> create(Branch branch) async => branches.add(branch);
  @override
  Future<void> update(Branch branch) async {}
  @override
  Future<void> delete(String academyId, String branchId) async {}
}

class _FakeStudentRepo implements StudentRepository {
  final List<Student> students = [];

  @override
  Stream<List<Student>> watchAll(String academyId) => Stream.value(students);
  @override
  Future<Student?> getById(String academyId, String studentId) async => null;
  @override
  Future<void> create(Student student) async => students.add(student);
  @override
  Future<void> update(Student student) async {}
  @override
  Future<void> delete(String academyId, String studentId) async {}
  @override
  Future<String> allocateRollNumber(String academyId) async => 'RN-101';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Custom Academy Model Tests', () {
    test('AcademySubscription serializes and deserializes custom quotas', () {
      final sub = AcademySubscription(
        id: 'sub_1',
        academyId: 'acad_1',
        academyName: 'Al-Hadi Science Academy',
        academyCode: 'AHSA',
        planId: 'custom',
        planName: 'Custom Package',
        price: 25000,
        status: 'active',
        startDate: DateTime(2026, 11, 1),
        renewalDate: DateTime(2026, 12, 1),
        maxBranches: 3,
        maxStudents: 350,
      );

      final json = sub.toJson();
      expect(json['maxBranches'], 3);
      expect(json['maxStudents'], 350);
      expect(json['price'], 25000);

      final restored = AcademySubscription.fromJson('sub_1', json);
      expect(restored.maxBranches, 3);
      expect(restored.maxStudents, 350);
      expect(restored.price, 25000);
      expect(restored.planName, 'Custom Package');
    });

    test('AcademyAccessInfo contains custom package quotas', () {
      const access = AcademyAccessInfo(
        state: AcademyAccessState.active,
        academyId: 'acad_1',
        maxBranches: 2,
        maxStudents: 150,
        planPrice: 18000,
        planName: 'Custom Package',
      );

      expect(access.maxBranches, 2);
      expect(access.maxStudents, 150);
      expect(access.planPrice, 18000);
      expect(access.isActive, isTrue);
    });
  });

  group('CreateCustomAcademyScreen Widget Tests', () {
    testWidgets('renders properly on small mobile screen without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAcademyRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CreateCustomAcademyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll all the way down to verify every widget renders without overflow
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all fields, generates code, and creates custom academy',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAcademyRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CreateCustomAcademyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sections are visible
      expect(find.text('Create Custom Academy'), findsOneWidget);
      expect(find.text('Academy Details'), findsOneWidget);
      expect(find.text('Academy Owner Credentials'), findsOneWidget);
      expect(find.text('Custom Package Quotas & Billing'), findsOneWidget);

      // Verify auto-generated code exists in the text field
      final codeField = find.widgetWithText(TextFormField, 'Academy Code');
      expect(codeField, findsOneWidget);

      // Fill in Academy details
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Academy Name'), 'Apex College');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Address / Street'),
          'Gulberg Main Blvd');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'City'), 'Lahore');

      // Fill in Owner credentials
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Owner Full Name'),
          'Prof. Usman Tariq');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Owner Login Email'),
          'usman@apex.edu.pk');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Login Password'), 'secret123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone / WhatsApp'),
          '03001234567');

      // Scroll to package quotas
      await tester.drag(
          find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Fill in custom quotas
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Allowed Branches'), '3');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Allowed Students'), '450');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monthly Fee (Rupees / PKR)'),
          '28000');

      // Submit
      await tester.tap(find.text('Create Academy & Owner Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify repository was called with custom details
      expect(fakeRepo.customCreatedAcademies.length, 1);
      final created = fakeRepo.customCreatedAcademies.first;
      expect(created['academyName'], 'Apex College');
      expect(created['ownerEmail'], 'usman@apex.edu.pk');
      expect(created['ownerPassword'], 'secret123');
      expect(created['maxBranches'], 3);
      expect(created['maxStudents'], 450);
      expect(created['monthlyFee'], 28000);

      // Verify Credentials Confirmation Slip Dialog is shown
      expect(find.text('Academy & Owner Created!'), findsOneWidget);
      expect(find.text('Apex College'), findsWidgets);
      expect(find.text('usman@apex.edu.pk'), findsWidgets);
      expect(find.text('3 branch(es)'), findsOneWidget);
      expect(find.text('450 students'), findsOneWidget);
      expect(find.text('PKR 28000'), findsOneWidget);
      expect(find.text('Copy Slip'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    });
  });

  group('Quota Enforcement Tests', () {
    testWidgets(
        'AddBranchScreen blocks creation when custom package branch quota is reached',
        (tester) async {
      final fakeBranchRepo = _FakeBranchRepo();
      const academyId = 'test_acad_quota';

      // 1 existing branch registered
      final existingBranch = Branch(
        id: 'branch_1',
        academyId: academyId,
        name: 'Main Campus',
        city: 'Lahore',
        isActive: true,
      );

      // Access indicates custom package limit is 1 branch
      final accessInfo = Stream.value(const AcademyAccessInfo(
        state: AcademyAccessState.active,
        academyId: academyId,
        maxBranches: 1, // Only 1 branch allowed!
        maxStudents: 100,
        planName: 'Custom Package',
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(academyId),
            academyAccessProvider.overrideWith((ref) => accessInfo),
            branchesStreamProvider(academyId)
                .overrideWith((ref) => Stream.value([existingBranch])),
            branchRepositoryProvider.overrideWithValue(fakeBranchRepo),
          ],
          child: const MaterialApp(
            home: AddBranchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Limit Reached banner is displayed
      expect(find.textContaining('Campus Limit Reached (1/1 registered)'),
          findsOneWidget);
      expect(find.text('Limit Reached'), findsOneWidget);

      // Ensure creation is blocked
      expect(fakeBranchRepo.branches.isEmpty, isTrue);
    });

    testWidgets(
        'AddStudentScreen blocks admission when custom package student quota is reached',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeStudentRepo = _FakeStudentRepo();
      const academyId = 'test_acad_quota';

      // 2 existing students registered
      final existingStudents = [
        Student(
          id: 's_1',
          academyId: academyId,
          fullName: 'Ali Raza',
          fatherName: 'Raza',
          guardianPhone: '03001',
          rollNumber: '101',
          admissionDate: DateTime.now(),
        ),
        Student(
          id: 's_2',
          academyId: academyId,
          fullName: 'Bilal Khan',
          fatherName: 'Khan',
          guardianPhone: '03002',
          rollNumber: '102',
          admissionDate: DateTime.now(),
        ),
      ];

      // Custom package capacity is 2 students
      final accessInfo = Stream.value(const AcademyAccessInfo(
        state: AcademyAccessState.active,
        academyId: academyId,
        maxBranches: 2,
        maxStudents: 2, // Only 2 students allowed!
        planName: 'Custom Package',
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(academyId),
            academyAccessProvider.overrideWith((ref) => accessInfo),
            studentsStreamProvider(academyId)
                .overrideWith((ref) => Stream.value(existingStudents)),
            studentRepositoryProvider.overrideWithValue(fakeStudentRepo),
          ],
          child: const MaterialApp(
            home: AddStudentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Capacity Reached warning banner is displayed
      expect(find.textContaining('Student Capacity Reached (2/2 enrolled)'),
          findsOneWidget);
      expect(find.text('Capacity Reached'), findsOneWidget);

      // Ensure no student was admitted
      expect(fakeStudentRepo.students.isEmpty, isTrue);
    });
  });
}

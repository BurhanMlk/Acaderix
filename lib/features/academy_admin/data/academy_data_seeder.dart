import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/domain/attendance_calculator.dart';
import '../../../core/network/firebase_services.dart';
import '../../../core/network/firestore_ext.dart';
import '../../academics/domain/course.dart';
import '../../admissions/domain/student.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../branches/domain/branch.dart';
import '../../exams/domain/exam.dart';
import '../../exams/domain/exam_result.dart';
import '../../fees/domain/fee_invoice.dart';
import '../../fees/domain/fee_payment.dart';
import '../../staff/domain/staff.dart';

/// Riverpod provider for [AcademyDataSeeder].
final academyDataSeederProvider = Provider<AcademyDataSeeder>(
  (ref) => AcademyDataSeeder(ref.watch(firestoreProvider)),
);

/// Seeds realistic demo students and associated academic records into Firestore.
class AcademyDataSeeder {
  AcademyDataSeeder(this._firestore);

  final FirebaseFirestore _firestore;

  /// Populates 5 diverse students, staff, attendance, fee invoices, payments,
  /// exams, and branch records for [academyId].
  Future<void> seedAcademyData(String academyId, {bool force = false}) async {
    if (academyId.isEmpty) return;

    final studentsRef =
        _firestore.collection(FirestorePaths.students(academyId));
    if (!force) {
      final existingSnap = await studentsRef.limit(1).get();
      if (existingSnap.docs.isNotEmpty) {
        // Academy already has student records
        return;
      }
    }

    final batch = _firestore.batch();

    // 1. Five diverse students across classes
    final students = [
      Student(
        id: 'stu_100001',
        academyId: academyId,
        fullName: 'Muhammad Ali',
        fatherName: 'Tariq Ali',
        guardianPhone: '+92 301 2345678',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100001',
        gender: 'Male',
        dateOfBirth: DateTime(2009, 3, 15),
        admissionDate: DateTime.now().subtract(const Duration(days: 60)),
        address: 'Sector F-8/2, Islamabad',
        status: 'active',
        notes: 'Pre-Medical Group · Class 10th',
      ),
      Student(
        id: 'stu_100002',
        academyId: academyId,
        fullName: 'Fatima Zahra',
        fatherName: 'Syed Qasim',
        guardianPhone: '+92 302 3456789',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100002',
        gender: 'Female',
        dateOfBirth: DateTime(2009, 7, 22),
        admissionDate: DateTime.now().subtract(const Duration(days: 55)),
        address: 'Street 4, Gulberg, Lahore',
        status: 'active',
        notes: 'Pre-Engineering Group · Class 10th',
      ),
      Student(
        id: 'stu_100003',
        academyId: academyId,
        fullName: 'Hamza Ahmed',
        fatherName: 'Naveed Ahmed',
        guardianPhone: '+92 303 4567890',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100003',
        gender: 'Male',
        dateOfBirth: DateTime(2010, 11, 5),
        admissionDate: DateTime.now().subtract(const Duration(days: 40)),
        address: 'DHA Phase 5, Karachi',
        status: 'active',
        notes: 'Computer Science Group · Class 9th',
      ),
      Student(
        id: 'stu_100004',
        academyId: academyId,
        fullName: 'Ayesha Khan',
        fatherName: 'Imran Khan',
        guardianPhone: '+92 304 5678901',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100004',
        gender: 'Female',
        dateOfBirth: DateTime(2010, 1, 18),
        admissionDate: DateTime.now().subtract(const Duration(days: 30)),
        address: 'Satellite Town, Rawalpindi',
        status: 'active',
        notes: 'Science Group · Class 9th',
      ),
      Student(
        id: 'stu_100005',
        academyId: academyId,
        fullName: 'Zayd Bilal',
        fatherName: 'Bilal Farooq',
        guardianPhone: '+92 305 6789012',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100005',
        gender: 'Male',
        dateOfBirth: DateTime(2011, 9, 9),
        admissionDate: DateTime.now().subtract(const Duration(days: 15)),
        address: 'Model Town, Faisalabad',
        status: 'active',
        notes: 'Junior Section · Class 8th',
      ),
    ];

    for (final s in students) {
      batch.set(
        studentsRef.doc(s.id),
        toFirestoreData(s.toJson())..remove('id'),
      );
    }

    // 2. Roll number counter update
    final counterRef = _firestore.doc(
      '${FirestorePaths.counters(academyId)}/roll_number',
    );
    batch.set(counterRef, {'value': 100005}, SetOptions(merge: true));

    // 3. Main campus branch
    final branchesRef =
        _firestore.collection(FirestorePaths.branches(academyId));
    final branch = Branch(
      id: 'br_main',
      academyId: academyId,
      name: 'Main Campus',
      address: 'Plot 14-A, Blue Area',
      city: 'Islamabad',
      phone: '+92 51 111 222 333',
      isActive: true,
    );
    batch.set(
      branchesRef.doc(branch.id),
      toFirestoreData(branch.toJson())..remove('id'),
    );

    // 4. Staff faculty records
    final staffRef = _firestore.collection(FirestorePaths.staff(academyId));
    final staffList = [
      Staff(
        id: 'stf_01',
        academyId: academyId,
        staffId: 'STF-1001',
        password: 'Staff@1001',
        fullName: 'Sir Tariq Mehmood',
        phone: '+92 312 9876543',
        email: 'tariq.math@acaderix.com',
        jobTitle: 'Senior Mathematics Faculty',
        salary: 65000,
        joiningDate: DateTime(2025, 8, 1),
        branchId: branch.id,
        status: 'active',
      ),
      Staff(
        id: 'stf_02',
        academyId: academyId,
        staffId: 'STF-1002',
        password: 'Staff@1002',
        fullName: 'Dr. Amina Qureshi',
        phone: '+92 313 8765432',
        email: 'amina.physics@acaderix.com',
        jobTitle: 'Head of Science Department',
        salary: 75000,
        joiningDate: DateTime(2025, 6, 15),
        branchId: branch.id,
        status: 'active',
      ),
    ];
    for (final stf in staffList) {
      batch.set(
        staffRef.doc(stf.id),
        toFirestoreData(stf.toJson())..remove('id'),
      );
      batch.set(
        _firestore.collection('staff_accounts').doc(stf.staffId),
        {
          'staffId': stf.staffId,
          'staffDocId': stf.id,
          'academyId': stf.academyId,
          'branchId': stf.branchId,
          'fullName': stf.fullName,
          'email': stf.email,
          'password': stf.password,
          'status': stf.status,
        },
      );
    }

    // 5. Courses & Batches
    final coursesRef = _firestore.collection(FirestorePaths.courses(academyId));
    final courses = [
      Course(
        id: 'crs_101',
        academyId: academyId,
        branchId: branch.id,
        name: 'Physics 10th - Batch A',
        courseCode: 'PHY-101',
        teacherId: staffList[0].id,
        teacherName: staffList[0].fullName,
        enrolledStudentIds: [students[0].id, students[1].id, students[2].id],
        schedule: 'Mon, Wed, Fri • 4:00 PM - 5:30 PM',
        room: 'Room 1',
        fee: 6500,
      ),
      Course(
        id: 'crs_102',
        academyId: academyId,
        branchId: branch.id,
        name: 'Mathematics 10th - Batch B',
        courseCode: 'MTH-102',
        teacherId: staffList[1].id,
        teacherName: staffList[1].fullName,
        enrolledStudentIds: [students[2].id, students[3].id, students[4].id],
        schedule: 'Tue, Thu, Sat • 5:30 PM - 7:00 PM',
        room: 'Room 2',
        fee: 7000,
      ),
      Course(
        id: 'crs_103',
        academyId: academyId,
        branchId: branch.id,
        name: 'Computer Science 9th',
        courseCode: 'CS-901',
        teacherId: staffList[0].id,
        teacherName: staffList[0].fullName,
        enrolledStudentIds: [students[0].id, students[2].id, students[4].id],
        schedule: 'Mon, Wed • 2:30 PM - 4:00 PM',
        room: 'Lab 1',
        fee: 8000,
      ),
    ];
    for (final crs in courses) {
      batch.set(
        coursesRef.doc(crs.id),
        toFirestoreData(crs.toJson())..remove('id'),
      );
    }

    // 6. Daily Attendance for students (course-scoped)
    final attRef = _firestore.collection(FirestorePaths.attendance(academyId));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = today.toIso8601String().substring(0, 10);
    final attStatuses = [
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.present,
      AttendanceStatus.absent,
    ];
    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      final record = AttendanceRecord(
        id: '${s.id}_crs_101_$dateKey',
        academyId: academyId,
        courseId: 'crs_101',
        markedById: staffList[0].id,
        studentId: s.id,
        date: today,
        status: attStatuses[i],
      );
      batch.set(
        attRef.doc('${s.id}_crs_101_$dateKey'),
        toFirestoreData(record.toJson())..remove('id'),
      );
    }

    // 7. Fee Invoices and Payments
    final invRef = _firestore.collection(FirestorePaths.feeInvoices(academyId));
    final payRef = _firestore.collection(FirestorePaths.feePayments(academyId));
    final invoices = [
      FeeInvoice(
        id: 'inv_1001',
        academyId: academyId,
        studentId: students[0].id,
        invoiceNo: 'INV-1001',
        title: 'Tuition Fee - October 2026',
        baseAmount: 8000,
        paidAmount: 8000,
        status: 'paid',
        issuedAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
      ),
      FeeInvoice(
        id: 'inv_1002',
        academyId: academyId,
        studentId: students[1].id,
        invoiceNo: 'INV-1002',
        title: 'Tuition Fee - October 2026',
        baseAmount: 8000,
        paidAmount: 8000,
        status: 'paid',
        issuedAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
      ),
      FeeInvoice(
        id: 'inv_1003',
        academyId: academyId,
        studentId: students[2].id,
        invoiceNo: 'INV-1003',
        title: 'Tuition Fee - October 2026',
        baseAmount: 7500,
        paidAmount: 4000,
        status: 'partial',
        issuedAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
      ),
      FeeInvoice(
        id: 'inv_1004',
        academyId: academyId,
        studentId: students[3].id,
        invoiceNo: 'INV-1004',
        title: 'Tuition Fee - October 2026',
        baseAmount: 7500,
        paidAmount: 0,
        status: 'unpaid',
        issuedAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
      ),
    ];
    for (final inv in invoices) {
      batch.set(
        invRef.doc(inv.id),
        toFirestoreData(inv.toJson())..remove('id'),
      );
    }

    final payment1 = FeePayment(
      id: 'pay_2001',
      academyId: academyId,
      invoiceId: 'inv_1001',
      studentId: students[0].id,
      amount: 8000,
      method: 'Bank Transfer',
      reference: 'REC-501',
      paidAt: DateTime.now().subtract(const Duration(days: 8)),
    );
    batch.set(
      payRef.doc(payment1.id),
      toFirestoreData(payment1.toJson())..remove('id'),
    );

    // 7. Exam and Results
    final examsRef = _firestore.collection(FirestorePaths.exams(academyId));
    final resultsRef = _firestore.collection(FirestorePaths.results(academyId));
    final exam1 = Exam(
      id: 'ex_3001',
      academyId: academyId,
      name: 'Midterm Examination 2026',
      totalMarks: 100,
      examDate: DateTime.now().subtract(const Duration(days: 5)),
    );
    batch.set(
      examsRef.doc(exam1.id),
      toFirestoreData(exam1.toJson())..remove('id'),
    );

    final results = [
      ExamResult(
        id: 'res_4001',
        academyId: academyId,
        examId: exam1.id,
        studentId: students[0].rollNumber,
        obtainedMarks: 92,
        totalMarks: 100,
        grade: 'A+',
        passed: true,
        isPublished: true,
      ),
      ExamResult(
        id: 'res_4002',
        academyId: academyId,
        examId: exam1.id,
        studentId: students[1].rollNumber,
        obtainedMarks: 88,
        totalMarks: 100,
        grade: 'A',
        passed: true,
        isPublished: true,
      ),
      ExamResult(
        id: 'res_4003',
        academyId: academyId,
        examId: exam1.id,
        studentId: students[2].rollNumber,
        obtainedMarks: 74,
        totalMarks: 100,
        grade: 'B',
        passed: true,
        isPublished: true,
      ),
      ExamResult(
        id: 'res_4004',
        academyId: academyId,
        examId: exam1.id,
        studentId: students[3].rollNumber,
        obtainedMarks: 81,
        totalMarks: 100,
        grade: 'A',
        passed: true,
        isPublished: true,
      ),
      ExamResult(
        id: 'res_4005',
        academyId: academyId,
        examId: exam1.id,
        studentId: students[4].rollNumber,
        obtainedMarks: 58,
        totalMarks: 100,
        grade: 'C',
        passed: true,
        isPublished: true,
      ),
    ];
    for (final res in results) {
      batch.set(
        resultsRef.doc(res.id),
        toFirestoreData(res.toJson())..remove('id'),
      );
    }

    await batch.commit();
  }
}

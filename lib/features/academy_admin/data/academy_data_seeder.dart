import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/domain/attendance_calculator.dart';
import '../../../core/network/firebase_services.dart';
import '../../../core/network/firestore_ext.dart';
import '../../../core/utils/security_utils.dart';
import '../../academics/domain/course.dart';
import '../../admissions/domain/student.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../branches/domain/branch.dart';
import '../../exams/domain/exam.dart';
import '../../exams/domain/exam_result.dart';
import '../../fees/domain/fee_invoice.dart';
import '../../fees/domain/fee_payment.dart';
import '../../staff/domain/staff.dart';
import '../../communication/domain/announcement.dart';
import '../../communication/domain/inquiry.dart';

/// Riverpod provider for [AcademyDataSeeder].
final academyDataSeederProvider = Provider<AcademyDataSeeder>(
  (ref) => AcademyDataSeeder(ref.watch(firestoreProvider)),
);

/// Seeds realistic demo students, courses, staff, and associated academic records into Firestore
/// matching the multi-branch, teacher-led course attendance architecture.
class AcademyDataSeeder {
  AcademyDataSeeder(this._firestore);

  final FirebaseFirestore _firestore;

  /// Deletes all existing subcollections and demo records for [academyId] to ensure a clean slate.
  Future<void> clearAcademyData(String academyId) async {
    if (academyId.isEmpty) return;

    // Clean up staff_accounts linked to this academy
    try {
      final staffSnap =
          await _firestore.collection(FirestorePaths.staff(academyId)).get();
      for (final doc in staffSnap.docs) {
        final staffId = doc.data()['staffId'] as String?;
        if (staffId != null && staffId.isNotEmpty) {
          await _firestore.collection('staff_accounts').doc(staffId).delete();
        }
      }
    } catch (_) {}

    // Clean up student_accounts linked to this academy
    try {
      final studentSnap =
          await _firestore.collection(FirestorePaths.students(academyId)).get();
      for (final doc in studentSnap.docs) {
        final q = await _firestore
            .collection('student_accounts')
            .where('studentDocId', isEqualTo: doc.id)
            .get();
        for (final d in q.docs) {
          await d.reference.delete();
        }
      }
    } catch (_) {}

    // Clean up all core subcollections
    final collections = [
      FirestorePaths.students(academyId),
      FirestorePaths.staff(academyId),
      FirestorePaths.branches(academyId),
      FirestorePaths.courses(academyId),
      FirestorePaths.attendance(academyId),
      FirestorePaths.feeInvoices(academyId),
      FirestorePaths.feePayments(academyId),
      FirestorePaths.exams(academyId),
      FirestorePaths.results(academyId),
      FirestorePaths.announcements(academyId),
      FirestorePaths.inquiries(academyId),
      FirestorePaths.notifications(academyId),
    ];

    for (final path in collections) {
      try {
        final snap = await _firestore.collection(path).get();
        if (snap.docs.isNotEmpty) {
          final deleteBatch = _firestore.batch();
          for (final doc in snap.docs) {
            deleteBatch.delete(doc.reference);
          }
          await deleteBatch.commit();
        }
      } catch (_) {}
    }
  }

  /// Wipes existing academy data and seeds fresh records matching the latest course architecture.
  Future<void> resetAndSeedAcademyData(String academyId) async {
    await clearAcademyData(academyId);
    await seedAcademyData(academyId, force: true);
  }

  /// Populates realistic campuses, students, assigned staff, courses, and course-scoped
  /// attendance records for [academyId].
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

    // 0. Resolve & Register Academy Code mapping
    String academyCode = 'ACD-900';
    try {
      final acadSnap = await _firestore
          .collection(FirestorePaths.academies)
          .doc(academyId)
          .get();
      if (acadSnap.exists) {
        academyCode =
            (acadSnap.data()?['code'] as String? ?? 'ACD-900').toUpperCase();
      }
    } catch (_) {}

    batch.set(
      _firestore.collection(FirestorePaths.academyCodes).doc(academyCode),
      {'academyId': academyId},
      SetOptions(merge: true),
    );

    // 1. Multi-Branch Campuses
    final branchesRef =
        _firestore.collection(FirestorePaths.branches(academyId));
    final branches = [
      Branch(
        id: 'br_main',
        academyId: academyId,
        name: 'Main Campus',
        address: 'Plot 14-A, Blue Area',
        city: 'Islamabad',
        phone: '+92 51 111 222 333',
        isActive: true,
      ),
      Branch(
        id: 'br_city',
        academyId: academyId,
        name: 'City Campus',
        address: 'Main Murree Road, Saddar',
        city: 'Rawalpindi',
        phone: '+92 51 444 555 666',
        isActive: true,
      ),
    ];
    for (final b in branches) {
      batch.set(
        branchesRef.doc(b.id),
        toFirestoreData(b.toJson())..remove('id'),
      );
    }

    // 2. Staff Faculty (with Staff IDs & Login credentials)
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
        branchId: branches[0].id,
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
        branchId: branches[0].id,
        status: 'active',
      ),
      Staff(
        id: 'stf_03',
        academyId: academyId,
        staffId: 'STF-1003',
        password: 'Staff@1003',
        fullName: 'Sir Usman Ali',
        phone: '+92 314 7654321',
        email: 'usman.cs@acaderix.com',
        jobTitle: 'Computer Science Specialist',
        salary: 60000,
        joiningDate: DateTime(2025, 9, 1),
        branchId: branches[1].id,
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
          'password': SecurityUtils.hashPassword(stf.password),
          'status': stf.status,
        },
      );
    }

    // 3. Students assigned to respective branches
    final students = [
      Student(
        id: 'stu_100001',
        academyId: academyId,
        branchId: branches[0].id,
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
        branchId: branches[0].id,
        fullName: 'Fatima Zahra',
        fatherName: 'Syed Qasim',
        guardianPhone: '+92 302 3456789',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100002',
        gender: 'Female',
        dateOfBirth: DateTime(2009, 7, 22),
        admissionDate: DateTime.now().subtract(const Duration(days: 55)),
        address: 'Street 4, Gulberg, Islamabad',
        status: 'active',
        notes: 'Pre-Engineering Group · Class 10th',
      ),
      Student(
        id: 'stu_100003',
        academyId: academyId,
        branchId: branches[0].id,
        fullName: 'Hamza Ahmed',
        fatherName: 'Naveed Ahmed',
        guardianPhone: '+92 303 4567890',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100003',
        gender: 'Male',
        dateOfBirth: DateTime(2010, 11, 5),
        admissionDate: DateTime.now().subtract(const Duration(days: 40)),
        address: 'Sector G-10, Islamabad',
        status: 'active',
        notes: 'Science Group · Class 10th',
      ),
      Student(
        id: 'stu_100004',
        academyId: academyId,
        branchId: branches[1].id,
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
        branchId: branches[1].id,
        fullName: 'Zayd Bilal',
        fatherName: 'Bilal Farooq',
        guardianPhone: '+92 305 6789012',
        guardianRelation: 'Father',
        academicSession: '2026-2027',
        rollNumber: '100005',
        gender: 'Male',
        dateOfBirth: DateTime(2011, 9, 9),
        admissionDate: DateTime.now().subtract(const Duration(days: 15)),
        address: 'Westridge, Rawalpindi',
        status: 'active',
        notes: 'Computer Science · Class 9th',
      ),
    ];
    for (final s in students) {
      batch.set(
        studentsRef.doc(s.id),
        toFirestoreData(s.toJson())..remove('id')..['pin'] = SecurityUtils.hashPin('1234'),
      );
      batch.set(
        _firestore
            .collection('student_accounts')
            .doc('${academyCode}_${s.rollNumber}'),
        {
          'academyCode': academyCode,
          'academyId': academyId,
          'studentDocId': s.id,
          'rollNumber': s.rollNumber,
          'fullName': s.fullName,
          'branchId': s.branchId,
          'pin': SecurityUtils.hashPin('1234'),
          'status': s.status,
        },
      );
    }

    // 4. Update Counters
    final rollCounterRef = _firestore.doc(
      '${FirestorePaths.counters(academyId)}/roll_number',
    );
    batch.set(rollCounterRef, {'value': 100005}, SetOptions(merge: true));

    final staffCounterRef = _firestore.doc(
      '${FirestorePaths.counters(academyId)}/staff_id',
    );
    batch.set(staffCounterRef, {'value': 1003}, SetOptions(merge: true));

    // 5. Courses & Batches (Teacher-Assigned & Branch-Scoped)
    final coursesRef = _firestore.collection(FirestorePaths.courses(academyId));
    final courses = [
      Course(
        id: 'crs_101',
        academyId: academyId,
        branchId: branches[0].id,
        name: 'Physics 10th - Batch A',
        courseCode: 'PHY-101',
        teacherId: staffList[1].id, // Dr. Amina Qureshi
        teacherName: staffList[1].fullName,
        enrolledStudentIds: [students[0].id, students[1].id, students[2].id],
        schedule: 'Mon, Wed, Fri • 4:00 PM - 5:30 PM',
        room: 'Lab 1',
        fee: 6500,
      ),
      Course(
        id: 'crs_102',
        academyId: academyId,
        branchId: branches[0].id,
        name: 'Mathematics 10th - Batch B',
        courseCode: 'MTH-102',
        teacherId: staffList[0].id, // Sir Tariq Mehmood
        teacherName: staffList[0].fullName,
        enrolledStudentIds: [students[0].id, students[1].id, students[2].id],
        schedule: 'Tue, Thu, Sat • 5:30 PM - 7:00 PM',
        room: 'Room 2',
        fee: 7000,
      ),
      Course(
        id: 'crs_103',
        academyId: academyId,
        branchId: branches[1].id,
        name: 'Computer Science 9th',
        courseCode: 'CS-901',
        teacherId: staffList[2].id, // Sir Usman Ali
        teacherName: staffList[2].fullName,
        enrolledStudentIds: [students[3].id, students[4].id],
        schedule: 'Mon, Wed • 2:30 PM - 4:00 PM',
        room: 'IT Lab',
        fee: 8000,
      ),
    ];
    for (final crs in courses) {
      batch.set(
        coursesRef.doc(crs.id),
        toFirestoreData(crs.toJson())..remove('id'),
      );
    }

    // 6. Course-Scoped Attendance Records
    // crs_101 (Dr. Amina Qureshi) has been submitted today by the teacher.
    // crs_102 (Sir Tariq Mehmood) is PENDING today to demonstrate compliance audit.
    // crs_103 (Sir Usman Ali) has also been submitted today.
    final attRef = _firestore.collection(FirestorePaths.attendance(academyId));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateKey = today.toIso8601String().substring(0, 10);

    // crs_101 attendance records:
    final crs101Records = [
      AttendanceRecord(
        id: '${students[0].id}_crs_101_$dateKey',
        academyId: academyId,
        courseId: 'crs_101',
        markedById: staffList[1].id,
        studentId: students[0].id,
        date: today,
        status: AttendanceStatus.present,
      ),
      AttendanceRecord(
        id: '${students[1].id}_crs_101_$dateKey',
        academyId: academyId,
        courseId: 'crs_101',
        markedById: staffList[1].id,
        studentId: students[1].id,
        date: today,
        status: AttendanceStatus.present,
      ),
      AttendanceRecord(
        id: '${students[2].id}_crs_101_$dateKey',
        academyId: academyId,
        courseId: 'crs_101',
        markedById: staffList[1].id,
        studentId: students[2].id,
        date: today,
        status: AttendanceStatus.late,
      ),
    ];
    for (final rec in crs101Records) {
      batch.set(
        attRef.doc(rec.id),
        toFirestoreData(rec.toJson())..remove('id'),
      );
    }

    // crs_103 attendance records:
    final crs103Records = [
      AttendanceRecord(
        id: '${students[3].id}_crs_103_$dateKey',
        academyId: academyId,
        courseId: 'crs_103',
        markedById: staffList[2].id,
        studentId: students[3].id,
        date: today,
        status: AttendanceStatus.present,
      ),
      AttendanceRecord(
        id: '${students[4].id}_crs_103_$dateKey',
        academyId: academyId,
        courseId: 'crs_103',
        markedById: staffList[2].id,
        studentId: students[4].id,
        date: today,
        status: AttendanceStatus.absent,
      ),
    ];
    for (final rec in crs103Records) {
      batch.set(
        attRef.doc(rec.id),
        toFirestoreData(rec.toJson())..remove('id'),
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

    // 8. Exams and Results
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

    // Seed realistic announcements
    final announcementsRef =
        _firestore.collection(FirestorePaths.announcements(academyId));
    final demoAnnouncements = [
      Announcement(
        id: 'ann_5001',
        academyId: academyId,
        title: 'Midterm Examination Schedule Released',
        content:
            'The date sheet and syllabus guidelines for the upcoming Midterm examinations are now published. All students are advised to review the timetable.',
        audience: 'all',
        priority: 'urgent',
        category: 'academic',
        authorName: 'Academy Administration',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isPinned: true,
      ),
      Announcement(
        id: 'ann_5002',
        academyId: academyId,
        title: 'Science & Robotics Exhibition Next Friday',
        content:
            'Calling all young innovators! Submit your team project briefs for next Friday\'s Science & Innovation showcase.',
        audience: 'students',
        priority: 'normal',
        category: 'event',
        authorName: 'Head of Academics',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    for (final ann in demoAnnouncements) {
      batch.set(
        announcementsRef.doc(ann.id),
        toFirestoreData(ann.toJson())..remove('id'),
      );
    }

    // Seed sample student inquiry and teacher answer
    final inquiriesRef =
        _firestore.collection(FirestorePaths.inquiries(academyId));
    final demoInquiry = StudentInquiry(
      id: 'inq_6001',
      academyId: academyId,
      studentId: students[0].id,
      studentName: students[0].fullName,
      studentRollNumber: students[0].rollNumber,
      teacherId: staffList[0].id,
      teacherName: staffList[0].fullName,
      courseId: 'crs_2001',
      courseName: 'Advanced Mathematics - Grade 10',
      subject: 'Clarification regarding Chapter 4 Exercise 4.2',
      question:
          'Respected Sir, could you please clarify how question 5 should be derived? Do we need to apply the quadratic theorem or factoring?',
      reply:
          'Hello Muhammad! Factoring is acceptable, but applying the quadratic formula provides full working marks in the board exam rubric.',
      status: 'answered',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      answeredAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    batch.set(
      inquiriesRef.doc(demoInquiry.id),
      toFirestoreData(demoInquiry.toJson())..remove('id'),
    );

    await batch.commit();
  }
}

/**
 * Production-ready Firestore database cleanup and seeding script.
 *
 * Populates 8 academies across diverse statuses (active, pending, suspended),
 * creates branches, staff (with salted SHA-256 hashed passwords), students
 * (with salted SHA-256 hashed PINs), course enrollments, previous 5-day attendance records,
 * fee invoices, subscriptions, and platform broadcasts.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');

const PROJECT_ID = 'acaderix-64a5c';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const PASSWORD_SALT = 'acaderix_salt_pwd_v2026_#984!';
const PIN_SALT = 'acaderix_salt_pin_v2026_#412!';

function hashPassword(pwd) {
  const clean = pwd.trim();
  if (!clean) return '';
  return crypto.createHash('sha256').update(`${PASSWORD_SALT}:${clean}`).digest('hex');
}

function hashPin(pin) {
  const clean = pin.trim();
  if (!clean) return '';
  return crypto.createHash('sha256').update(`${PIN_SALT}:${clean}`).digest('hex');
}

// Convert native JS values to Firestore REST API typed values
function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (typeof val === 'string') {
    // Check if ISO string
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(val)) {
      return { timestampValue: val };
    }
    return { stringValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (k === 'id') continue; // ID belongs to document path
    fields[k] = toFirestoreValue(v);
  }
  return fields;
}

async function main() {
  console.log('🚀 Connecting to Firestore for project:', PROJECT_ID);

  const configPath = 'C:/Users/Anonymous/.config/configstore/firebase-tools.json';
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase tools configuration not found at ${configPath}`);
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const client = new OAuth2Client();
  client.setCredentials(config.tokens);

  async function request(endpoint, options = {}) {
    const url = endpoint.startsWith('http') ? endpoint : `${BASE_URL}/${endpoint}`;
    return client.request({ url, ...options });
  }

  async function writeDoc(docPath, data) {
    const fields = toFirestoreFields(data);
    const url = `${BASE_URL}/${docPath}`;
    return request(url, {
      method: 'PATCH',
      data: { fields },
    });
  }

  async function deleteDoc(docPath) {
    try {
      await request(`${BASE_URL}/${docPath}`, { method: 'DELETE' });
    } catch (_) {}
  }

  async function listCollectionDocs(collectionPath) {
    try {
      const res = await request(collectionPath);
      return (res.data.documents || []).map(d => d.name.replace(`projects/${PROJECT_ID}/databases/(default)/documents/`, ''));
    } catch (_) {
      return [];
    }
  }

  console.log('🧹 Clearing legacy test and demo records from Firestore...');

  // 1. Delete legacy documents from top-level collections
  const collectionsToClear = [
    'student_accounts',
    'staff_accounts',
    'academy_codes',
    'subscriptions',
    'subscription_plans',
    'subscription_payments',
    'support_tickets',
    'broadcasts',
  ];

  for (const col of collectionsToClear) {
    const docs = await listCollectionDocs(col);
    for (const doc of docs) {
      await deleteDoc(doc);
    }
  }

  // 2. Clear old academy subcollections
  const existingAcademies = await listCollectionDocs('academies');
  const subcollections = [
    'branches', 'courses', 'staff', 'students', 'attendance',
    'fee_invoices', 'fee_payments', 'exams', 'results',
    'announcements', 'inquiries', 'notifications'
  ];

  for (const acadPath of existingAcademies) {
    for (const sub of subcollections) {
      const subDocs = await listCollectionDocs(`${acadPath}/${sub}`);
      for (const d of subDocs) {
        await deleteDoc(d);
      }
    }
    // Delete the academy document itself
    await deleteDoc(acadPath);
  }
  console.log('✅ Firestore wipe complete. All legacy records cleared.');

  // 3. Seed Subscription Plans
  console.log('📦 Seeding default subscription plans...');
  const plans = [
    {
      id: 'basic',
      name: 'Basic',
      price: 10000,
      billingPeriod: 'month',
      maxStudents: 200,
      maxBranches: 1,
      isPopular: false,
      features: [
        'Up to 200 Students',
        'Single Campus / Branch',
        'Student Attendance Tracking',
        'Monthly Fee Invoices & Receipts',
        'Basic Academic Performance Reports',
      ],
    },
    {
      id: 'standard',
      name: 'Standard',
      price: 15000,
      billingPeriod: 'month',
      maxStudents: 500,
      maxBranches: 3,
      isPopular: true,
      features: [
        'Up to 500 Students',
        'Up to 3 Campus Branches',
        'Exams & Gradebook Management',
        'Staff & Teacher Attendance',
        'Salaries & Expense Tracking',
        'Automated Invoicing & SMS Alerts',
      ],
    },
    {
      id: 'premium',
      name: 'Premium',
      price: 20000,
      billingPeriod: 'month',
      maxStudents: -1,
      maxBranches: -1,
      isPopular: false,
      features: [
        'Unlimited Students & Batches',
        'Unlimited Campus Branches',
        'Comprehensive Multi-Branch Rollup Analytics',
        'Custom SMS Gateway & Priority Alerts',
        'Staff Payroll & Dynamic Commission Rules',
        '24/7 Dedicated Account Manager & VIP Support',
      ],
    },
  ];

  for (const p of plans) {
    await writeDoc(`subscription_plans/${p.id}`, p);
  }

  // Dates for the previous 5 days (excluding today 2026-11-02 to comply with advance guardrail)
  const previous5Days = [
    new Date('2026-11-01T00:00:00Z'),
    new Date('2026-10-31T00:00:00Z'),
    new Date('2026-10-30T00:00:00Z'),
    new Date('2026-10-29T00:00:00Z'),
    new Date('2026-10-28T00:00:00Z'),
  ];

  const attendanceStatuses = ['present', 'present', 'present', 'late', 'absent'];

  // 4. Define 8 Academies (5 active, 2 pending, 1 suspended)
  const academiesConfig = [
    {
      id: 'YtZZVD5vKTRqEk2s8NT3',
      name: 'Apex International Academy',
      code: 'ACD-7KN6N',
      status: 'active',
      planId: 'premium',
      planName: 'Premium',
      price: 20000,
      ownerUid: 'y0fRjfDd49S4xosQTob6PkKnpWp2',
      ownerName: 'Anonymous Dominator',
      ownerEmail: 'anonymousdominators@gmail.com',
      ownerPhone: '+92 312 1212312',
      address: 'Street 14, Sector F-8/2',
      city: 'Islamabad',
      province: 'Islamabad Capital Territory',
      branchCount: 2,
      branches: [
        { id: 'br_apex_1', name: 'F-8 Main Campus', address: 'Street 14, Sector F-8/2', city: 'Islamabad', phone: '+92 51 2284910' },
        { id: 'br_apex_2', name: 'Rawalpindi Saddar Branch', address: 'Haider Road, Saddar', city: 'Rawalpindi', phone: '+92 51 5567812' },
      ],
      staff: [
        { id: 'stf_apex_1', staffId: 'STF-101', name: 'Prof. Tariq Mehmood', email: 'tariq.apex@gmail.com', phone: '+92 301 5551111', jobTitle: 'Head of Physics', branchId: 'br_apex_1', salary: 95000 },
        { id: 'stf_apex_2', staffId: 'STF-102', name: 'Dr. Ayesha Siddiqui', email: 'ayesha.apex@gmail.com', phone: '+92 302 5552222', jobTitle: 'Senior Lecturer Chemistry', branchId: 'br_apex_1', salary: 90000 },
        { id: 'stf_apex_3', staffId: 'STF-103', name: 'Sir Bilal Ahmed', email: 'bilal.apex@gmail.com', phone: '+92 303 5553333', jobTitle: 'Mathematics Faculty', branchId: 'br_apex_2', salary: 85000 },
        { id: 'stf_apex_4', staffId: 'STF-104', name: 'Ms. Zainab Fatima', email: 'zainab.apex@gmail.com', phone: '+92 304 5554444', jobTitle: 'English Faculty', branchId: 'br_apex_2', salary: 75000 },
      ],
      students: [
        { id: 'stu_apex_1', name: 'Muhammad Hamza', roll: '10001', phone: '+92 321 0001111', branchId: 'br_apex_1' },
        { id: 'stu_apex_2', name: 'Fatima Zahra', roll: '10002', phone: '+92 321 0002222', branchId: 'br_apex_1' },
        { id: 'stu_apex_3', name: 'Zaid Tariq', roll: '10003', phone: '+92 321 0003333', branchId: 'br_apex_1' },
        { id: 'stu_apex_4', name: 'Aiman Noor', roll: '10004', phone: '+92 321 0004444', branchId: 'br_apex_1' },
        { id: 'stu_apex_5', name: 'Abdullah Qasim', roll: '10005', phone: '+92 321 0005555', branchId: 'br_apex_2' },
        { id: 'stu_apex_6', name: 'Maryam Bilal', roll: '10006', phone: '+92 321 0006666', branchId: 'br_apex_2' },
        { id: 'stu_apex_7', name: 'Usman Farooq', roll: '10007', phone: '+92 321 0007777', branchId: 'br_apex_2' },
        { id: 'stu_apex_8', name: 'Hiba Rehman', roll: '10008', phone: '+92 321 0008888', branchId: 'br_apex_2' },
      ],
      courses: [
        { id: 'crs_apex_1', name: 'Physics 10th - Batch A', code: 'PHY-101', teacherId: 'stf_apex_1', teacherName: 'Prof. Tariq Mehmood', branchId: 'br_apex_1', enrolled: ['stu_apex_1', 'stu_apex_2', 'stu_apex_3', 'stu_apex_4'], schedule: 'Mon, Wed, Fri • 4:00 PM' },
        { id: 'crs_apex_2', name: 'Chemistry 10th - Batch A', code: 'CHM-102', teacherId: 'stf_apex_2', teacherName: 'Dr. Ayesha Siddiqui', branchId: 'br_apex_1', enrolled: ['stu_apex_1', 'stu_apex_2', 'stu_apex_3', 'stu_apex_4'], schedule: 'Tue, Thu, Sat • 4:00 PM' },
        { id: 'crs_apex_3', name: 'Mathematics 9th - Morning', code: 'MTH-201', teacherId: 'stf_apex_3', teacherName: 'Sir Bilal Ahmed', branchId: 'br_apex_2', enrolled: ['stu_apex_5', 'stu_apex_6', 'stu_apex_7', 'stu_apex_8'], schedule: 'Mon, Wed, Fri • 9:00 AM' },
        { id: 'crs_apex_4', name: 'English Grammar & Comp', code: 'ENG-101', teacherId: 'stf_apex_4', teacherName: 'Ms. Zainab Fatima', branchId: 'br_apex_2', enrolled: ['stu_apex_5', 'stu_apex_6', 'stu_apex_7', 'stu_apex_8'], schedule: 'Tue, Thu • 11:00 AM' },
      ],
    },
    {
      id: 'acad_beacon_8787',
      name: 'Beacon Heights Academy',
      code: 'BHA-878',
      status: 'active',
      planId: 'standard',
      planName: 'Standard',
      price: 15000,
      ownerUid: 'zaKSXVFa8IWHJJomli1oqoZjQff2',
      ownerName: 'Umer Farooq',
      ownerEmail: 'useeusee8787@gmail.com',
      ownerPhone: '+92 300 7654321',
      address: 'Main Boulevard Gulberg III',
      city: 'Lahore',
      province: 'Punjab',
      branchCount: 2,
      branches: [
        { id: 'br_bha_1', name: 'Gulberg Campus', address: 'Main Boulevard Gulberg III', city: 'Lahore', phone: '+92 42 3578912' },
        { id: 'br_bha_2', name: 'Blue Area Campus', address: 'Fazal-e-Haq Road', city: 'Islamabad', phone: '+92 51 2894120' },
      ],
      staff: [
        { id: 'stf_bha_1', staffId: 'STF-201', name: 'Dr. Khalid Mehmood', email: 'khalid.beacon@gmail.com', phone: '+92 300 1114444', jobTitle: 'Senior Biology Specialist', branchId: 'br_bha_1', salary: 92000 },
        { id: 'stf_bha_2', staffId: 'STF-202', name: 'Ms. Rabia Shah', email: 'rabia.beacon@gmail.com', phone: '+92 300 2225555', jobTitle: 'Advanced Mathematics', branchId: 'br_bha_1', salary: 88000 },
        { id: 'stf_bha_3', staffId: 'STF-203', name: 'Sir Kamran Gill', email: 'kamran.beacon@gmail.com', phone: '+92 300 3336666', jobTitle: 'English & Verbal Skills', branchId: 'br_bha_2', salary: 80000 },
      ],
      students: [
        { id: 'stu_bha_1', name: 'Saad Rafique', roll: '20001', phone: '+92 333 1110001', branchId: 'br_bha_1' },
        { id: 'stu_bha_2', name: 'Anum Khurram', roll: '20002', phone: '+92 333 1110002', branchId: 'br_bha_1' },
        { id: 'stu_bha_3', name: 'Bilal Javed', roll: '20003', phone: '+92 333 1110003', branchId: 'br_bha_1' },
        { id: 'stu_bha_4', name: 'Khadija Imran', roll: '20004', phone: '+92 333 1110004', branchId: 'br_bha_2' },
        { id: 'stu_bha_5', name: 'Danyal Asif', roll: '20005', phone: '+92 333 1110005', branchId: 'br_bha_2' },
        { id: 'stu_bha_6', name: 'Laiba Naveed', roll: '20006', phone: '+92 333 1110006', branchId: 'br_bha_2' },
      ],
      courses: [
        { id: 'crs_bha_1', name: 'MDCAT Biology Intensive', code: 'BIO-501', teacherId: 'stf_bha_1', teacherName: 'Dr. Khalid Mehmood', branchId: 'br_bha_1', enrolled: ['stu_bha_1', 'stu_bha_2', 'stu_bha_3'], schedule: 'Mon, Wed, Fri • 5:00 PM' },
        { id: 'crs_bha_2', name: 'Calculus & Algebra Fast Track', code: 'MTH-402', teacherId: 'stf_bha_2', teacherName: 'Ms. Rabia Shah', branchId: 'br_bha_1', enrolled: ['stu_bha_1', 'stu_bha_2', 'stu_bha_3'], schedule: 'Tue, Thu • 5:00 PM' },
        { id: 'crs_bha_3', name: 'IELTS & Business English', code: 'ENG-303', teacherId: 'stf_bha_3', teacherName: 'Sir Kamran Gill', branchId: 'br_bha_2', enrolled: ['stu_bha_4', 'stu_bha_5', 'stu_bha_6'], schedule: 'Mon, Thu • 3:00 PM' },
      ],
    },
    {
      id: 'acad_crescent_101',
      name: 'Crescent Science Academy',
      code: 'CSA-102',
      status: 'active',
      planId: 'standard',
      planName: 'Standard',
      price: 15000,
      ownerUid: 'uid_csa_admin',
      ownerName: 'Dr. Mansoor Ali',
      ownerEmail: 'admin@crescentacademy.edu.pk',
      ownerPhone: '+92 42 35841234',
      address: 'Main Boulevard Johar Town',
      city: 'Lahore',
      province: 'Punjab',
      branchCount: 2,
      branches: [
        { id: 'br_csa_1', name: 'Johar Town Main Campus', address: 'Plot 45, Johar Town', city: 'Lahore', phone: '+92 42 35841234' },
        { id: 'br_csa_2', name: 'Model Town Branch', address: 'Block C, Model Town', city: 'Lahore', phone: '+92 42 35129876' },
      ],
      staff: [
        { id: 'stf_csa_1', staffId: 'STF-301', name: 'Engr. Haris Mumtaz', email: 'haris.csa@gmail.com', phone: '+92 311 4441111', jobTitle: 'Senior Physics Coach', branchId: 'br_csa_1', salary: 88000 },
        { id: 'stf_csa_2', staffId: 'STF-302', name: 'Mrs. Saima Jameel', email: 'saima.csa@gmail.com', phone: '+92 311 4442222', jobTitle: 'Organic Chemistry Expert', branchId: 'br_csa_1', salary: 85000 },
        { id: 'stf_csa_3', staffId: 'STF-303', name: 'Prof. Noman Qureshi', email: 'noman.csa@gmail.com', phone: '+92 311 4443333', jobTitle: 'Applied Mathematics Lead', branchId: 'br_csa_2', salary: 90000 },
      ],
      students: [
        { id: 'stu_csa_1', name: 'Ahmed Raza', roll: '30001', phone: '+92 345 1110001', branchId: 'br_csa_1' },
        { id: 'stu_csa_2', name: 'Iqra Pervez', roll: '30002', phone: '+92 345 1110002', branchId: 'br_csa_1' },
        { id: 'stu_csa_3', name: 'Fahad Mustafa', roll: '30003', phone: '+92 345 1110003', branchId: 'br_csa_1' },
        { id: 'stu_csa_4', name: 'Nimra Sheikh', roll: '30004', phone: '+92 345 1110004', branchId: 'br_csa_2' },
        { id: 'stu_csa_5', name: 'Zubair Akram', roll: '30005', phone: '+92 345 1110005', branchId: 'br_csa_2' },
        { id: 'stu_csa_6', name: 'Sana Malik', roll: '30006', phone: '+92 345 1110006', branchId: 'br_csa_2' },
      ],
      courses: [
        { id: 'crs_csa_1', name: 'ECAT Physics Foundation', code: 'PHY-601', teacherId: 'stf_csa_1', teacherName: 'Engr. Haris Mumtaz', branchId: 'br_csa_1', enrolled: ['stu_csa_1', 'stu_csa_2', 'stu_csa_3'], schedule: 'Mon, Wed • 6:00 PM' },
        { id: 'crs_csa_2', name: 'FSc Chemistry Masterclass', code: 'CHM-602', teacherId: 'stf_csa_2', teacherName: 'Mrs. Saima Jameel', branchId: 'br_csa_1', enrolled: ['stu_csa_1', 'stu_csa_2', 'stu_csa_3'], schedule: 'Tue, Thu • 6:00 PM' },
        { id: 'crs_csa_3', name: 'Intermediate Mathematics', code: 'MTH-503', teacherId: 'stf_csa_3', teacherName: 'Prof. Noman Qureshi', branchId: 'br_csa_2', enrolled: ['stu_csa_4', 'stu_csa_5', 'stu_csa_6'], schedule: 'Mon, Wed, Fri • 4:00 PM' },
      ],
    },
    {
      id: 'acad_alquds_202',
      name: 'Al-Quds Grammar School & Academy',
      code: 'AQG-204',
      status: 'active',
      planId: 'basic',
      planName: 'Basic',
      price: 10000,
      ownerUid: 'uid_aqg_admin',
      ownerName: 'Qari Abdul Rehman',
      ownerEmail: 'principal@alquds.edu.pk',
      ownerPhone: '+92 21 36671234',
      address: 'Block L, North Nazimabad',
      city: 'Karachi',
      province: 'Sindh',
      branchCount: 1,
      branches: [
        { id: 'br_aqg_1', name: 'North Nazimabad Campus', address: 'Block L, North Nazimabad', city: 'Karachi', phone: '+92 21 36671234' },
      ],
      staff: [
        { id: 'stf_aqg_1', staffId: 'STF-401', name: 'Maulana Asif Raza', email: 'asif.aqg@gmail.com', phone: '+92 322 1112222', jobTitle: 'Arabic & Islamic Studies', branchId: 'br_aqg_1', salary: 70000 },
        { id: 'stf_aqg_2', staffId: 'STF-402', name: 'Sir Owais Qazi', email: 'owais.aqg@gmail.com', phone: '+92 322 3334444', jobTitle: 'General Science & Math', branchId: 'br_aqg_1', salary: 72000 },
      ],
      students: [
        { id: 'stu_aqg_1', name: 'Hassan Ali', roll: '40001', phone: '+92 331 2220001', branchId: 'br_aqg_1' },
        { id: 'stu_aqg_2', name: 'Zainab Bano', roll: '40002', phone: '+92 331 2220002', branchId: 'br_aqg_1' },
        { id: 'stu_aqg_3', name: 'Bilal Hussain', roll: '40003', phone: '+92 331 2220003', branchId: 'br_aqg_1' },
        { id: 'stu_aqg_4', name: 'Kalsoom Bibi', roll: '40004', phone: '+92 331 2220004', branchId: 'br_aqg_1' },
        { id: 'stu_aqg_5', name: 'Yousuf Khan', roll: '40005', phone: '+92 331 2220005', branchId: 'br_aqg_1' },
      ],
      courses: [
        { id: 'crs_aqg_1', name: 'Islamic Theology & Arabic', code: 'ARB-101', teacherId: 'stf_aqg_1', teacherName: 'Maulana Asif Raza', branchId: 'br_aqg_1', enrolled: ['stu_aqg_1', 'stu_aqg_2', 'stu_aqg_3'], schedule: 'Mon, Tue, Wed • 8:30 AM' },
        { id: 'crs_aqg_2', name: 'Matric Science Essentials', code: 'SCI-201', teacherId: 'stf_aqg_2', teacherName: 'Sir Owais Qazi', branchId: 'br_aqg_1', enrolled: ['stu_aqg_3', 'stu_aqg_4', 'stu_aqg_5'], schedule: 'Thu, Fri, Sat • 10:00 AM' },
      ],
    },
    {
      id: 'acad_iqra_303',
      name: 'Iqra Excellence College & Academy',
      code: 'IEC-305',
      status: 'active',
      planId: 'premium',
      planName: 'Premium',
      price: 20000,
      ownerUid: 'uid_iec_admin',
      ownerName: 'Hafiz Muhammad Qasim',
      ownerEmail: 'admissions@iqraexcellence.edu.pk',
      ownerPhone: '+92 21 35891234',
      address: 'Khayaban-e-Shamsheer, DHA Phase 5',
      city: 'Karachi',
      province: 'Sindh',
      branchCount: 3,
      branches: [
        { id: 'br_iec_1', name: 'DHA Phase 5 Campus', address: 'Khayaban-e-Shamsheer, Phase 5', city: 'Karachi', phone: '+92 21 35891234' },
        { id: 'br_iec_2', name: 'Gulshan Campus', address: 'Block 6, Gulshan-e-Iqbal', city: 'Karachi', phone: '+92 21 34981234' },
        { id: 'br_iec_3', name: 'Saddar Girls Campus', address: 'Preedy Street, Saddar', city: 'Karachi', phone: '+92 21 32781234' },
      ],
      staff: [
        { id: 'stf_iec_1', staffId: 'STF-501', name: 'Prof. Shamim Akhtar', email: 'shamim.iec@gmail.com', phone: '+92 300 8881111', jobTitle: 'Director Academic Affairs', branchId: 'br_iec_1', salary: 110000 },
        { id: 'stf_iec_2', staffId: 'STF-502', name: 'Sir Junaid Farooqui', email: 'junaid.iec@gmail.com', phone: '+92 300 8882222', jobTitle: 'Advanced Computer Science', branchId: 'br_iec_1', salary: 95000 },
        { id: 'stf_iec_3', staffId: 'STF-503', name: 'Dr. Shahida Parveen', email: 'shahida.iec@gmail.com', phone: '+92 300 8883333', jobTitle: 'Biochemistry Faculty', branchId: 'br_iec_2', salary: 98000 },
        { id: 'stf_iec_4', staffId: 'STF-504', name: 'Ms. Mehwish Bukhari', email: 'mehwish.iec@gmail.com', phone: '+92 300 8884444', jobTitle: 'Statistics & Math', branchId: 'br_iec_3', salary: 85000 },
      ],
      students: [
        { id: 'stu_iec_1', name: 'Taimoor Shah', roll: '50001', phone: '+92 300 9990001', branchId: 'br_iec_1' },
        { id: 'stu_iec_2', name: 'Zara Noor', roll: '50002', phone: '+92 300 9990002', branchId: 'br_iec_1' },
        { id: 'stu_iec_3', name: 'Hamza Daniyal', roll: '50003', phone: '+92 300 9990003', branchId: 'br_iec_1' },
        { id: 'stu_iec_4', name: 'Hania Amir', roll: '50004', phone: '+92 300 9990004', branchId: 'br_iec_2' },
        { id: 'stu_iec_5', name: 'Shahmeer Khan', roll: '50005', phone: '+92 300 9990005', branchId: 'br_iec_2' },
        { id: 'stu_iec_6', name: 'Areeba Siddiqui', roll: '50006', phone: '+92 300 9990006', branchId: 'br_iec_3' },
        { id: 'stu_iec_7', name: 'Mahnoor Baloch', roll: '50007', phone: '+92 300 9990007', branchId: 'br_iec_3' },
        { id: 'stu_iec_8', name: 'Kashif Mehmood', roll: '50008', phone: '+92 300 9990008', branchId: 'br_iec_3' },
      ],
      courses: [
        { id: 'crs_iec_1', name: 'A-Level Computer Science', code: 'CS-901', teacherId: 'stf_iec_2', teacherName: 'Sir Junaid Farooqui', branchId: 'br_iec_1', enrolled: ['stu_iec_1', 'stu_iec_2', 'stu_iec_3'], schedule: 'Mon, Wed, Fri • 3:30 PM' },
        { id: 'crs_iec_2', name: 'A-Level Physics Dynamics', code: 'PHY-902', teacherId: 'stf_iec_1', teacherName: 'Prof. Shamim Akhtar', branchId: 'br_iec_1', enrolled: ['stu_iec_1', 'stu_iec_2', 'stu_iec_3'], schedule: 'Tue, Thu • 3:30 PM' },
        { id: 'crs_iec_3', name: 'Medical Biochemistry Prep', code: 'BIO-801', teacherId: 'stf_iec_3', teacherName: 'Dr. Shahida Parveen', branchId: 'br_iec_2', enrolled: ['stu_iec_4', 'stu_iec_5'], schedule: 'Mon, Thu • 4:00 PM' },
        { id: 'crs_iec_4', name: 'Applied Business Statistics', code: 'STA-701', teacherId: 'stf_iec_4', teacherName: 'Ms. Mehwish Bukhari', branchId: 'br_iec_3', enrolled: ['stu_iec_6', 'stu_iec_7', 'stu_iec_8'], schedule: 'Wed, Fri • 11:00 AM' },
      ],
    },
    {
      id: 'acad_punjab_404',
      name: 'Punjab Elite Scholars Academy',
      code: 'PES-406',
      status: 'pending', // PENDING APPROVAL
      planId: 'standard',
      planName: 'Standard',
      price: 15000,
      ownerUid: 'uid_pes_admin',
      ownerName: 'Chaudhry Shahzad Aslam',
      ownerEmail: 'director@punjabelite.edu.pk',
      ownerPhone: '+92 41 8541234',
      address: 'Canal Road, East Canal Town',
      city: 'Faisalabad',
      province: 'Punjab',
      branchCount: 2,
      branches: [
        { id: 'br_pes_1', name: 'Canal Road Campus', address: 'Canal Road, East Canal Town', city: 'Faisalabad', phone: '+92 41 8541234' },
        { id: 'br_pes_2', name: 'Jinnah Colony Branch', address: 'Main Bazar, Jinnah Colony', city: 'Faisalabad', phone: '+92 41 8556789' },
      ],
      staff: [
        { id: 'stf_pes_1', staffId: 'STF-601', name: 'Prof. Zahid Bashir', email: 'zahid.pes@gmail.com', phone: '+92 300 7771111', jobTitle: 'Principal & Chemistry Lead', branchId: 'br_pes_1', salary: 85000 },
        { id: 'stf_pes_2', staffId: 'STF-602', name: 'Sir Imran Cheema', email: 'imran.pes@gmail.com', phone: '+92 300 7772222', jobTitle: 'Physics Instructor', branchId: 'br_pes_2', salary: 80000 },
      ],
      students: [
        { id: 'stu_pes_1', name: 'Moiz Shahzad', roll: '60001', phone: '+92 341 5550001', branchId: 'br_pes_1' },
        { id: 'stu_pes_2', name: 'Khadija Tul Kubra', roll: '60002', phone: '+92 341 5550002', branchId: 'br_pes_1' },
        { id: 'stu_pes_3', name: 'Ali Haider', roll: '60003', phone: '+92 341 5550003', branchId: 'br_pes_2' },
        { id: 'stu_pes_4', name: 'Ayesha Bibi', roll: '60004', phone: '+92 341 5550004', branchId: 'br_pes_2' },
      ],
      courses: [
        { id: 'crs_pes_1', name: 'FSc Pre-Medical Chemistry', code: 'CHM-401', teacherId: 'stf_pes_1', teacherName: 'Prof. Zahid Bashir', branchId: 'br_pes_1', enrolled: ['stu_pes_1', 'stu_pes_2'], schedule: 'Mon, Wed • 4:00 PM' },
        { id: 'crs_pes_2', name: 'FSc Pre-Engineering Physics', code: 'PHY-402', teacherId: 'stf_pes_2', teacherName: 'Sir Imran Cheema', branchId: 'br_pes_2', enrolled: ['stu_pes_3', 'stu_pes_4'], schedule: 'Tue, Thu • 4:00 PM' },
      ],
    },
    {
      id: 'acad_frontier_505',
      name: 'Frontier Model Science Academy',
      code: 'FMS-507',
      status: 'pending', // PENDING APPROVAL
      planId: 'basic',
      planName: 'Basic',
      price: 10000,
      ownerUid: 'uid_fms_admin',
      ownerName: 'Engr. Khalid Khan',
      ownerEmail: 'rector@frontierscience.edu.pk',
      ownerPhone: '+92 91 5841234',
      address: 'University Road, Tehkal Payan',
      city: 'Peshawar',
      province: 'Khyber Pakhtunkhwa',
      branchCount: 1,
      branches: [
        { id: 'br_fms_1', name: 'University Road Campus', address: 'University Road, Tehkal Payan', city: 'Peshawar', phone: '+92 91 5841234' },
      ],
      staff: [
        { id: 'stf_fms_1', staffId: 'STF-701', name: 'Sir Sher Afghan', email: 'sher.fms@gmail.com', phone: '+92 333 9991111', jobTitle: 'Mathematics Lecturer', branchId: 'br_fms_1', salary: 75000 },
        { id: 'stf_fms_2', staffId: 'STF-702', name: 'Ms. Palwasha Durrani', email: 'palwasha.fms@gmail.com', phone: '+92 333 9992222', jobTitle: 'Biology Faculty', branchId: 'br_fms_1', salary: 72000 },
      ],
      students: [
        { id: 'stu_fms_1', name: 'Asfandyar Khan', roll: '70001', phone: '+92 313 8880001', branchId: 'br_fms_1' },
        { id: 'stu_fms_2', name: 'Gulalai Noor', roll: '70002', phone: '+92 313 8880002', branchId: 'br_fms_1' },
        { id: 'stu_fms_3', name: 'Zarak Khan', roll: '70003', phone: '+92 313 8880003', branchId: 'br_fms_1' },
        { id: 'stu_fms_4', name: 'Bibi Zainab', roll: '70004', phone: '+92 313 8880004', branchId: 'br_fms_1' },
      ],
      courses: [
        { id: 'crs_fms_1', name: 'Board Exam Mathematics Prep', code: 'MTH-105', teacherId: 'stf_fms_1', teacherName: 'Sir Sher Afghan', branchId: 'br_fms_1', enrolled: ['stu_fms_1', 'stu_fms_2'], schedule: 'Mon, Wed, Fri • 3:00 PM' },
        { id: 'crs_fms_2', name: 'General Biology Lab & Theory', code: 'BIO-105', teacherId: 'stf_fms_2', teacherName: 'Ms. Palwasha Durrani', branchId: 'br_fms_1', enrolled: ['stu_fms_3', 'stu_fms_4'], schedule: 'Tue, Thu • 3:00 PM' },
      ],
    },
    {
      id: 'acad_zenith_606',
      name: 'Zenith Preparatory Academy',
      code: 'ZPA-608',
      status: 'suspended', // SUSPENDED
      planId: 'standard',
      planName: 'Standard',
      price: 15000,
      ownerUid: 'uid_zpa_admin',
      ownerName: 'Prof. M. Arshad',
      ownerEmail: 'registrar@zenithprep.edu.pk',
      ownerPhone: '+92 51 4541234',
      address: 'Peshawar Road, Cantt',
      city: 'Rawalpindi',
      province: 'Punjab',
      branchCount: 1,
      branches: [
        { id: 'br_zpa_1', name: 'Cantt Campus', address: 'Peshawar Road, Cantt', city: 'Rawalpindi', phone: '+92 51 4541234' },
      ],
      staff: [
        { id: 'stf_zpa_1', staffId: 'STF-801', name: 'Sir Naeem Akhtar', email: 'naeem.zpa@gmail.com', phone: '+92 300 4441111', jobTitle: 'Senior Physics Tutor', branchId: 'br_zpa_1', salary: 78000 },
        { id: 'stf_zpa_2', staffId: 'STF-802', name: 'Ms. Amber Qureshi', email: 'amber.zpa@gmail.com', phone: '+92 300 4442222', jobTitle: 'English Language Tutor', branchId: 'br_zpa_1', salary: 70000 },
      ],
      students: [
        { id: 'stu_zpa_1', name: 'Danish Ali', roll: '80001', phone: '+92 315 4440001', branchId: 'br_zpa_1' },
        { id: 'stu_zpa_2', name: 'Mehak Fatima', roll: '80002', phone: '+92 315 4440002', branchId: 'br_zpa_1' },
        { id: 'stu_zpa_3', name: 'Farhan Zaidi', roll: '80003', phone: '+92 315 4440003', branchId: 'br_zpa_1' },
        { id: 'stu_zpa_4', name: 'Natasha Khan', roll: '80004', phone: '+92 315 4440004', branchId: 'br_zpa_1' },
      ],
      courses: [
        { id: 'crs_zpa_1', name: 'Crash Course Physics', code: 'PHY-301', teacherId: 'stf_zpa_1', teacherName: 'Sir Naeem Akhtar', branchId: 'br_zpa_1', enrolled: ['stu_zpa_1', 'stu_zpa_2'], schedule: 'Mon, Wed • 5:00 PM' },
        { id: 'crs_zpa_2', name: 'Crash Course English', code: 'ENG-302', teacherId: 'stf_zpa_2', teacherName: 'Ms. Amber Qureshi', branchId: 'br_zpa_1', enrolled: ['stu_zpa_3', 'stu_zpa_4'], schedule: 'Tue, Thu • 5:00 PM' },
      ],
    },
  ];

  console.log(`🏛️ Seeding ${academiesConfig.length} academies into Firestore...`);

  for (const acad of academiesConfig) {
    console.log(`  -> Processing Academy: ${acad.name} (${acad.code}) [${acad.status.toUpperCase()}]`);

    // 1. Write academy document
    await writeDoc(`academies/${acad.id}`, {
      code: acad.code,
      name: acad.name,
      status: acad.status,
      ownerUid: acad.ownerUid,
      ownerName: acad.ownerName,
      ownerEmail: acad.ownerEmail,
      ownerPhone: acad.ownerPhone,
      address: acad.address,
      city: acad.city,
      province: acad.province,
      branchCount: acad.branchCount,
      subscriptionPlan: acad.planName,
      subscriptionPrice: acad.price,
      registrationDate: new Date('2026-10-15T09:00:00Z'),
      logoUrl: '',
    });

    // 2. Map academy code
    await writeDoc(`academy_codes/${acad.code.toUpperCase()}`, {
      academyId: acad.id,
      name: acad.name,
      status: acad.status,
      assignedAt: new Date('2026-10-15T09:00:00Z'),
    });

    // 3. Write Subscription record
    const subStatus = acad.status === 'suspended' ? 'expired' : (acad.status === 'pending' ? 'pending' : 'active');
    await writeDoc(`subscriptions/${acad.id}`, {
      academyId: acad.id,
      academyName: acad.name,
      academyCode: acad.code,
      planId: acad.planId,
      planName: acad.planName,
      price: acad.price,
      status: subStatus,
      startDate: new Date('2026-10-15T09:00:00Z'),
      renewalDate: new Date('2026-11-15T09:00:00Z'),
      billingCycle: 'monthly',
      paymentStatus: acad.status === 'suspended' ? 'overdue' : 'paid',
      ownerEmail: acad.ownerEmail,
      ownerPhone: acad.ownerPhone,
    });

    // 4. Record payment for active subscriptions
    if (acad.status === 'active') {
      await writeDoc(`subscription_payments/pay_${acad.id}_oct`, {
        academyId: acad.id,
        academyName: acad.name,
        amount: acad.price,
        planName: acad.planName,
        paymentMethod: 'Bank Transfer / IBFT',
        transactionId: `TXN-PK-2026-${Math.floor(100000 + Math.random() * 900000)}`,
        status: 'completed',
        createdAt: new Date('2026-10-15T10:30:00Z'),
      });
    }

    // 5. Seed Branches
    for (const br of acad.branches) {
      await writeDoc(`academies/${acad.id}/branches/${br.id}`, {
        academyId: acad.id,
        name: br.name,
        address: br.address,
        city: br.city,
        phone: br.phone,
        isActive: true,
      });
    }

    // 6. Seed Staff (with salted SHA-256 hashed password)
    const staffPasswordPlain = 'StaffPass@2026';
    const staffPasswordHashed = hashPassword(staffPasswordPlain);

    for (const stf of acad.staff) {
      await writeDoc(`academies/${acad.id}/staff/${stf.id}`, {
        academyId: acad.id,
        staffId: stf.staffId,
        fullName: stf.name,
        email: stf.email,
        phone: stf.phone,
        jobTitle: stf.jobTitle,
        branchId: stf.branchId,
        salary: stf.salary,
        status: 'active',
        password: staffPasswordHashed,
        joiningDate: new Date('2026-08-01T08:00:00Z'),
        permissions: ['attendance', 'results', 'students_view'],
        leaveBalance: 12,
      });

      // Map into staff_accounts collection for login
      await writeDoc(`staff_accounts/${stf.staffId}`, {
        staffDocId: stf.id,
        academyId: acad.id,
        staffId: stf.staffId,
        fullName: stf.name,
        email: stf.email,
        passwordHash: staffPasswordHashed,
        branchId: stf.branchId,
        status: 'active',
      });
    }

    // 7. Seed Students (with salted SHA-256 hashed 4-digit PIN)
    const studentPinPlain = '1234';
    const studentPinHashed = hashPin(studentPinPlain);

    for (const stu of acad.students) {
      await writeDoc(`academies/${acad.id}/students/${stu.id}`, {
        academyId: acad.id,
        fullName: stu.name,
        rollNumber: stu.roll,
        guardianPhone: stu.phone,
        branchId: stu.branchId,
        academicSession: '2026-2027',
        status: 'active',
        admissionDate: new Date('2026-09-01T09:00:00Z'),
      });

      // Map into student_accounts collection for student portal login
      await writeDoc(`student_accounts/${acad.id}_${stu.roll}`, {
        studentDocId: stu.id,
        academyId: acad.id,
        academyCode: acad.code.toUpperCase(),
        rollNumber: stu.roll,
        fullName: stu.name,
        pinHash: studentPinHashed,
        branchId: stu.branchId,
        status: 'active',
        updatedAt: new Date('2026-09-01T09:00:00Z'),
      });
    }

    // 8. Seed Courses
    for (const crs of acad.courses) {
      await writeDoc(`academies/${acad.id}/courses/${crs.id}`, {
        academyId: acad.id,
        branchId: crs.branchId,
        name: crs.name,
        courseCode: crs.code,
        teacherId: crs.teacherId,
        teacherName: crs.teacherName,
        enrolledStudentIds: crs.enrolled,
        schedule: crs.schedule,
        room: 'Lecture Hall A',
        fee: 4500.0,
        isActive: true,
      });

      // 9. Seed Attendance for the previous 5 days
      for (let dayIdx = 0; dayIdx < previous5Days.length; dayIdx++) {
        const attDate = previous5Days[dayIdx];

        for (let stuIdx = 0; stuIdx < crs.enrolled.length; stuIdx++) {
          const studentId = crs.enrolled[stuIdx];
          const status = attendanceStatuses[(dayIdx + stuIdx) % attendanceStatuses.length];
          const recId = `att_${crs.id}_${studentId}_d${dayIdx}`;

          await writeDoc(`academies/${acad.id}/attendance/${recId}`, {
            id: recId,
            academyId: acad.id,
            courseId: crs.id,
            studentId: studentId,
            status: status,
            date: attDate,
            markedById: crs.teacherId,
          });
        }
      }
    }

    // 10. Seed Fee Invoices
    for (let i = 0; i < acad.students.length; i++) {
      const stu = acad.students[i];
      const invId = `inv_${acad.id}_${stu.id}`;
      const isPaid = i % 3 !== 0; // 2/3 paid, 1/3 unpaid
      await writeDoc(`academies/${acad.id}/fee_invoices/${invId}`, {
        academyId: acad.id,
        studentId: stu.id,
        invoiceNo: `INV-2026-${1000 + i}`,
        title: 'October 2026 Academic Tuition Fee',
        baseAmount: 6500.0,
        fine: 0.0,
        discount: 0.0,
        scholarship: 0.0,
        paidAmount: isPaid ? 6500.0 : 0.0,
        status: isPaid ? 'paid' : 'unpaid',
        dueDate: new Date('2026-10-10T00:00:00Z'),
        issuedAt: new Date('2026-10-01T00:00:00Z'),
      });
    }

    // 11. Seed Announcements
    await writeDoc(`academies/${acad.id}/announcements/ann_welcome`, {
      academyId: acad.id,
      title: 'Academic Session 2026-2027 Orientation',
      content: 'Welcome to all enrolled students and faculty members. Regular classes commence in full swing across all campus branches.',
      authorName: 'Administration Office',
      createdAt: new Date('2026-10-15T09:00:00Z'),
      targetAudience: 'all',
      isPinned: true,
    });
  }

  // 5. Seed Super Admin Platform Broadcasts
  console.log('📢 Seeding platform broadcasts...');
  const broadcasts = [
    {
      id: 'bc_system_launch',
      title: 'Welcome to Acaderix Enterprise Cloud',
      message: 'The official Acaderix School & Academy ERP is live. Manage branch rollups, faculty payroll, and daily course attendance from your unified portal.',
      category: 'general',
      priority: 'normal',
      targetAudience: 'all',
      authorEmail: 'admin@acadrix.com',
      isActive: true,
      sentPushNotification: true,
      deliveryCount: 8,
      createdAt: new Date('2026-10-25T10:00:00Z'),
    },
    {
      id: 'bc_maintenance_nov',
      title: 'Scheduled Cloud Maintenance Notice',
      message: 'Routine cloud database indexing will take place on Sunday, November 8th between 2:00 AM and 3:00 AM PKT. Minimal downtime expected.',
      category: 'maintenance',
      priority: 'high',
      targetAudience: 'all',
      authorEmail: 'admin@acadrix.com',
      isActive: true,
      sentPushNotification: false,
      deliveryCount: 8,
      createdAt: new Date('2026-11-01T14:00:00Z'),
    },
  ];

  for (const b of broadcasts) {
    await writeDoc(`broadcasts/${b.id}`, b);
  }

  // 6. Seed Support Tickets
  console.log('🎫 Seeding support tickets...');
  const tickets = [
    {
      id: 'tkt_apex_reporting',
      ticketNumber: 'TKT-1001',
      academyId: 'YtZZVD5vKTRqEk2s8NT3',
      academyName: 'Apex International Academy',
      subject: 'Inquiry regarding Multi-Branch Rollup Reporting',
      status: 'resolved',
      priority: 'medium',
      category: 'technical',
      createdAt: new Date('2026-10-26T11:00:00Z'),
      updatedAt: new Date('2026-10-27T15:30:00Z'),
      resolutionNote: 'Explained how to filter branch scope using the top navigation pill tabs.',
      messages: [
        {
          id: 'msg_1',
          senderName: 'Anonymous Dominator',
          senderRole: 'academyAdmin',
          message: 'Hello, could you explain how branch metrics aggregate on the executive dashboard?',
          createdAt: new Date('2026-10-26T11:00:00Z'),
          isStaffReply: false,
        },
        {
          id: 'msg_2',
          senderName: 'Acaderix Platform Support',
          senderRole: 'superAdmin',
          message: 'Selecting "All Branches" shows aggregated financial and student totals, while selecting an individual branch filters all charts and rosters to that campus.',
          createdAt: new Date('2026-10-27T15:30:00Z'),
          isStaffReply: true,
        },
      ],
    },
    {
      id: 'tkt_pes_approval',
      ticketNumber: 'TKT-1002',
      academyId: 'acad_punjab_404',
      academyName: 'Punjab Elite Scholars Academy',
      subject: 'Institutional Registration Verification Documents',
      status: 'open',
      priority: 'high',
      category: 'billing',
      createdAt: new Date('2026-10-31T09:15:00Z'),
      updatedAt: new Date('2026-10-31T09:15:00Z'),
      messages: [
        {
          id: 'msg_3',
          senderName: 'Chaudhry Shahzad Aslam',
          senderRole: 'academyAdmin',
          message: 'We have submitted our academy registration details. Kindly review our registration for approval.',
          createdAt: new Date('2026-10-31T09:15:00Z'),
          isStaffReply: false,
        },
      ],
    },
  ];

  for (const t of tickets) {
    await writeDoc(`support_tickets/${t.id}`, t);
  }

  // 7. Re-verify users mapping
  console.log('👤 Synchronizing user account mappings...');
  await writeDoc('users/g7Xnwt3jXyOOuYsM3O434g2RPzv1', {
    role: 'super_admin',
    email: 'admin@acadrix.com',
  });
  await writeDoc('users/y0fRjfDd49S4xosQTob6PkKnpWp2', {
    role: 'academy_admin',
    academyId: 'YtZZVD5vKTRqEk2s8NT3',
    email: 'anonymousdominators@gmail.com',
  });
  await writeDoc('users/zaKSXVFa8IWHJJomli1oqoZjQff2', {
    role: 'academy_admin',
    academyId: 'acad_beacon_8787',
    email: 'useeusee8787@gmail.com',
  });

  console.log('\n✨ PRODUCTION SEEDING COMPLETED SUCCESSFULLY! ✨');
  console.log('📊 Summary:');
  console.log('  - 8 Academies: 5 Active, 2 Pending, 1 Suspended');
  console.log('  - All academies equipped with Branches, Courses, Staff, and Students');
  console.log('  - Passwords and PINs hashed with Salted SHA-256');
  console.log('  - 5 Days of historic attendance records per student (Oct 28 - Nov 1, 2026)');
  console.log('  - Active subscriptions & payments recorded');
  console.log('  - Super Admin broadcasts and Help Desk tickets initialized');
}

main().catch(err => {
  console.error('❌ Seeding failed with error:', err);
  process.exit(1);
});

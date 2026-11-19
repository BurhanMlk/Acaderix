/**
 * Deletes all Firestore & non-super-admin Firebase Auth data, then seeds:
 * - Default subscription plans (basic, standard, premium)
 * - 1 Active Academy (Apex International Academy, code: ACD-10001)
 * - 1 Academy Admin Auth user (admin@apexacademy.com / Admin@1234)
 * - 1 Branch (Main Campus)
 * - 2 Teachers (STF-1001 / Staff@1001, STF-1002 / Staff@1002)
 * - 2 Students (Roll 100001 / PIN 1234, Roll 100002 / PIN 5678)
 * - 2 Courses (PHY-101, MTH-102) with both students enrolled
 * - Sample attendance, fee invoices, and announcement
 */

const fs = require('fs');
const crypto = require('crypto');

const PROJECT_ID = 'acaderix-64a5c';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const AUTH_BASE = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}`;

const PASSWORD_SALT = 'acaderix_salt_pwd_v2026_#984!';
const PIN_SALT = 'acaderix_salt_pin_v2026_#412!';
const SUPER_ADMIN_UID = 'g7Xnwt3jXyOOuYsM3O434g2RPzv1';
const SUPER_ADMIN_EMAIL = 'admin@acadrix.com';

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

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (typeof val === 'string') {
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
    if (k === 'id') continue;
    fields[k] = toFirestoreValue(v);
  }
  return fields;
}

async function main() {
  const configPath = 'C:/Users/Anonymous/.config/configstore/firebase-tools.json';
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase tools config not found at ${configPath}`);
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config.tokens.access_token;
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  async function fsRequest(pathOrUrl, options = {}) {
    const url = pathOrUrl.startsWith('http') ? pathOrUrl : `${FIRESTORE_BASE}/${pathOrUrl}`;
    const res = await fetch(url, { ...options, headers });
    if (!res.ok && res.status !== 404) {
      const text = await res.text();
      throw new Error(`Firestore ${options.method || 'GET'} ${url} failed (${res.status}): ${text}`);
    }
    if (res.status === 204 || res.status === 404) return null;
    return res.json();
  }

  async function writeDoc(docPath, data) {
    return fsRequest(docPath, {
      method: 'PATCH',
      body: JSON.stringify({ fields: toFirestoreFields(data) }),
    });
  }

  async function deleteDoc(docPath) {
    return fsRequest(docPath, { method: 'DELETE' });
  }

  async function listCollectionDocs(collectionPath) {
    const docs = [];
    let pageToken = '';
    do {
      const sep = collectionPath.includes('?') ? '&' : '?';
      const url = `${FIRESTORE_BASE}/${collectionPath}?pageSize=200${pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : ''}`;
      const data = await fsRequest(url);
      if (!data || !data.documents) break;
      for (const d of data.documents) {
        docs.push(d.name.replace(`projects/${PROJECT_ID}/databases/(default)/documents/`, ''));
      }
      pageToken = data.nextPageToken || '';
    } while (pageToken);
    return docs;
  }

  // 1. Clear Firebase Auth users (except Super Admin)
  console.log('🧹 Clearing Firebase Auth users (preserving Super Admin)...');
  const authListRes = await fetch(`${AUTH_BASE}/accounts:batchGet?maxResults=100`, { headers });
  const authList = await authListRes.json();
  const usersToDelete = (authList.users || [])
    .map(u => u.localId)
    .filter(uid => uid !== SUPER_ADMIN_UID);

  if (usersToDelete.length > 0) {
    const delRes = await fetch(`${AUTH_BASE}/accounts:batchDelete`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ localIds: usersToDelete, force: true }),
    });
    if (!delRes.ok) {
      throw new Error(`Auth batchDelete failed: ${await delRes.text()}`);
    }
    console.log(`   Deleted ${usersToDelete.length} Auth user(s).`);
  }

  // 2. Clear all Firestore collections
  console.log('🧹 Clearing all Firestore collections...');
  const topCollections = [
    'users',
    'student_accounts',
    'staff_accounts',
    'academy_codes',
    'subscriptions',
    'subscription_plans',
    'subscription_payments',
    'support_tickets',
    'broadcasts',
    'platform_settings',
  ];

  async function deleteDocsBatch(docPaths) {
    const chunkSize = 20;
    for (let i = 0; i < docPaths.length; i += chunkSize) {
      await Promise.all(docPaths.slice(i, i + chunkSize).map(deleteDoc));
    }
  }

  for (const col of topCollections) {
    const docs = await listCollectionDocs(col);
    await deleteDocsBatch(docs);
  }

  const existingAcademies = await listCollectionDocs('academies');
  const subcollections = [
    'branches', 'courses', 'staff', 'students', 'attendance',
    'fee_invoices', 'fee_payments', 'fee_structures', 'exams', 'results',
    'announcements', 'inquiries', 'notifications', 'conversations', 'messages',
    'counters', 'enrollments', 'batches', 'classes', 'subjects', 'guardians',
  ];

  for (const acadPath of existingAcademies) {
    const subDocLists = await Promise.all(
      subcollections.map(sub => listCollectionDocs(`${acadPath}/${sub}`))
    );
    await deleteDocsBatch(subDocLists.flat());
    await deleteDoc(acadPath);
  }
  console.log('✅ All Firestore data cleared.');

  // 3. Create Academy Admin Auth user
  console.log('👤 Creating Academy Admin Auth user...');
  const createAuthRes = await fetch(`${AUTH_BASE}/accounts`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      email: 'admin@apexacademy.com',
      password: 'Admin@1234',
      displayName: 'Tariq Mehmood',
      emailVerified: true,
    }),
  });
  const createdAuth = await createAuthRes.json();
  if (!createAuthRes.ok || !createdAuth.localId) {
    throw new Error(`Failed to create Academy Admin Auth user: ${JSON.stringify(createdAuth)}`);
  }
  const academyAdminUid = createdAuth.localId;

  // 4. Seed Subscription Plans
  console.log('📦 Seeding subscription plans...');
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
        'Multi-Branch Rollup Analytics',
        'Priority Support',
      ],
    },
  ];
  for (const p of plans) {
    await writeDoc(`subscription_plans/${p.id}`, p);
  }

  // 5. Seed 1 Academy
  console.log('🏫 Seeding 1 Academy (Apex International Academy)...');
  const academyId = 'acad_apex_001';
  const academyCode = 'ACD-10001';
  const branchId = 'br_main_1';
  const now = new Date();
  const renewalDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

  await writeDoc(`academies/${academyId}`, {
    code: academyCode,
    name: 'Apex International Academy',
    address: 'Street 14, Sector F-8/2',
    city: 'Islamabad',
    province: 'Islamabad Capital Territory',
    ownerName: 'Tariq Mehmood',
    ownerEmail: 'admin@apexacademy.com',
    ownerPhone: '+92 300 1234567',
    cnic: '61101-1234567-1',
    subscriptionPlan: 'Standard',
    subscriptionPrice: 15000,
    logoUrl: '',
    ownerUid: academyAdminUid,
    status: 'active',
    branchCount: 1,
    registrationDate: now,
    createdAt: now,
  });

  await writeDoc(`academy_codes/${academyCode}`, { academyId });

  await writeDoc(`subscriptions/${academyId}`, {
    academyId,
    planName: 'Standard',
    planPrice: 15000,
    status: 'active',
    paymentStatus: 'paid',
    createdAt: now,
    renewalDate,
  });

  await writeDoc(`users/${SUPER_ADMIN_UID}`, {
    role: 'super_admin',
    email: SUPER_ADMIN_EMAIL,
  });

  await writeDoc(`users/${academyAdminUid}`, {
    role: 'academy_admin',
    academyId,
    email: 'admin@apexacademy.com',
  });

  // 6. Seed 1 Branch
  console.log('🏢 Seeding 1 Branch...');
  await writeDoc(`academies/${academyId}/branches/${branchId}`, {
    academyId,
    name: 'Main Campus',
    address: 'Street 14, Sector F-8/2',
    city: 'Islamabad',
    phone: '+92 51 2284910',
    isActive: true,
    createdAt: now,
  });

  // 7. Seed 2 Teachers
  console.log('👨‍🏫 Seeding 2 Teachers...');
  const teachers = [
    {
      id: 'stf_1',
      staffId: 'STF-1001',
      fullName: 'Prof. Tariq Mehmood',
      email: 'tariq@apexacademy.com',
      phone: '+92 301 5551111',
      jobTitle: 'Physics Lecturer',
      salary: 90000,
      passwordPlain: 'Staff@1001',
    },
    {
      id: 'stf_2',
      staffId: 'STF-1002',
      fullName: 'Ms. Ayesha Siddiqui',
      email: 'ayesha@apexacademy.com',
      phone: '+92 302 5552222',
      jobTitle: 'Mathematics Lecturer',
      salary: 85000,
      passwordPlain: 'Staff@1002',
    },
  ];

  for (const t of teachers) {
    const hashedPwd = hashPassword(t.passwordPlain);
    await writeDoc(`academies/${academyId}/staff/${t.id}`, {
      academyId,
      branchId,
      staffId: t.staffId,
      fullName: t.fullName,
      email: t.email,
      phone: t.phone,
      role: 'teacher',
      jobTitle: t.jobTitle,
      salary: t.salary,
      password: hashedPwd,
      status: 'active',
      joiningDate: now,
    });

    await writeDoc(`staff_accounts/${t.staffId}`, {
      staffDocId: t.id,
      staffId: t.staffId,
      academyId,
      academyCode,
      branchId,
      fullName: t.fullName,
      email: t.email,
      password: hashedPwd,
      status: 'active',
    });
  }

  // 8. Seed 2 Students
  console.log('🎓 Seeding 2 Students...');
  const students = [
    {
      id: 'stu_1',
      fullName: 'Muhammad Hamza',
      fatherName: 'Imran Khan',
      rollNumber: '100001',
      guardianPhone: '+92 321 0001111',
      guardianRelation: 'Father',
      pinPlain: '1234',
    },
    {
      id: 'stu_2',
      fullName: 'Fatima Zahra',
      fatherName: 'Zahid Ali',
      rollNumber: '100002',
      guardianPhone: '+92 321 0002222',
      guardianRelation: 'Father',
      pinPlain: '5678',
    },
  ];

  for (const s of students) {
    const hashedPin = hashPin(s.pinPlain);
    await writeDoc(`academies/${academyId}/students/${s.id}`, {
      academyId,
      branchId,
      fullName: s.fullName,
      fatherName: s.fatherName,
      rollNumber: s.rollNumber,
      guardianPhone: s.guardianPhone,
      guardianRelation: s.guardianRelation,
      academicSession: '2026-2027',
      status: 'active',
      pin: hashedPin,
      admissionDate: now,
    });

    await writeDoc(`student_accounts/${academyCode}_${s.rollNumber}`, {
      studentDocId: s.id,
      academyId,
      academyCode,
      rollNumber: s.rollNumber,
      fullName: s.fullName,
      branchId,
      pin: hashedPin,
      status: 'active',
    });
  }

  // 9. Seed 2 Courses
  console.log('📚 Seeding 2 Courses...');
  const courses = [
    {
      id: 'crs_1',
      name: 'Physics 10th - Batch A',
      courseCode: 'PHY-101',
      teacherId: 'stf_1',
      teacherName: 'Prof. Tariq Mehmood',
      schedule: 'Mon, Wed, Fri • 4:00 PM',
      room: 'Lecture Hall A',
      fee: 4500,
    },
    {
      id: 'crs_2',
      name: 'Mathematics 10th - Batch A',
      courseCode: 'MTH-102',
      teacherId: 'stf_2',
      teacherName: 'Ms. Ayesha Siddiqui',
      schedule: 'Tue, Thu, Sat • 4:00 PM',
      room: 'Lecture Hall B',
      fee: 4500,
    },
  ];

  for (const c of courses) {
    await writeDoc(`academies/${academyId}/courses/${c.id}`, {
      academyId,
      branchId,
      name: c.name,
      courseCode: c.courseCode,
      teacherId: c.teacherId,
      teacherName: c.teacherName,
      enrolledStudentIds: ['stu_1', 'stu_2'],
      schedule: c.schedule,
      room: c.room,
      fee: c.fee,
      isActive: true,
    });
  }

  // 10. Seed Attendance (past 3 days) & Fee Invoices & Announcement
  console.log('📝 Seeding attendance, fee invoices, and announcement...');
  for (let d = 1; d <= 3; d++) {
    const attDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - d));
    for (const c of courses) {
      for (const s of students) {
        const recId = `att_${c.id}_${s.id}_d${d}`;
        await writeDoc(`academies/${academyId}/attendance/${recId}`, {
          academyId,
          courseId: c.id,
          studentId: s.id,
          status: d === 2 && s.id === 'stu_2' ? 'late' : 'present',
          date: attDate,
          markedById: c.teacherId,
        });
      }
    }
  }

  await writeDoc(`academies/${academyId}/fee_invoices/inv_1`, {
    academyId,
    studentId: 'stu_1',
    invoiceNo: 'INV-2026-1001',
    title: 'Monthly Tuition Fee',
    baseAmount: 9000,
    fine: 0,
    discount: 0,
    scholarship: 0,
    paidAmount: 9000,
    status: 'paid',
    dueDate: now,
    issuedAt: now,
  });

  await writeDoc(`academies/${academyId}/fee_invoices/inv_2`, {
    academyId,
    studentId: 'stu_2',
    invoiceNo: 'INV-2026-1002',
    title: 'Monthly Tuition Fee',
    baseAmount: 9000,
    fine: 0,
    discount: 0,
    scholarship: 0,
    paidAmount: 0,
    status: 'unpaid',
    dueDate: renewalDate,
    issuedAt: now,
  });

  await writeDoc(`academies/${academyId}/announcements/ann_welcome`, {
    academyId,
    branchId,
    title: 'Welcome to Apex International Academy',
    content: 'Classes for Physics (PHY-101) and Mathematics (MTH-102) are now in session.',
    authorName: 'Administration Office',
    createdAt: now,
    targetAudience: 'all',
    isPinned: true,
  });

  console.log('\n✨ RESET & SEED COMPLETED SUCCESSFULLY! ✨');
}

main().catch(err => {
  console.error('❌ Failed:', err);
  process.exit(1);
});

/**
 * Admin utility: Permanently deletes an academy and cascades deletion across:
 *   1. Firebase Authentication (deletes the academy admin user account)
 *   2. Firestore `users/{uid}` profiles (owner and any users with this academyId)
 *   3. All 23 Firestore subcollections (students, staff, branches, fees, attendance, results, etc.)
 *   4. `academy_codes/{code}` human-friendly code mapping
 *   5. Root `academies/{academyId}` document
 *
 * Usage:
 *   node scripts/delete-academy.js <academyId_or_code>
 *
 * Example:
 *   node scripts/delete-academy.js ACD-TEST1
 *   node scripts/delete-academy.js 3ZqVbN...
 */
'use strict';

const admin = require('firebase-admin');

const academyIdentifier = process.argv[2];

function fail(msg) {
  console.error('\x1b[31mError:\x1b[0m', msg);
  process.exit(1);
}

if (!academyIdentifier) {
  console.log(`
Usage:
  node scripts/delete-academy.js <academyId_or_academy_code>
`);
  process.exit(1);
}

try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'acaderix-64a5c',
  });
} catch (e) {
  fail(
    `Could not load Firebase credentials: ${e.message}\n` +
      'Run `gcloud auth application-default login` or set GOOGLE_APPLICATION_CREDENTIALS.'
  );
}

const auth = admin.auth();
const db = admin.firestore();

const subcollections = [
  'branches',
  'staff',
  'students',
  'guardians',
  'classes',
  'courses',
  'subjects',
  'batches',
  'enrollments',
  'attendance',
  'staff_attendance',
  'fee_structures',
  'fee_invoices',
  'fee_payments',
  'exams',
  'results',
  'homework',
  'timetables',
  'salaries',
  'expenses',
  'announcements',
  'audit_logs',
  'counters',
];

(async () => {
  let academyId = academyIdentifier;
  let academyDoc = await db.collection('academies').doc(academyId).get();

  if (!academyDoc.exists) {
    // Try resolving from academy_codes collection
    const codeDoc = await db.collection('academy_codes').doc(academyIdentifier.toUpperCase()).get();
    if (codeDoc.exists) {
      academyId = codeDoc.data().academyId;
      academyDoc = await db.collection('academies').doc(academyId).get();
    }
  }

  if (!academyDoc.exists) {
    fail(`Academy "${academyIdentifier}" not found in Firestore.`);
  }

  const academyData = academyDoc.data() || {};
  const academyName = academyData.name || 'Unnamed';
  const code = academyData.code || '';
  const ownerUid = academyData.ownerUid || '';
  const ownerEmail = academyData.ownerEmail || '';
  const logoUrl = academyData.logoUrl || '';

  console.log(`\nFound Academy: "${academyName}" (${code}) [ID: ${academyId}]`);
  console.log(`Owner UID: ${ownerUid} | Owner Email: ${ownerEmail}`);

  // 1. Delete from Firebase Authentication
  if (ownerUid) {
    try {
      await auth.deleteUser(ownerUid);
      console.log(`✔ Deleted user "${ownerEmail}" (UID: ${ownerUid}) from Firebase Authentication.`);
    } catch (e) {
      console.warn(`⚠ Could not delete Auth user ${ownerUid}: ${e.message}`);
    }
  } else if (ownerEmail) {
    try {
      const user = await auth.getUserByEmail(ownerEmail);
      await auth.deleteUser(user.uid);
      console.log(`✔ Deleted user "${ownerEmail}" from Firebase Authentication.`);
    } catch (e) {
      console.warn(`⚠ Could not find Auth user for ${ownerEmail}: ${e.message}`);
    }
  }

  // 2. Cascade delete all subcollections
  console.log('\nDeleting all subcollection documents under academy...');
  for (const subcol of subcollections) {
    const snapshot = await db.collection(`academies/${academyId}/${subcol}`).get();
    if (!snapshot.empty) {
      let batch = db.batch();
      let count = 0;
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      console.log(`✔ Deleted ${snapshot.size} document(s) from "${subcol}".`);
    }
  }

  // 3. Delete user profiles from Firestore
  if (ownerUid) {
    await db.collection('users').doc(ownerUid).delete().catch(() => {});
    console.log(`✔ Deleted profile users/${ownerUid} from Firestore.`);
  }

  const linkedUsers = await db.collection('users').where('academyId', '==', academyId).get();
  if (!linkedUsers.empty) {
    const batch = db.batch();
    for (const doc of linkedUsers.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    console.log(`✔ Deleted ${linkedUsers.size} associated users record(s) from Firestore.`);
  }

  // 4. Delete academy code
  if (code) {
    await db.collection('academy_codes').doc(code.toUpperCase()).delete().catch(() => {});
    console.log(`✔ Deleted academy_codes/${code.toUpperCase()} (code can now be claimed again).`);
  }

  // 5. Delete root academy document
  await db.collection('academies').doc(academyId).delete();
  console.log(`✔ Deleted root document academies/${academyId}.`);

  if (logoUrl) {
    console.log(`\nNote: Academy logo was stored at Cloudinary: ${logoUrl}`);
    console.log('To remove the media from Cloudinary storage, delete it via your Cloudinary Media Library.');
  }

  console.log('\n\x1b[32mCascade deletion completed successfully.\x1b[0m\n');
})().catch((err) => {
  fail(err.message);
});

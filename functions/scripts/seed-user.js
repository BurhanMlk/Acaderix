/**
 * Dev-only helper: create (or update) a Firebase Auth user and write their
 * `users/{uid}` profile document with a role, so the Flutter app routes to
 * the right dashboard. Firebase is used for Auth + Firestore only.
 *
 * This script is NOT deployed. It is a local development utility that talks
 * to your Firebase project using Application Default Credentials.
 *
 * Prerequisites:
 *   1. cd functions && npm install
 *   2. Provide credentials with one of:
 *      a. A service-account key (recommended):
 *         Firebase console → Project settings → Service accounts →
 *         Generate new private key. Then:
 *         GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *           node scripts/seed-user.js user@example.com 'password123' super_admin
 *      b. Google Cloud ADC:
 *         gcloud auth application-default login
 *         node scripts/seed-user.js user@example.com 'password123' super_admin
 *
 * Roles: super_admin | academy_admin | staff | student
 */
'use strict';

const admin = require('firebase-admin');

const [email, password, role] = process.argv.slice(2);
const validRoles = ['super_admin', 'academy_admin', 'staff', 'student'];

function fail(message) {
  console.error(message);
  process.exit(1);
}

if (!email || !password || !role) {
  fail(
    'Usage: node scripts/seed-user.js <email> <password> <role>\n' +
      `  role must be one of: ${validRoles.join(', ')}`
  );
}
if (!validRoles.includes(role)) {
  fail(`Invalid role "${role}". Use one of: ${validRoles.join(', ')}`);
}

try {
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
} catch (e) {
  fail(
    `Could not load Firebase credentials: ${e.message}\n` +
      'Set GOOGLE_APPLICATION_CREDENTIALS to a service-account key, or run ' +
      '`gcloud auth application-default login`.'
  );
}

const auth = admin.auth();
const db = admin.firestore();

(async () => {
  let uid;
  try {
    const existing = await auth.getUserByEmail(email);
    uid = existing.uid;
    await auth.updateUser(uid, { password });
    console.log(`Updated existing user ${email} (uid: ${uid}) with a new password.`);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    const created = await auth.createUser({ email, password });
    uid = created.uid;
    console.log(`Created user ${email} (uid: ${uid}).`);
  }

  await db.collection('users').doc(uid).set({ role, email });
  console.log(`Wrote Firestore profile { role: '${role}' } for uid ${uid}.`);
  console.log('Sign in again in the app to load the new profile.');
})().catch((e) => {
  console.error('Failed:', e.message);
  process.exit(1);
});

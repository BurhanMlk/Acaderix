/**
 * Admin utility: Update an existing user's email and/or password directly in
 * Firebase Cloud Authentication and synchronize their Firestore records.
 *
 * Usage:
 *   node scripts/update-admin-credentials.js <identifier> [options]
 *
 * Parameters:
 *   identifier: The user's current email or UID in Firebase Authentication
 *
 * Options:
 *   --email <new_email>       New email address to set in Firebase Auth & Firestore
 *   --password <new_password> New password to set directly in Firebase Auth
 *
 * Examples:
 *   node scripts/update-admin-credentials.js admin@example.com --email newadmin@example.com
 *   node scripts/update-admin-credentials.js admin@example.com --password 'NewSecret123!'
 *   node scripts/update-admin-credentials.js admin@example.com --email newadmin@example.com --password 'NewSecret123!'
 */
'use strict';

const admin = require('firebase-admin');

const args = process.argv.slice(2);

function fail(msg) {
  console.error('\x1b[31mError:\x1b[0m', msg);
  process.exit(1);
}

if (args.length === 0 || args[0].startsWith('--')) {
  console.log(`
Usage:
  node scripts/update-admin-credentials.js <current_email_or_uid> [--email <new_email>] [--password <new_password>]

Options:
  --email <new_email>        Update login email in Firebase Auth and Firestore
  --password <new_password>  Set new password directly in Firebase Auth
`);
  process.exit(1);
}

const identifier = args[0];
let newEmail = null;
let newPassword = null;

for (let i = 1; i < args.length; i++) {
  if (args[i] === '--email' && i + 1 < args.length) {
    newEmail = args[++i];
  } else if (args[i] === '--password' && i + 1 < args.length) {
    newPassword = args[++i];
  }
}

if (!newEmail && !newPassword) {
  fail('Specify at least --email <new_email> or --password <new_password>.');
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

(async () => {
  let user;
  try {
    if (identifier.includes('@')) {
      user = await auth.getUserByEmail(identifier);
    } else {
      user = await auth.getUser(identifier);
    }
  } catch (e) {
    fail(`User "${identifier}" not found in Firebase Authentication: ${e.message}`);
  }

  const updates = {};
  if (newEmail) updates.email = newEmail;
  if (newPassword) updates.password = newPassword;

  console.log(`\nFound Firebase Auth user: ${user.email} (UID: ${user.uid})`);
  console.log('Applying updates to Firebase Authentication...');

  await auth.updateUser(user.uid, updates);

  if (newEmail) {
    console.log(`✔ Firebase Auth email updated to: ${newEmail}`);
    console.log('Synchronizing Firestore profile records...');

    await db.collection('users').doc(user.uid).set({ email: newEmail }, { merge: true });

    // Sync any academy owned by this user
    const academies = await db
      .collection('academies')
      .where('ownerUid', '==', user.uid)
      .get();

    for (const doc of academies.docs) {
      await doc.ref.update({ ownerEmail: newEmail });
      console.log(`✔ Updated ownerEmail on academy "${doc.data().name}" (${doc.id})`);
    }
  }

  if (newPassword) {
    console.log('✔ Firebase Auth password successfully updated directly.');
  }

  console.log('\n\x1b[32mAll updates completed successfully.\x1b[0m\n');
})().catch((err) => {
  fail(err.message);
});

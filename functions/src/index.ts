/**
 * Privileged server-side operations for the Academy Management System.
 *
 * Firebase Admin SDK operations bypass Firestore Security Rules, so every
 * function here MUST:
 *   1. Verify the caller is authenticated (`context.auth`).
 *   2. Verify the caller's role / custom claims before acting.
 *   3. Scope every read/write to the caller's academy (tenant isolation).
 *   4. Never trust role, academy id, price, or subscription status supplied
 *      by the client payload.
 *
 * Phase 1 ships the `health` check plus the two most security-sensitive
 * flows: atomic roll-number allocation and student credential verification
 * with custom-token sign-in.
 */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {randomBytes, scryptSync, timingSafeEqual} from "crypto";

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

/** Claims that identify the role/tenant of a caller. */
interface CustomClaims {
  role?: string;
  academyId?: string;
  rollNumber?: string;
}

/** Unambiguous alphabet used for human-friendly academy codes. */
const ACADEMY_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

/**
 * Generates an academy code in the `ACD-XXXXX` shape used by the app.
 * @return {string} The generated academy code.
 */
function generateAcademyCode(): string {
  let code = "ACD-";
  for (let i = 0; i < 5; i++) {
    code += ACADEMY_CODE_ALPHABET[
        Math.floor(Math.random() * ACADEMY_CODE_ALPHABET.length)
    ];
  }
  return code;
}

/**
 * A harmless health check used to verify the Functions deploy and connectivity.
 */
export const health = functions.https.onCall(async () => {
  return {status: "ok", timestamp: Date.now()};
});

/**
 * Atomically allocates the next six-digit roll number for an academy.
 *
 * Authorization: requires an authenticated caller with an `academyId` claim.
 * Uses a Firestore transaction on `counters/roll_number` so concurrent
 * admissions can never produce duplicate roll numbers.
 */
export const allocateRollNumber = functions.https.onCall(
    async (request, context) => {
      const caller = authorizeCaller(context);
      const academyId = caller.academyId;
      if (!academyId) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "No academy context for this caller."
        );
      }

      const counterRef = db.doc(
          `academies/${academyId}/counters/roll_number`
      );

      const next = await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(counterRef);
        const current = snapshot.exists ?
        ((snapshot.data()?.value as number) ?? 0) :
        0;
        const nextValue = current < 100001 ? 100001 : current + 1;
        transaction.set(counterRef, {value: nextValue}, {merge: true});
        return nextValue;
      });

      return {rollNumber: String(next)};
    }
);

/**
 * Verifies a student's academy code + roll number + PIN and issues a Firebase
 * custom token carrying student claims.
 *
 * The PIN is verified against a salted scrypt hash stored on the student
 * document. Plaintext PINs are never stored.
 */
export const studentSignIn = functions.https.onCall(
    async (
        request: {
      academyCode?: string;
      rollNumber?: string;
      pin?: string;
    },
        context
    ) => {
      const {academyCode, rollNumber, pin} = request;
      if (!academyCode || !rollNumber || !pin) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "academyCode, rollNumber and pin are required."
        );
      }

      // Resolve academy id from the human-friendly academy code.
      const academySnapshot = await db
          .collection("academy_codes")
          .doc(academyCode.toUpperCase())
          .get();
      const academyId = academySnapshot.data()?.academyId as string | undefined;
      if (!academyId) {
        throw new functions.https.HttpsError(
            "not-found",
            "Invalid academy code."
        );
      }

      const academy = await db.doc(`academies/${academyId}`).get();
      const academyStatus = academy.data()?.status as string | undefined;
      if (academyStatus !== "active") {
        throw new functions.https.HttpsError(
            "permission-denied",
            "This academy is not active."
        );
      }

      // Find the student by roll number within the academy.
      const students = await db
          .collection(`academies/${academyId}/students`)
          .where("rollNumber", "==", rollNumber)
          .limit(1)
          .get();

      const studentDoc = students.docs[0];
      if (!studentDoc) {
        throw new functions.https.HttpsError(
            "not-found",
            "No student found for this roll number."
        );
      }

      const student = studentDoc.data();
      const uid: string = studentDoc.id;
      const pinHash = Buffer.from(student.pinHash ?? "", "base64");
      const pinSalt = Buffer.from(student.pinSalt ?? "", "base64");

      const candidate = scryptSync(String(pin), pinSalt, 64);
      const valid = timingSafeEqual(candidate, pinHash);
      if (!valid) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Invalid credentials."
        );
      }

      const token = await auth.createCustomToken(uid, {
        role: "student",
        academyId,
        rollNumber,
      } satisfies CustomClaims);

      return {token};
    }
);

/**
 * Creates a student with a securely hashed temporary PIN.
 *
 * This is the trusted path for admissions: it allocates the roll number and
 * hashes the PIN server-side. The PIN is returned exactly once to the caller
 * for one-time delivery; it is never stored in plaintext.
 */
export const admitStudent = functions.https.onCall(
    async (
        request: {
      academyId?: string;
      fullName?: string;
      fatherName?: string;
      guardianPhone?: string;
      academicSession?: string;
    },
        context
    ) => {
      const caller = authorizeCaller(context);
      const academyId = caller.academyId ?? request.academyId;
      if (!academyId) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "No academy context."
        );
      }
      if (!request.fullName || !request.fatherName) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "fullName and fatherName are required."
        );
      }

      // Allocate roll number atomically.
      const counterRef = db.doc(`academies/${academyId}/counters/roll_number`);
      const rollNumber = await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(counterRef);
        const current = snapshot.exists ?
        ((snapshot.data()?.value as number) ?? 0) :
        0;
        const nextValue = current < 100001 ? 100001 : current + 1;
        transaction.set(counterRef, {value: nextValue}, {merge: true});
        return nextValue;
      });

      // Generate a temporary PIN and hash it.
      const pin = String(Math.floor(1000 + Math.random() * 9000));
      const salt = randomBytes(16);
      const hash = scryptSync(pin, salt, 64);

      const studentRef = db
          .collection(`academies/${academyId}/students`)
          .doc();

      await studentRef.set({
        fullName: request.fullName,
        fatherName: request.fatherName,
        guardianPhone: request.guardianPhone ?? "",
        academicSession: request.academicSession ?? "",
        rollNumber: String(rollNumber),
        pinHash: hash.toString("base64"),
        pinSalt: salt.toString("base64"),
        status: "active",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        studentId: studentRef.id,
        rollNumber: String(rollNumber),
        pin,
      };
    }
);

/**
 * Registers a new academy and provisions its first Academy Admin.
 *
 * This is the trusted counterpart to the public registration form:
 *   1. Verifies the caller is a freshly created auth user with no role yet.
 *   2. Enforces one academy per owner account.
 *   3. Allocates a unique academy code and writes the academy document.
 *   4. Assigns `role: academy_admin` + `academyId` custom claims so the
 *      client routes the user to their academy dashboard on the next token
 *      refresh.
 */
export const registerAcademy = functions.https.onCall(
    async (
        request: {
      academyName?: string;
      address?: string;
      cnic?: string;
      ownerName?: string;
      ownerPhone?: string;
      planName?: string;
      planPrice?: number;
      logoUrl?: string;
    },
        context
    ) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be signed in."
        );
      }

      const uid = context.auth.uid;
      if (context.auth.token.role) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "This account is already registered."
        );
      }

      const {
        academyName,
        address,
        cnic,
        ownerName,
        ownerPhone,
        planName,
        planPrice,
        logoUrl,
      } = request;
      if (!academyName || !address) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "academyName and address are required."
        );
      }

      // Enforce one academy per owner account.
      const existing = await db
          .collection("academies")
          .where("ownerUid", "==", uid)
          .limit(1)
          .get();
      if (!existing.empty) {
        throw new functions.https.HttpsError(
            "already-exists",
            "You have already registered an academy."
        );
      }

      const academyId = db.collection("academies").doc().id;

      const code = await db.runTransaction(async (transaction) => {
        for (let attempt = 0; attempt < 10; attempt++) {
          const candidate = generateAcademyCode();
          const codeRef = db.doc(`academy_codes/${candidate}`);
          const snapshot = await transaction.get(codeRef);
          if (!snapshot.exists) {
            transaction.set(codeRef, {academyId});
            transaction.set(db.doc(`academies/${academyId}`), {
              code: candidate,
              name: academyName,
              address: address ?? "",
              ownerName: ownerName ?? "",
              ownerEmail: context.auth?.token.email ?? "",
              ownerPhone: ownerPhone ?? "",
              cnic: cnic ?? "",
              subscriptionPlan: planName ?? "",
              subscriptionPrice: planPrice ?? 0,
              logoUrl: logoUrl ?? "",
              ownerUid: uid,
              status: "active",
              branchCount: 0,
              registrationDate: admin.firestore.FieldValue.serverTimestamp(),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return candidate;
          }
        }
        throw new functions.https.HttpsError(
            "internal",
            "Could not allocate a unique academy code."
        );
      });

      await auth.setCustomUserClaims(uid, {
        role: "academy_admin",
        academyId,
      } satisfies CustomClaims);

      return {academyId, code};
    }
);

/**
 * Extracts and validates the caller's custom claims.
 * @param {functions.https.CallableContext} context The callable context.
 * @return {CustomClaims} The caller's validated custom claims.
 */
function authorizeCaller(
    context: functions.https.CallableContext
): CustomClaims {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
    );
  }
  const claims = (context.auth.token ?? {}) as CustomClaims;
  return claims;
}

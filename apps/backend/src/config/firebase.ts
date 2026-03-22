import admin from 'firebase-admin';
import { env } from './env';

const isFirebaseConfigured =
  env.FIREBASE_PROJECT_ID &&
  env.FIREBASE_PRIVATE_KEY &&
  env.FIREBASE_CLIENT_EMAIL;

if (isFirebaseConfigured && !admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.FIREBASE_PROJECT_ID,
      privateKey: env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
    }),
  });
}

export const verifyFirebaseToken = async (
  idToken: string
): Promise<admin.auth.DecodedIdToken | null> => {
  if (!isFirebaseConfigured) {
    console.warn('Firebase not configured — skipping token verification');
    return null;
  }
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch {
    // In development, allow fallback to dev UID if Firebase token is invalid
    if (process.env.NODE_ENV !== 'production') {
      console.warn('Firebase token verification failed — using dev fallback');
      return null;
    }
    throw new Error('Invalid Firebase token');
  }
};

export { isFirebaseConfigured };
export default admin;

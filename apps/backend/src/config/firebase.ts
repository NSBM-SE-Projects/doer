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
  return admin.auth().verifyIdToken(idToken);
};

export { isFirebaseConfigured };
export default admin;

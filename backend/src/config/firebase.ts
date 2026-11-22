import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

let isFirebaseInitialized = false;

try {
    if (fs.existsSync(serviceAccountPath)) {
        // Local development: use the JSON file
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        isFirebaseInitialized = true;
        console.log('Firebase Admin initialized successfully from serviceAccountKey.json.');
    } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
        // Production (e.g., Dokploy): use environment variables
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                // Replace escaped newlines so the private key is parsed correctly
                privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            }),
        });
        isFirebaseInitialized = true;
        console.log('Firebase Admin initialized successfully from Environment Variables.');
    } else {
        console.warn(
            'WARNING: Firebase credentials not found (neither serviceAccountKey.json nor ENV vars). FCM features will not work.'
        );
    }
} catch (error) {
    console.error('Error initializing Firebase Admin:', error);
}

export const firebaseAdmin = isFirebaseInitialized ? admin : null;
export { isFirebaseInitialized };

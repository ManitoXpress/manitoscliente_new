const admin = require('firebase-admin');
const serviceAccount = require('./manitoxpress-cf855-firebase-adminsdk-vawdb-eb13e80ee5.json'); // <- tu clave aquí

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function contarWorkers() {
  try {
    const snapshot = await db.collection('workers').get();
    console.log(`Total de documentos en "workers": ${snapshot.size}`);
  } catch (error) {
    console.error('Error al contar documentos:', error);
  }
}

contarWorkers();

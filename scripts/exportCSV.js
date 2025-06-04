const admin = require('firebase-admin');
const fs = require('fs');
const { Parser } = require('json2csv');
const serviceAccount = require('./manitoxpress-cf855-firebase-adminsdk-vawdb-eb13e80ee5.json'); // Tu clave aquí

// Inicializa Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function exportCollectionToCSV(collectionName, fileName) {  // Corrige la definición de la función
  try {
    const snapshot = await db.collection(collectionName).get();
    const documents = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      documents.push({ id: doc.id, ...data }); // Agregar ID como campo si lo necesitas
    });

    // Convierte los documentos a CSV
    const json2csvParser = new Parser();
    const csv = json2csvParser.parse(documents);

    // Guarda el CSV en un archivo
    fs.writeFileSync(fileName, csv);

    console.log(`Datos de la colección "${collectionName}" exportados a ${fileName}`);
  } catch (error) {
    console.error('Error al exportar la colección a CSV:', error);
  }
}

// Llama a la función con el nombre de la colección y el archivo de salida
exportCollectionToCSV('users', 'users.csv'); // Cambia 'workers' por el nombre de tu colección

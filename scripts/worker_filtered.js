const admin = require('firebase-admin');
const fs = require('fs');
const { Parser } = require('json2csv');
const serviceAccount = require('./manitoxpress-cf855-firebase-adminsdk-vawdb-eb13e80ee5.json'); // Tu clave aquí

// Inicializa Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function exportCollectionToCSV(collectionName, fileName, fields = []) {
  try {
    const snapshot = await db.collection(collectionName).get();
    const documents = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      // Construye un objeto solo con las keys de `fields`
      const filtered = fields.reduce((obj, key) => {
        if (data[key] !== undefined) obj[key] = data[key];
        return obj;
      }, { id: doc.id });
      documents.push(filtered);
    });

    const json2csvParser = new Parser({ fields: ['id', ...fields] });
    const csv = json2csvParser.parse(documents);
    fs.writeFileSync(fileName, csv);

    console.log(`Datos de "${collectionName}" (${fields.join(', ')}) exportados a ${fileName}`);
  } catch (error) {
    console.error('Error al exportar la colección a CSV:', error);
  }
}

exportCollectionToCSV('users', 'users_filtered.csv', ['displayName', 'phoneNumber', 'email', 'uid']);
// Cambia 'workers' por el nombre de tu colección y 'workers_filtered.csv' por el nombre del archivo de salida  
// Cambia el array de fields por los campos que realmente quieras exportar


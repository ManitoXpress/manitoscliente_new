/**
 * export_last24_to_csv.js
 *
 * Este script:
 * 1. Se conecta a Firestore usando las credenciales provistas.
 * 2. Lee todos los documentos de la colección "workers".
 * 3. Filtra solo los creados en las últimas 24 horas (usando `snapshot.createTime`).
 * 4. Exporta, en formato CSV, los campos: id, displayName, phoneNumber y expertises (nombre de cada expertise).
 *
 * Requisitos previos:
 *   npm install firebase-admin json2csv
 *
 * Para ejecutarlo:
 *   node export_last24_to_csv.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const { Parser } = require('json2csv');

// Sustituye la ruta si tu JSON de credenciales está en otro directorio
const serviceAccount = require('./manitoxpress-cf855-firebase-adminsdk-vawdb-eb13e80ee5.json');

// ======== 1) Inicializar Firebase Admin SDK ========
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// ======== 2) Lógica para filtrar documentos de las últimas 24 horas y exportar a CSV ========
async function exportLast24ToCSV() {
  try {
    // 2.1) Calcular el umbral de "hace 24 horas"
    const ahora = new Date();
    const hace24h = new Date(ahora.getTime() - 24 * 60 * 60 * 1000);

    console.log('Fecha actual:       ', ahora.toISOString());
    console.log('Filtrando desde:   ', hace24h.toISOString());

    // 2.2) Leer todos los documentos de "workers"
    const snapshot = await db.collection('workers').get();
    console.log(`Total de documentos en "workers": ${snapshot.size}`);

    // 2.3) Iterar y quedarnos solo con los docs cuyo createTime >= hace24h
    const docsFiltrados = [];
    snapshot.forEach((docSnap) => {
      const createTime = docSnap.createTime; // Timestamp interno de Firestore
      if (!createTime) return; // por si acaso
      const fechaCreacion = createTime.toDate();

      if (fechaCreacion >= hace24h) {
        const data = docSnap.data();

        // Tomamos solo los campos que queremos exportar:
        // - id (docSnap.id)
        // - displayName
        // - phoneNumber
        // - expertises: lo convertimos a una cadena con los nombres separados por ";"
        let expertisesStr = '';
        if (Array.isArray(data.expertises)) {
          expertisesStr = data.expertises
            .map((exp) => {
              // Si cada expertise es un objeto con campo "name", lo tomamos
              if (exp && typeof exp === 'object' && exp.name) {
                return exp.name;
              }
              return '';
            })
            .filter((name) => name.length > 0)
            .join('; ');
        }

        docsFiltrados.push({
          id: docSnap.id,
          displayName: data.displayName || '',
          phoneNumber: data.phoneNumber || '',
          expertises: expertisesStr
        });
      }
    });

    console.log(`Documentos de las últimas 24h: ${docsFiltrados.length}`);

    if (docsFiltrados.length === 0) {
      console.log('No hay documentos nuevos en este rango.');
      return;
    }

    // 2.4) Convertir a CSV
    const fields = ['id', 'displayName', 'phoneNumber', 'expertises'];
    const parser = new Parser({ fields });
    const csv = parser.parse(docsFiltrados);

    // 2.5) Escribir el CSV a un archivo
    const outputFileName = 'workers_last24.csv';
    fs.writeFileSync(outputFileName, csv, 'utf8');

    console.log(`✅ CSV generado: ${outputFileName}`);
  } catch (error) {
    console.error('❌ Error exportando últimos 24h a CSV:', error);
  }
}

// Ejecutar
exportLast24ToCSV();

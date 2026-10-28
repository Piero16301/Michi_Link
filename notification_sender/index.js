#!/usr/bin/env node

/**
 * MichiLink - CLI para envío de notificaciones push de prueba (FCM)
 * Permite enviar por Topic o por Token directo a un dispositivo,
 * seleccionando entre las 3 severidades soportadas (CRITICAL, WARNING, INFO).
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');
require('dotenv').config();

const admin = require('firebase-admin');

// Configuración de Canales y Plantillas por Severidad
const SEVERITY_CONFIG = {
  CRITICAL: {
    channelId: 'michi_critical_channel',
    priority: 'high',
    androidNotificationPriority: 'max',
    badge: '🚨 [CRITICAL]',
    defaultTitle: '🚨 ¡Alerta Crítica! Michi fuera de zona',
    defaultBody: 'Michi ha salido del perímetro seguro configurado.',
  },
  WARNING: {
    channelId: 'michi_warning_channel',
    priority: 'high',
    androidNotificationPriority: 'high',
    badge: '⚠️ [WARNING]',
    defaultTitle: '⚠️ Advertencia: Batería baja',
    defaultBody: 'La batería del collar ha bajado al 15%. Conéctalo pronto.',
  },
  INFO: {
    channelId: 'michi_info_channel',
    priority: 'normal',
    androidNotificationPriority: 'default',
    badge: 'ℹ️ [INFO]',
    defaultTitle: 'ℹ️ Información: Michi en casa',
    defaultBody: 'Michi ha regresado a la zona segura habitual.',
  },
};

/**
 * Inicializa Firebase Admin SDK buscando credenciales en:
 * 1. serviceAccountKey.json en la misma carpeta
 * 2. GOOGLE_APPLICATION_CREDENTIALS en .env / entorno
 * 3. Application Default Credentials (gcloud)
 */
function initFirebase() {
  const localKeyPath = path.join(__dirname, 'serviceAccountKey.json');
  const envKeyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  let credential = null;

  if (fs.existsSync(localKeyPath)) {
    try {
      const keyData = JSON.parse(fs.readFileSync(localKeyPath, 'utf8'));
      credential = admin.credential.cert(keyData);
      console.log('🔑 Credencial cargada desde: serviceAccountKey.json');
    } catch (e) {
      console.error('❌ Error al leer serviceAccountKey.json:', e.message);
      process.exit(1);
    }
  } else if (envKeyPath && fs.existsSync(envKeyPath)) {
    try {
      const keyData = JSON.parse(fs.readFileSync(envKeyPath, 'utf8'));
      credential = admin.credential.cert(keyData);
      console.log(`🔑 Credencial cargada desde: ${envKeyPath}`);
    } catch (e) {
      console.error(`❌ Error al leer ${envKeyPath}:`, e.message);
      process.exit(1);
    }
  } else {
    try {
      credential = admin.credential.applicationDefault();
      console.log('🔑 Usando credenciales por defecto de Google Cloud');
    } catch (_) {
      console.error('\n' + '='.repeat(68));
      console.error('❌ NO SE ENCONTRÓ ARCHIVO DE CREDENCIALES DE FIREBASE');
      console.error('='.repeat(68));
      console.error('Para enviar notificaciones push con Firebase Admin, necesitas');
      console.error('descargar la clave de cuenta de servicio de tu proyecto Firebase:');
      console.error('');
      console.error('1. Ve a Firebase Console -> Configuración del proyecto -> Cuentas de servicio');
      console.error('2. Clic en "Generar nueva clave privada".');
      console.error('3. Guarda el archivo descargado como:');
      console.error(`   ${localKeyPath}`);
      console.error('='.repeat(68) + '\n');
      process.exit(1);
    }
  }

  const appOptions = { credential };
  if (process.env.FIREBASE_PROJECT_ID) {
    appOptions.projectId = process.env.FIREBASE_PROJECT_ID;
  }
  admin.initializeApp(appOptions);
}

/**
 * Lee argumentos de línea de comandos simples: --key=value o --flag
 */
function parseArgs() {
  const args = {};
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith('--')) {
      const parts = arg.slice(2).split('=');
      const key = parts[0];
      const value = parts.length > 1 ? parts.slice(1).join('=') : true;
      args[key] = value;
    }
  }
  return args;
}

/**
 * Pregunta interactiva en terminal usando readline
 */
function askQuestion(rl, query, defaultValue) {
  return new Promise((resolve) => {
    const prompt = defaultValue ? `${query} [${defaultValue}]: ` : `${query}: `;
    rl.question(prompt, (answer) => {
      const result = answer.trim() || defaultValue || '';
      resolve(result);
    });
  });
}

/**
 * Envía el mensaje con FCM
 */
async function sendNotification({
  targetType,
  targetValue,
  severity,
  title,
  body,
  deviceId,
}) {
  const sevConfig = SEVERITY_CONFIG[severity] || SEVERITY_CONFIG.INFO;
  const collarId = deviceId || (targetType === 'topic' ? targetValue : 'COLLAR_9E2B4A1F8C3D2E5A');

  const message = {
    notification: {
      title,
      body,
    },
    data: {
      device_id: collarId,
    },
    android: {
      priority: sevConfig.priority,
      notification: {
        channelId: sevConfig.channelId,
        priority: sevConfig.androidNotificationPriority,
        defaultSound: true,
        defaultVibrateTimings: true,
        tag: collarId,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
  };

  if (targetType === 'topic') {
    message.topic = targetValue;
  } else {
    message.token = targetValue;
  }

  console.log('\n📤 Enviando mensaje a FCM...');
  console.log(`   Destino (${targetType}): ${targetValue}`);
  console.log(`   Collar / Device ID:    ${collarId}`);
  console.log(`   Severidad:             ${severity}`);
  console.log(`   Canal Android:         ${sevConfig.channelId}`);
  console.log(`   Título:                ${title}`);
  console.log(`   Cuerpo:                ${body}`);

  try {
    const response = await admin.messaging().send(message);
    console.log('\n✅ ¡Notificación enviada con éxito!');
    console.log(`   ID de respuesta FCM: ${response}`);
    console.log('\n📱 Qué esperar en tu dispositivo:');
    console.log('   - Si la app está abierta: se mostrará con flutter_local_notifications (en primer plano).');
    console.log('   - Si la app está en segundo plano o cerrada: la bandeja del sistema la mostrará.');
    console.log(`   - Al tocar la notificación: abrirá el historial de alertas del collar (${collarId}).`);
    return response;
  } catch (error) {
    console.error('\n❌ Error al enviar la notificación:', error.message);
    if (error.code) console.error(`   Código de error FCM: ${error.code}`);
    throw error;
  }
}

/**
 * Modo interactivo CLI
 */
async function runInteractive() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log('\n======================================================');
  console.log('   🐱 MichiLink - Enviador de Notificaciones Push');
  console.log('======================================================\n');

  try {
    // 1. Target Type
    console.log('1. ¿Cómo deseas enviar la notificación?');
    console.log('   [1] Por Topic (Collar registrado)');
    console.log('   [2] Por Token FCM (Dispositivo específico)');
    const targetOption = await askQuestion(rl, 'Elige una opción (1 o 2)', '1');
    const targetType = targetOption === '2' ? 'token' : 'topic';

    // 2. Target Value
    let targetValue = '';
    let deviceId = '';

    if (targetType === 'topic') {
      targetValue = await askQuestion(
        rl,
        'Ingresa el Topic / ID del collar',
        'COLLAR_9E2B4A1F8C3D2E5A'
      );
      deviceId = targetValue;
    } else {
      targetValue = await askQuestion(
        rl,
        'Pega el Token FCM del dispositivo'
      );
      if (!targetValue) {
        console.error('❌ El token no puede estar vacío.');
        rl.close();
        return;
      }
      deviceId = await askQuestion(
        rl,
        'ID del collar asociado (para redirección)',
        'COLLAR_9E2B4A1F8C3D2E5A'
      );
    }

    // 3. Severidad
    console.log('\n2. Selecciona la severidad de la alerta:');
    console.log('   [1] CRITICAL (Alerta roja, prioridad máxima)');
    console.log('   [2] WARNING  (Advertencia amarilla, prioridad alta)');
    console.log('   [3] INFO     (Informativo azul, prioridad normal)');
    const sevOption = await askQuestion(rl, 'Elige una opción (1, 2 o 3)', '1');
    const severity =
      sevOption === '2' ? 'WARNING' : sevOption === '3' ? 'INFO' : 'CRITICAL';

    const sevConfig = SEVERITY_CONFIG[severity];

    // 4. Título y Cuerpo
    console.log('\n3. Contenido del mensaje:');
    console.log('   [1] Usar título y mensaje predeterminados');
    console.log('   [2] Personalizar texto');
    const contentOption = await askQuestion(rl, 'Elige una opción (1 o 2)', '1');

    let title = sevConfig.defaultTitle;
    let body = sevConfig.defaultBody;

    if (contentOption === '2') {
      title = await askQuestion(rl, 'Título de la notificación', title);
      body = await askQuestion(rl, 'Cuerpo de la notificación', body);
    }

    rl.close();

    await sendNotification({
      targetType,
      targetValue,
      severity,
      title,
      body,
      deviceId,
    });
  } catch (e) {
    rl.close();
  }
}

/**
 * Muestra la ayuda si se pasa --help
 */
function showHelp() {
  console.log(`
Uso de MichiLink Notification Sender:

  Modo interactivo:
    npm start

  Modo directo por argumentos:
    node index.js --topic=COLLAR_9E2B4A1F8C3D2E5A --severity=CRITICAL
    node index.js --token=<FCM_TOKEN> --severity=WARNING --device-id=COLLAR_9E2B4A1F8C3D2E5A
    node index.js --topic=COLLAR_9E2B4A1F8C3D2E5A --severity=INFO --title="Hola" --body="Mundo"

Opciones disponibles:
    --topic=<nombre>        Topic de FCM al que enviar (ej. COLLAR_9E2B4A1F8C3D2E5A)
    --token=<token>         Token de registro FCM del dispositivo
    --severity=<tipo>       Severidad: CRITICAL, WARNING o INFO (default: CRITICAL)
    --device-id=<id>        ID del collar asociado (default: tomado del topic)
    --title=<texto>         Título personalizado
    --body=<texto>          Cuerpo de la notificación
    --help                  Muestra este mensaje de ayuda
`);
}

/**
 * Función Principal
 */
async function main() {
  const args = parseArgs();

  if (args.help) {
    showHelp();
    return;
  }

  initFirebase();

  // Si se pasaron argumentos por CLI, ejecutar directamente sin menú interactivo
  if (args.topic || args.token) {
    const targetType = args.topic ? 'topic' : 'token';
    const targetValue = args.topic || args.token;
    const severity = (args.severity || 'CRITICAL').toUpperCase();
    const sevConfig = SEVERITY_CONFIG[severity] || SEVERITY_CONFIG.CRITICAL;
    const deviceId = args['device-id'] || (targetType === 'topic' ? targetValue : 'COLLAR_9E2B4A1F8C3D2E5A');
    const title = args.title || sevConfig.defaultTitle;
    const body = args.body || sevConfig.defaultBody;

    await sendNotification({
      targetType,
      targetValue,
      severity,
      title,
      body,
      deviceId,
    });
  } else {
    await runInteractive();
  }
}

main().catch((err) => {
  console.error('\nProceso finalizado con error.');
  process.exit(1);
});

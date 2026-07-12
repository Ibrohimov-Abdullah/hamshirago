/**
 * Click SHOP API — Prepare & Complete webhooks
 *
 * Credentials:
 *   SERVICE_ID  : 101190
 *   MERCHANT_ID : 59988
 *   SECRET_KEY  : gBwef0ny6HXC
 *
 * After deploying, register these URLs in merchant.click.uz → Сервисы → ✏️:
 *   Prepare URL : https://us-central1-mening-hamshiram-off.cloudfunctions.net/clickPrepare
 *   Complete URL: https://us-central1-mening-hamshiram-off.cloudfunctions.net/clickComplete
 *
 * Click docs: https://docs.click.uz/click-api-request
 */

const functions = require('firebase-functions');
const admin     = require('firebase-admin');
const crypto    = require('crypto');

admin.initializeApp();

const SERVICE_ID = '101190';
const SECRET_KEY = 'gBwef0ny6HXC';

// ── MD5 helper ────────────────────────────────────────────────────────────────
function md5(str) {
  return crypto.createHash('md5').update(str, 'utf8').digest('hex');
}

// ── Sign verification ─────────────────────────────────────────────────────────
// action = 0 → PREPARE   sign = MD5(click_trans_id + service_id + SECRET_KEY + merchant_trans_id + amount + action + sign_time)
// action = 1 → COMPLETE  sign = MD5(click_trans_id + service_id + SECRET_KEY + merchant_trans_id + merchant_prepare_id + amount + action + sign_time)
function makeSign(body, action) {
  const parts = action === 0
    ? [body.click_trans_id, SERVICE_ID, SECRET_KEY, body.merchant_trans_id, body.amount, action, body.sign_time]
    : [body.click_trans_id, SERVICE_ID, SECRET_KEY, body.merchant_trans_id, body.merchant_prepare_id, body.amount, action, body.sign_time];
  return md5(parts.join(''));
}

// ── Standard error response builders ─────────────────────────────────────────
function prepareError(body, code, note) {
  return {
    click_trans_id:      body.click_trans_id,
    merchant_trans_id:   body.merchant_trans_id,
    merchant_prepare_id: 0,
    error:               code,
    error_note:          note,
  };
}

function completeError(body, code, note) {
  return {
    click_trans_id:     body.click_trans_id,
    merchant_trans_id:  body.merchant_trans_id,
    merchant_confirm_id: 0,
    error:              code,
    error_note:         note,
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// PREPARE  (action = 0)
// Click calls this BEFORE charging the user to verify the order is valid.
// ══════════════════════════════════════════════════════════════════════════════
exports.clickPrepare = functions.https.onRequest(async (req, res) => {
  res.set('Content-Type', 'application/json');

  if (req.method !== 'POST') {
    return res.status(405).json(prepareError({}, -8, 'Method not allowed'));
  }

  const body = req.body;
  const orderId = body.merchant_trans_id;

  functions.logger.info('[clickPrepare] received', { orderId, body });

  // 1. Verify signature
  const expectedSign = makeSign(body, 0);
  if (body.sign_string !== expectedSign) {
    functions.logger.warn('[clickPrepare] sign mismatch', { expected: expectedSign, got: body.sign_string });
    return res.json(prepareError(body, -1, 'SIGN CHECK FAILED'));
  }

  // 2. Fetch order from Firestore
  const db = admin.firestore();
  const orderDoc = await db.collection('orders').doc(orderId).get();

  if (!orderDoc.exists) {
    return res.json(prepareError(body, -5, 'Order not found'));
  }

  const order = orderDoc.data();

  // 3. Check already paid
  if (order.isPaid) {
    return res.json(prepareError(body, -4, 'Already paid'));
  }

  // 4. Verify amount (Click sends UZS as float, our totalPrice is integer UZS)
  const clickAmount = parseFloat(body.amount);
  const orderAmount = parseFloat(order.totalPrice);
  if (Math.abs(clickAmount - orderAmount) > 1) {   // allow 1 soum rounding tolerance
    functions.logger.warn('[clickPrepare] amount mismatch', { clickAmount, orderAmount });
    return res.json(prepareError(body, -2, 'Incorrect amount'));
  }

  // 5. Save prepare record and return success
  const prepareRef = await db.collection('click_prepares').add({
    click_trans_id:  body.click_trans_id,
    click_paydoc_id: body.click_paydoc_id,
    orderId:         orderId,
    amount:          clickAmount,
    sign_time:       body.sign_time,
    createdAt:       admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info('[clickPrepare] success', { orderId, prepareId: prepareRef.id });

  return res.json({
    click_trans_id:      body.click_trans_id,
    merchant_trans_id:   orderId,
    merchant_prepare_id: prepareRef.id,   // string doc ID — we return this back to Click
    error:               0,
    error_note:          'Success',
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// COMPLETE  (action = 1)
// Click calls this AFTER the user has paid (or after a cancellation).
// On success (error == 0): mark the Firestore order isPaid = true.
// ══════════════════════════════════════════════════════════════════════════════
exports.clickComplete = functions.https.onRequest(async (req, res) => {
  res.set('Content-Type', 'application/json');

  if (req.method !== 'POST') {
    return res.status(405).json(completeError({}, -8, 'Method not allowed'));
  }

  const body = req.body;
  const orderId = body.merchant_trans_id;

  functions.logger.info('[clickComplete] received', { orderId, body });

  // 1. Verify signature
  const expectedSign = makeSign(body, 1);
  if (body.sign_string !== expectedSign) {
    functions.logger.warn('[clickComplete] sign mismatch', { expected: expectedSign, got: body.sign_string });
    return res.json(completeError(body, -1, 'SIGN CHECK FAILED'));
  }

  // 2. Fetch order
  const db = admin.firestore();
  const orderRef = db.collection('orders').doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    return res.json(completeError(body, -5, 'Order not found'));
  }

  const order = orderDoc.data();

  // 3. If Click itself sent an error (user cancelled / payment failed) — just acknowledge
  const clickError = parseInt(body.error);
  if (clickError < 0) {
    functions.logger.info('[clickComplete] payment cancelled/failed by Click', { orderId, clickError });
    return res.json({
      click_trans_id:      body.click_trans_id,
      merchant_trans_id:   orderId,
      merchant_confirm_id: 0,
      error:               0,
      error_note:          'Payment cancelled, acknowledged',
    });
  }

  // 4. Check already paid (idempotency)
  if (order.isPaid) {
    functions.logger.info('[clickComplete] already paid', { orderId });
    return res.json(completeError(body, -4, 'Already paid'));
  }

  // 5. Verify amount
  const clickAmount  = parseFloat(body.amount);
  const orderAmount  = parseFloat(order.totalPrice);
  if (Math.abs(clickAmount - orderAmount) > 1) {
    functions.logger.warn('[clickComplete] amount mismatch', { clickAmount, orderAmount });
    return res.json(completeError(body, -2, 'Incorrect amount'));
  }

  // 6. Mark order as paid — stays 'pending' so admin can assign a nurse
  await orderRef.update({
    isPaid:       true,
    paidAt:       admin.firestore.FieldValue.serverTimestamp(),
    clickTransId: body.click_trans_id,
    status:       'pending',   // admin assigns nurse manually
  });

  // 7. Save confirm record
  const confirmRef = await db.collection('click_confirms').add({
    click_trans_id:     body.click_trans_id,
    orderId:            orderId,
    amount:             clickAmount,
    sign_time:          body.sign_time,
    createdAt:          admin.firestore.FieldValue.serverTimestamp(),
  });

  functions.logger.info('[clickComplete] success — order marked as paid', { orderId, confirmId: confirmRef.id });

  return res.json({
    click_trans_id:      body.click_trans_id,
    merchant_trans_id:   orderId,
    merchant_confirm_id: confirmRef.id,
    error:               0,
    error_note:          'Success',
  });
});

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN ASSIGN NURSE  (callable from admin panel)
// Admin picks a nurse for an order → update Firestore + send FCM to nurse.
// ══════════════════════════════════════════════════════════════════════════════
exports.adminAssignNurse = functions.https.onCall(async (data, context) => {
  const { orderId, nurseId } = data;
  if (!orderId || !nurseId) throw new functions.https.HttpsError('invalid-argument', 'orderId and nurseId required');

  const db = admin.firestore();

  // 1. Fetch nurse
  const nurseDoc = await db.collection('nurses').doc(nurseId).get();
  if (!nurseDoc.exists) throw new functions.https.HttpsError('not-found', 'Nurse not found');
  const nurse = nurseDoc.data();
  const nurseName = `${nurse.name || ''} ${nurse.surname || ''}`.trim();
  const fcmToken  = nurse.fcmToken;

  // 2. Fetch order for client info
  const orderDoc = await db.collection('orders').doc(orderId).get();
  if (!orderDoc.exists) throw new functions.https.HttpsError('not-found', 'Order not found');
  const order = orderDoc.data();

  // 3. Update order
  await db.collection('orders').doc(orderId).update({
    nurseId,
    nurseName,
    status:     'accepted',
    acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 4. Mark nurse as busy
  await db.collection('nurses').doc(nurseId).update({ isAvailable: false });

  // 5. Send FCM push to nurse (if token available)
  if (fcmToken) {
    const address = order.address?.text || 'Andijon';
    const clientName = order.clientName || 'Mijoz';
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: '🏥 Yangi buyurtma tayinlandi!',
          body:  `${clientName} — ${address}`,
        },
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'orders' },
        },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
      });
      functions.logger.info('[adminAssignNurse] FCM sent', { nurseId, fcmToken });
    } catch (fcmErr) {
      functions.logger.warn('[adminAssignNurse] FCM failed (non-fatal)', { error: fcmErr.message });
    }
  } else {
    functions.logger.warn('[adminAssignNurse] no FCM token for nurse', { nurseId });
  }

  functions.logger.info('[adminAssignNurse] assigned', { orderId, nurseId, nurseName });
  return { success: true, nurseName };
});

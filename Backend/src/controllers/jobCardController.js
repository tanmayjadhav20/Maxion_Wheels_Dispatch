const { getStore, saveStore } = require('../config/db');
const { formatNumber } = require('../utils/qr');

/**
 * Module 13 — Job Card Report for Stock Booking (SSR Section 9)
 * Automated shift-end reporting of full pallet production (P pallets & PM-Full pallets)
 * for stock booking. Includes item summary, pallet details, half pallets note,
 * supervisor approval, submission tracking, and variance reporting.
 */

function getJobCards(req, res) {
  const store = getStore();

  // Find full pallets produced that are not yet on any Job Card (Pending Booking Report)
  const palletsInJobCards = new Set();
  (store.jobCards || []).forEach(jc => {
    (jc.palletsIncluded || []).forEach(p => palletsInJobCards.add(p));
  });

  const pendingPallets = (store.pallets || []).filter(p =>
    (p.typeSeries === 'P' || p.typeSeries === 'PM' || p.status === 'CLOSED_FULL' || p.status === 'CLOSED_MERGED_FULL' || p.status === 'STORED') &&
    (p.packedQty >= (p.stdQty || 96)) &&
    !palletsInJobCards.has(p.palletNumber)
  );

  // Variance report: Pallets reported on a Job Card that were later modified by QA or conversion
  const variancePallets = (store.pallets || []).filter(p =>
    palletsInJobCards.has(p.palletNumber) &&
    (p.status === 'UNDER_QA_INSPECTION' || p.status === 'CLOSED_QA_SHORT' || p.status === 'SPLIT_CONSUMED')
  );

  res.json({
    success: true,
    jobCards: store.jobCards || [],
    pendingBookingReport: pendingPallets,
    varianceReport: variancePallets
  });
}

function generateJobCard(req, res) {
  const { date = new Date().toISOString().split('T')[0], shift = 'A', line = 'PL2' } = req.body;
  const store = getStore();

  // Find closed full / stored pallets produced on date/shift that are not yet in a Job Card
  const existingPalletsInJobCards = new Set();
  (store.jobCards || []).forEach(jc => {
    (jc.palletsIncluded || []).forEach(p => existingPalletsInJobCards.add(p));
  });

  const eligibleFullPallets = (store.pallets || []).filter(p =>
    (p.typeSeries === 'P' || p.typeSeries === 'PM' || p.status === 'STORED' || p.status === 'CLOSED_FULL' || p.status === 'CLOSED_MERGED_FULL') &&
    (p.packedQty >= (p.stdQty || 96)) &&
    !existingPalletsInJobCards.has(p.palletNumber)
  );

  const halfPalletsProduced = (store.pallets || []).filter(p =>
    (p.typeSeries === 'H' || p.status === 'STORED_HALF') &&
    !existingPalletsInJobCards.has(p.palletNumber)
  );

  if (eligibleFullPallets.length === 0) {
    return res.status(400).json({
      success: false,
      message: `No unassigned full pallets available to generate Job Card for Date ${date}, Shift ${shift}`
    });
  }

  const totalWheels = eligibleFullPallets.reduce((sum, p) => sum + (p.packedQty || p.stdQty || 96), 0);
  const jobCardNumber = formatNumber('JC', '26', shift);

  // Group item-wise summary
  const itemSummaryMap = {};
  eligibleFullPallets.forEach(p => {
    if (!itemSummaryMap[p.itemCode]) {
      itemSummaryMap[p.itemCode] = { itemCode: p.itemCode, fullPalletsCount: 0, wheelsPerPallet: p.stdQty || 96, totalWheels: 0 };
    }
    itemSummaryMap[p.itemCode].fullPalletsCount++;
    itemSummaryMap[p.itemCode].totalWheels += (p.packedQty || p.stdQty || 96);
  });

  const newJobCard = {
    jobCardNumber,
    date,
    shift,
    line,
    fullPalletsCount: eligibleFullPallets.length,
    totalWheels,
    status: 'DRAFT', // DRAFT -> APPROVED -> SUBMITTED_TO_MAXION
    maxionBookingRef: null,
    itemSummary: Object.values(itemSummaryMap),
    halfPalletsNote: {
      halfPalletsCount: halfPalletsProduced.length,
      totalHalfWheels: halfPalletsProduced.reduce((sum, p) => sum + (p.packedQty || 0), 0),
      note: 'Half pallets produced in the same period are shown separately for information and are NOT part of the stock booking figure.'
    },
    signatures: {
      preparedBy: req.user ? req.user.name : 'Dispatch Executive',
      checkedBy: 'Production Supervisor',
      approvedBy: 'Dispatch Head'
    },
    submittedBy: req.user ? req.user.name : 'Shift Supervisor',
    submittedAt: new Date().toISOString(),
    palletsIncluded: eligibleFullPallets.map(p => p.palletNumber),
    palletDetails: eligibleFullPallets.map(p => ({
      palletNumber: p.palletNumber,
      itemCode: p.itemCode,
      typeSeries: p.typeSeries,
      packedQty: p.packedQty,
      locationCode: p.locationCode,
      closedAt: p.closedAt || p.createdAt
    }))
  };

  if (!store.jobCards) store.jobCards = [];
  store.jobCards.unshift(newJobCard);
  saveStore();

  res.json({
    success: true,
    message: `Job Card ${jobCardNumber} generated successfully for Shift ${shift} with ${eligibleFullPallets.length} full pallets (${totalWheels} wheels)`,
    jobCard: newJobCard
  });
}

function approveJobCard(req, res) {
  const { jobCardNumber, approvedBy = 'Dispatch Head' } = req.body;
  const store = getStore();

  const jobCard = (store.jobCards || []).find(j => j.jobCardNumber === jobCardNumber);
  if (!jobCard) {
    return res.status(404).json({ success: false, message: `Job Card ${jobCardNumber} not found` });
  }

  jobCard.status = 'APPROVED';
  jobCard.approvedBy = approvedBy;
  jobCard.approvedAt = new Date().toISOString();

  saveStore();

  res.json({
    success: true,
    message: `Job Card ${jobCardNumber} approved by ${approvedBy}. Ready for submission to Maxion ERP.`,
    jobCard
  });
}

function submitJobCardToMaxion(req, res) {
  const { jobCardNumber, maxionBookingRef } = req.body;
  const store = getStore();

  const jobCard = (store.jobCards || []).find(j => j.jobCardNumber === jobCardNumber);
  if (!jobCard) {
    return res.status(404).json({ success: false, message: `Job Card ${jobCardNumber} not found` });
  }

  const bookingReference = maxionBookingRef || `MXN-ERP-${String(Date.now()).slice(-6)}`;

  jobCard.status = 'SUBMITTED_TO_MAXION';
  jobCard.maxionBookingRef = bookingReference;
  jobCard.bookedAt = new Date().toISOString();
  jobCard.bookedBy = req.user ? req.user.name : 'Stock Booking Manager';

  saveStore();

  res.json({
    success: true,
    message: `Job Card ${jobCardNumber} submitted to Maxion ERP for Stock Booking. Reference: ${bookingReference}`,
    jobCard
  });
}

module.exports = {
  getJobCards,
  generateJobCard,
  approveJobCard,
  submitJobCardToMaxion
};

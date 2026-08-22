const { getStore } = require('../config/db');

function getDashboardStats(req, res) {
  const store = getStore();

  const latestPlan = store.paintPlans[0] || null;
  let plannedTotal = 0;
  let packedTotal = 0;

  if (latestPlan) {
    latestPlan.items.forEach(i => {
      plannedTotal += i.plannedQty || 0;
      packedTotal += i.packedQty || 0;
    });
  }

  const achievementPct = plannedTotal > 0 ? ((packedTotal / plannedTotal) * 100).toFixed(1) : '0.0';

  let fullCount = 0;
  let halfCount = 0;
  let mergedCount = 0;

  store.pallets.forEach(p => {
    if (p.typeSeries === 'P' || p.status === 'CLOSED_FULL' || p.status === 'STORED') fullCount++;
    if (p.typeSeries === 'H' || p.status === 'STORED_HALF') halfCount++;
    if (p.typeSeries === 'M' || p.status === 'CLOSED_MERGED_FULL' || p.status === 'CLOSED_MERGED_HALF') mergedCount++;
  });

  const openHalfPallets = store.pallets.filter(p => p.typeSeries === 'H' || p.status === 'STORED_HALF');
  const oldestHalf = openHalfPallets[0] || null;

  const gatedOutShipments = store.gatePasses.filter(g => g.status === 'DISPATCHED').length;

  res.json({
    success: true,
    stats: {
      achievementPct,
      packedTotal,
      plannedTotal,
      fullCount,
      halfCount,
      mergedCount,
      openHalfCount: openHalfPallets.length,
      oldestHalfNumber: oldestHalf ? oldestHalf.palletNumber : 'None',
      oldestHalfAge: oldestHalf ? `${oldestHalf.ageDays || 1} day` : 'N/A',
      gatedOutShipments,
      activePlan: latestPlan
    }
  });
}

module.exports = {
  getDashboardStats
};

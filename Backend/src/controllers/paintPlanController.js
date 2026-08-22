const { getStore, saveStore } = require('../config/db');
const { formatNumber } = require('../utils/qr');

function getPaintPlans(req, res) {
  const store = getStore();
  res.json({ success: true, paintPlans: store.paintPlans });
}

function createOrUpdatePaintPlan(req, res) {
  const { date, shift, line, items } = req.body;
  const store = getStore();

  const planNumber = formatNumber('PLN');

  const processedItems = items.map(i => {
    const master = store.items.find(m => m.itemCode === i.itemCode);
    const stdQty = master ? master.stdPalletQty : 96;
    const fullPalletsExpected = Math.floor(i.plannedQty / stdQty);
    const looseWheelsExpected = i.plannedQty % stdQty;
    return {
      itemCode: i.itemCode,
      plannedQty: i.plannedQty,
      fullPalletsExpected,
      looseWheelsExpected,
      packedQty: 0
    };
  });

  const newPlan = {
    planNumber,
    date: date || new Date().toISOString().split('T')[0],
    shift: shift || 'A',
    line: line || 'PL2',
    status: 'RELEASED',
    version: 1,
    releasedBy: req.user ? req.user.name : 'Dispatch Planner',
    releasedAt: new Date().toISOString(),
    items: processedItems
  };

  store.paintPlans.unshift(newPlan);
  saveStore();

  res.json({ success: true, message: 'Paint plan created and released to floor', paintPlan: newPlan });
}

function getPlanVsActual(req, res) {
  const store = getStore();
  const latestPlan = store.paintPlans[0] || null;

  if (!latestPlan) {
    return res.json({ success: true, summary: [] });
  }

  const summary = latestPlan.items.map(item => {
    const master = store.items.find(m => m.itemCode === item.itemCode);
    return {
      itemCode: item.itemCode,
      description: master ? master.description : item.itemCode,
      plannedQty: item.plannedQty,
      packedQty: item.packedQty,
      varianceQty: item.packedQty - item.plannedQty,
      completionPercentage: item.plannedQty > 0 ? ((item.packedQty / item.plannedQty) * 100).toFixed(1) : 0
    };
  });

  res.json({ success: true, planNumber: latestPlan.planNumber, summary });
}

module.exports = {
  getPaintPlans,
  createOrUpdatePaintPlan,
  getPlanVsActual
};

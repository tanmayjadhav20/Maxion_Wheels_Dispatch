const { getStore, saveStore } = require('../config/db');
const { formatNumber } = require('../utils/qr');

function getPaintPlans(req, res) {
  const store = getStore();
  res.json({ success: true, paintPlans: store.paintPlans });
}

function createOrUpdatePaintPlan(req, res) {
  const { date, shift, line, items, createNewPallet = false } = req.body;
  const store = getStore();

  const planNumber = formatNumber('PLN');
  let newPalletCreated = null;
  const itemMatchStatuses = [];

  const processedItems = items.map(i => {
    let master = store.items.find(m => m.itemCode === i.itemCode);
    if (!master) {
      master = {
        itemCode: i.itemCode,
        description: i.description || `Automotive Wheel ${i.itemCode}`,
        stdPalletQty: 4,
        wheelsPerLayer: 1,
        layersPerPallet: 4,
        palletType: 'STEEL-FRAME-A',
        separatorType: 'CORRUGATED-17',
        separatorQtyPerPallet: 3,
        unitWeightKg: 10.0,
        defaultCustomer: 'Tata Motors Pune',
        allowMerge: true
      };
      if (!store.items) store.items = [];
      store.items.push(master);
    }
    const stdQty = master.stdPalletQty || 4;
    const fullPalletsExpected = Math.floor(i.plannedQty / stdQty);
    const looseWheelsExpected = i.plannedQty % stdQty;

    // Check if matching half stored pallet exists in inventory
    const matchingHalfPallet = (store.pallets || []).find(p =>
      p.itemCode === i.itemCode && (p.status === 'STORED_HALF' || p.typeSeries === 'H')
    );

    const hasHalfMatch = !!matchingHalfPallet;

    // If createNewPallet is requested OR if no matching half stored pallet exists
    let allocatedPallet = null;
    if (createNewPallet || !hasHalfMatch) {
      const palletNo = formatNumber('P');
      newPalletCreated = palletNo;
      allocatedPallet = {
        palletNumber: palletNo,
        typeSeries: 'P',
        itemCode: i.itemCode,
        packedQty: 0,
        stdQty: stdQty,
        status: 'OPEN',
        locationCode: 'WH1-STG-01',
        isHold: false,
        holdReason: null,
        createdAt: new Date().toISOString(),
        createdBy: req.user ? req.user.name : 'Dispatch Planner',
        wheels: []
      };
      if (!store.pallets) store.pallets = [];
      store.pallets.unshift(allocatedPallet);
    }

    itemMatchStatuses.push({
      itemCode: i.itemCode,
      hasHalfMatch,
      matchedHalfPalletNumber: matchingHalfPallet ? matchingHalfPallet.palletNumber : null,
      newPalletAllocated: allocatedPallet ? allocatedPallet.palletNumber : null
    });

    return {
      itemCode: i.itemCode,
      plannedQty: i.plannedQty,
      fullPalletsExpected,
      looseWheelsExpected,
      packedQty: 0,
      allocatedPalletNumber: allocatedPallet ? allocatedPallet.palletNumber : (matchingHalfPallet ? matchingHalfPallet.palletNumber : null)
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
    items: processedItems,
    newPalletCreated,
    itemMatchStatuses
  };

  store.paintPlans.unshift(newPlan);

  // Automatically update store.activePallet for the Pack Point screen
  if (processedItems.length > 0) {
    const firstItem = processedItems[0];
    const itemMaster = store.items.find(m => m.itemCode === firstItem.itemCode);
    const stdQty = itemMaster ? itemMaster.stdPalletQty : 4;
    const activePalletNo = firstItem.allocatedPalletNumber || formatNumber('P');

    store.activePallet = {
      palletNumber: activePalletNo,
      typeSeries: activePalletNo.startsWith('H') ? 'H' : 'P',
      itemCode: firstItem.itemCode,
      packedQty: 0,
      stdQty: stdQty,
      status: 'PACKING',
      wheels: [],
      currentLayer: 1,
      createdAt: new Date().toISOString()
    };
  }

  saveStore();

  res.json({
    success: true,
    message: newPalletCreated
      ? `Paint plan created and new pallet ${newPalletCreated} allocated!`
      : 'Paint plan created and released to floor using existing half pallet',
    paintPlan: newPlan,
    newPalletCreated,
    itemMatchStatuses
  });
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

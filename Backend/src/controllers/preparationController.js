const { getStore } = require('../config/db');

function getPreparationChecklist(req, res) {
  const store = getStore();
  const latestPlan = store.paintPlans[0];

  if (!latestPlan) {
    return res.json({ success: true, checklist: [], halfPalletsToRecall: [] });
  }

  const checklist = [];
  const halfPalletsToRecall = [];

  for (const planItem of latestPlan.items) {
    const itemMaster = store.items.find(m => m.itemCode === planItem.itemCode);
    const stdQty = itemMaster ? itemMaster.stdPalletQty : 96;

    // Find reusable half pallets in storage
    const storedHalfPallets = store.pallets.filter(p =>
      p.itemCode === planItem.itemCode &&
      (p.status === 'STORED_HALF' || p.typeSeries === 'H')
    );

    let halfPalletsReusedCount = 0;
    storedHalfPallets.forEach(hp => {
      halfPalletsToRecall.push({
        palletNumber: hp.palletNumber,
        itemCode: hp.itemCode,
        currentQty: hp.packedQty,
        shortfallQty: stdQty - hp.packedQty,
        locationCode: hp.locationCode,
        ageDays: hp.ageDays || 1
      });
      halfPalletsReusedCount++;
    });

    const palletsNeeded = Math.max(0, Math.ceil(planItem.plannedQty / stdQty) - halfPalletsReusedCount);
    const separatorsNeeded = palletsNeeded * (itemMaster ? itemMaster.separatorQtyPerPallet : 3);

    checklist.push({
      itemCode: planItem.itemCode,
      description: itemMaster ? itemMaster.description : planItem.itemCode,
      plannedQty: planItem.plannedQty,
      palletType: itemMaster ? itemMaster.palletType : 'STEEL-FRAME-A',
      palletsNeeded,
      separatorType: itemMaster ? itemMaster.separatorType : 'CORRUGATED-17',
      separatorsNeeded,
      halfPalletsToReuseCount: halfPalletsReusedCount,
      isStaged: false
    });
  }

  res.json({
    success: true,
    planNumber: latestPlan.planNumber,
    checklist,
    halfPalletsToRecall
  });
}

module.exports = {
  getPreparationChecklist
};

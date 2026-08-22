enum UserRole {
  superAdmin,
  admin,
  dispatchPlanner,
  supervisor,
  packOperator,
  prepOperator,
  putawayOperator,
  picker,
  warehouseManager,
  dispatchExec,
  loadingSupervisor,
  stores,
  security;

  static UserRole fromCode(String code) {
    switch (code) {
      case 'superAdmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'dispatchPlanner':
        return UserRole.dispatchPlanner;
      case 'supervisor':
        return UserRole.supervisor;
      case 'packOperator':
        return UserRole.packOperator;
      case 'prepOperator':
        return UserRole.prepOperator;
      case 'putawayOperator':
        return UserRole.putawayOperator;
      case 'picker':
        return UserRole.picker;
      case 'warehouseManager':
        return UserRole.warehouseManager;
      case 'dispatchExec':
        return UserRole.dispatchExec;
      case 'loadingSupervisor':
        return UserRole.loadingSupervisor;
      case 'stores':
        return UserRole.stores;
      case 'security':
        return UserRole.security;
      default:
        return UserRole.packOperator;
    }
  }
}

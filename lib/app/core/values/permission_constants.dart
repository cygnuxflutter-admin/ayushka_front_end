/// Standard constants for Role & Permission-Based Access Control (RBAC).
abstract class PermissionModules {
  static const String cow = 'COW';
  static const String shed = 'SHED';
  static const String gaushala = 'GAUSHALA';
  static const String user = 'USER';
  static const String role = 'ROLE';
  static const String breedType = 'BREED_TYPE';
  static const String type = 'TYPE';
  static const String feedStock = 'FEED_STOCK';
  static const String medicalStock = 'MEDICAL_STOCK';
  static const String treatment = 'TREATMENT';
  static const String workerMgmt = 'WORKER_MGMT';
  static const String milkMgmt = 'MILK_MGMT';

  /// List of all system modules
  static const List<String> all = [
    cow,
    shed,
    gaushala,
    user,
    role,
    breedType,
    type,
    feedStock,
    medicalStock,
    treatment,
    workerMgmt,
    milkMgmt,
  ];

  /// Human-readable display label for each module code
  static String getLabel(String moduleCode) {
    switch (moduleCode.toUpperCase()) {
      case cow:
        return 'Cow Management';
      case shed:
        return 'Shed Management';
      case gaushala:
        return 'Gaushala Management';
      case user:
        return 'User Management';
      case role:
        return 'Role Management';
      case breedType:
        return 'Breed Types';
      case type:
        return 'Cattle Types';
      case feedStock:
        return 'Feed & Stock Management';
      case medicalStock:
        return 'Medical Stock';
      case treatment:
        return 'Treatments & Health';
      case workerMgmt:
        return 'Worker & Department';
      case milkMgmt:
        return 'Milk Management';
      default:
        return moduleCode;
    }
  }
}

/// Standard Sub-Module codes
abstract class PermissionSubModules {
  static const String cowList = 'COW_LIST';
  static const String shedTransfer = 'SHED_TRANSFER';
  static const String shedList = 'SHED_LIST';
  static const String gaushalaList = 'GAUSHALA_LIST';
  static const String userList = 'USER_LIST';
  static const String roleList = 'ROLE_LIST';
  static const String breedTypeList = 'BREED_TYPE_LIST';
  static const String typeList = 'TYPE_LIST';
  static const String feedItems = 'FEED_ITEMS';
  static const String stockTransaction = 'STOCK_TRANSACTION';
  static const String medicalItems = 'MEDICAL_ITEMS';
  static const String treatmentList = 'TREATMENT_LIST';
  static const String doseSchedule = 'DOSE_SCHEDULE';
  static const String departmentList = 'DEPARTMENT_LIST';
  static const String workerList = 'WORKER_LIST';
  static const String milkProduction = 'MILK_PRODUCTION';
  static const String milkDistribution = 'MILK_DISTRIBUTION';

  /// Human-readable display label for each sub-module code
  static String getLabel(String subModuleCode) {
    switch (subModuleCode.toUpperCase()) {
      case cowList:
        return 'Cow Records';
      case shedTransfer:
        return 'Shed Transfers';
      case shedList:
        return 'Shed Master';
      case gaushalaList:
        return 'Gaushala Master';
      case userList:
        return 'User Master';
      case roleList:
        return 'Role Master';
      case breedTypeList:
        return 'Breed Master';
      case typeList:
        return 'Cattle Type Master';
      case feedItems:
        return 'Feed Item Master';
      case stockTransaction:
        return 'Stock Transactions';
      case medicalItems:
        return 'Medical Stock & Items';
      case treatmentList:
        return 'Treatment Records';
      case doseSchedule:
        return 'Dose Schedules';
      case departmentList:
        return 'Department Master';
      case workerList:
        return 'Worker Master';
      case milkProduction:
        return 'Milk Production';
      case milkDistribution:
        return 'Milk Distribution';
      default:
        return subModuleCode;
    }
  }

  /// Mapping from sub-module to parent module code
  static String getParentModule(String subModuleCode) {
    switch (subModuleCode.toUpperCase()) {
      case cowList:
        return PermissionModules.cow;
      case shedTransfer:
      case shedList:
        return PermissionModules.shed;
      case gaushalaList:
        return PermissionModules.gaushala;
      case userList:
        return PermissionModules.user;
      case roleList:
        return PermissionModules.role;
      case breedTypeList:
        return PermissionModules.breedType;
      case typeList:
        return PermissionModules.type;
      case feedItems:
      case stockTransaction:
        return PermissionModules.feedStock;
      case medicalItems:
        return PermissionModules.medicalStock;
      case treatmentList:
      case doseSchedule:
        return PermissionModules.treatment;
      case departmentList:
      case workerList:
        return PermissionModules.workerMgmt;
      case milkProduction:
      case milkDistribution:
        return PermissionModules.milkMgmt;
      default:
        return '';
    }
  }
}

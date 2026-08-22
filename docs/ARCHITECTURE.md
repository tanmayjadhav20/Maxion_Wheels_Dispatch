# Maxion Wheels Dispatch System — System Architecture Document

## 1. System Topology & Data Flow

```
[ Plant Floor / HHT Guns ]          [ Dispatch Desktop Portal ]
     |                                    |
     +-------------- REST / HTTP ---------+
                        |
            [ Node.js API Gateway ]
                        |
          +-------------+-------------+
          |                           |
  [ Controller Layer ]      [ Middleware Layer ]
          |                           |
  [ Data Access / DB ]      [ Sync & Audit Logger ]
```

### 1.1 Client Layer (Flutter Web & HHT Terminal)
- **State Management**: Built on `flutter_riverpod` (StateNotifierProvider / Provider pattern).
- **Navigation & RBAC Router**: `go_router` wrapped with `RefreshGate` and `StatefulShellRoute` providing role-based route access controls.
- **Scanning Engine**:
  - Hardware Scanners (Keypress / HID Listener).
  - HTML5 Live System Camera Access via `getUserMedia` and `ui_web.platformViewRegistry` (`CameraScannerDialog`).

### 1.2 Offline Synchronization Engine
- **Queue Storage**: In-memory and IndexedDB offline queue storage.
- **State Transitions**: `OFFLINE_QUEUED` → `SYNCING` → `SYNCED` or `SYNC_FAILED`.
- **Conflict Resolution**: Last-Write-Wins with server timestamp verification.

---

## 2. Security & Role-Based Access Control (RBAC)

The system enforces granular role-based authorization across both client UI navigation and backend API endpoints:

```json
{
  "superAdmin": ["*"],
  "packOperator": ["pack-point", "preparation"],
  "warehouseManager": ["dashboard", "paint-plan", "picking", "warehouse", "returnables", "reports"],
  "picker": ["hht-picking", "warehouse"],
  "security": ["dispatch"]
}
```

---

## 3. Data Models & Poka-Yoke Controls

### 3.1 Wheel Serial & Pallet Master QR Schema
- **Wheel Serial Format**: `WHL-[WHEEL_CODE]-[JULIAN_DATE]-[SEQ]` (e.g. `WHL-MX1902-260822-0042`)
- **Pallet Master QR Format**: `PLT-[CUSTOMER]-[DATE]-[PALLET_SEQ]` (e.g. `PLT-MATA-20260822-001`)

### 3.2 2-Step Poka-Yoke Directed Picking Workflow
1. **Step 1 (Location Scan)**: HHT operator must scan physical bin location barcode (e.g. `WH1-A-01-A1`). System checks location code against picklist item target.
2. **Step 2 (Pallet Scan)**: HHT operator scans Pallet Master QR on the physical pallet. System validates pallet ID against assigned picklist line item. Auto-advances to next pick item upon validation match.

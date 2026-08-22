# Maxion Wheels Dispatch Operations Digitalization System
> Powered by **Vistar Logitek** Design & Engineering

An enterprise-grade, offline-first Dispatch Operations Digitalization Platform for **Maxion Wheels**, featuring 100% QR-code wheel & pallet traceability, automated paint line scheduling, HHT-directed picking, Poka-Yoke scanning verification, and automated vehicle gate passes.

---

## 🌟 Key Modules & Capability Matrix

| Module | Feature / Operational Goal | Primary User Role | Key Controls & Logic |
|---|---|---|---|
| **Mod 1: Paint Line Plan** | Digital paint plan entry & queue management | Warehouse Manager / Dispatch Planner | Screen instead of whiteboard, auto-sort by priority & SLA |
| **Mod 2: Wheel Preparation** | Half-pallet & loose wheel staging register | Pack Point Operator | Register partial quantities, assign temporary barcodes |
| **Mod 3–5: Pack Point & QR** | Real-time packing & Master Pallet QR printing | Pack Point Operator | Direct thermal label printing, 100% wheel verification |
| **Mod 6: Warehouse Putaway** | Bin location assignment & inventory tracking | Forklift Operator / HHT | Bin validation, physical barcode scan, capacity checks |
| **Mod 7: Offline Sync Engine** | Offline-first transaction queueing | All System Users | IndexedDB local queue, auto-sync upon reconnection |
| **Mod 8: Directed Picking** | Indent creation & HHT picking execution | Manager (Indent) / HHT Picker | Strict 2-step scan (Location → Pallet), Poka-Yoke error prevention |
| **Mod 9: Gate Pass & Loading** | Vehicle loading verification & Gate Pass printing | Security Guard / Dispatcher | QR verification of loaded pallets, PDF gate pass printing |
| **Mod 10: Traceability** | End-to-end wheel & pallet lifecycle audit | Quality / Super Admin | Full history lookup by Wheel Serial / Pallet QR / Job Card |

---

## 🏗️ Architecture & Technology Stack

```
           +-------------------------------------------------------+
           |       Frontend (Flutter Web / Android HHT)           |
           |  Riverpod 2.0 • GoRouter • Dio • Vistar Design Tokens |
           +-------------------------------------------------------+
                                       |
                           REST API / WebSockets
                                       |
           +-------------------------------------------------------+
           |           Backend Service (Node.js / Express)         |
           |  JWT Auth • Prisma ORM • SQLite / PostgreSQL • Winston  |
           +-------------------------------------------------------+
```

- **Frontend**: Flutter (Web & Android HHT Terminal), Riverpod 2.6, GoRouter, Dio HTTP Client, HTML5 Camera Access (`getUserMedia`).
- **Design System**: Vistar Premium Dark Design System (`--ribbon` 115° brand gradient, near-black surface scale `#070611` - `#16142A`, hairline borders, `Bricolage Grotesque` & `Inter` typography).
- **Backend**: Node.js, Express, RESTful APIs, JWT Authentication, JSON Schema Validation.
- **Hardware Integration**: HTML5 Camera Webview, Zebra/Honeywell 2D Barcode Scanners (USB/HID & Bluetooth), Zebra ZPL / PDF Printers.

---

## 🔐 User Role Matrix & Test Credentials

| Role Code | User Name | Role Title | Default PIN | Access Privileges |
|---|---|---|---|---|
| `EMP001` | Tanmay | Super Admin | `1234` | Full access to all 15 modules & management settings |
| `EMP002` | Ramesh | Pack Point Operator | `1111` | Wheel packing, Master QR printing, Preparation register |
| `EMP003` | Suresh | Warehouse Manager | `2222` | Paint plan management, Indent entry, Stock monitoring |
| `EMP004` | Vikram | Security Officer | `3333` | Vehicle loading verification, Gate pass verification & print |
| `EMP005` | John | HHT Forklift Operator | `4444` | HHT Directed Picking & Warehouse Putaway (Scanner-only mode) |

---

## 🚀 Quick Start Guide

### Prerequisites
- Node.js (v18.x or later)
- Flutter SDK (v3.22.x or later)

### 1. Start Backend Server
```bash
cd Backend
npm install
npm run dev
# Server running on http://localhost:5000
```

### 2. Start Frontend Web Client
```bash
cd Frontend
flutter pub get
flutter run -d chrome --web-port=3000
# App opening on http://localhost:3000
```

---

## 📄 Core Project Documentation Assets

Detailed architectural and operational documentation is located in the [`/docs`](./docs) directory:

- 📘 [**Architecture Overview**](./docs/ARCHITECTURE.md) — Technical system breakdown, offline engine, and data pipelines.
- 📙 [**System Specifications**](./docs/SYSTEM_SPECIFICATION.md) — Complete module-by-module functional requirements and Poka-Yoke rules.

---

*Copyright © 2026 Maxion Wheels & Vistar Logitek. All rights reserved.*

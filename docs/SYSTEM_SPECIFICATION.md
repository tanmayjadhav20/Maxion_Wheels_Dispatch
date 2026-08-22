# Maxion Wheels Dispatch System — Module Specifications

## Module 1: Digital Paint Line Planning
- Replace physical whiteboard with digital plan board.
- Supports sequence re-ordering, SLA countdown timer, color coding per OEM requirement.
- Exports paint schedule to plant floor display screens.

## Module 2: Preparation & Half-Pallet Register
- Manages staging of loose wheels and partial pallet inventory.
- Real-time conversion tracking between OEM (Original Equipment Manufacturer) and SPD (Spare Parts Division) specifications.

## Module 3-5: Pack Point & Master QR Printing
- Enforces 100% individual wheel barcode scan before pallet container seal.
- Generates and prints Master Pallet QR sticker via ZPL thermal printer integration.

## Module 6: Warehouse Bin Putaway
- Directed putaway routing to designated warehouse racks/bins.
- Real-time stock level updates across storage zones.

## Module 8: HHT Directed Picking
- Handheld terminal (HHT) picking workflow for forklift operators.
- Strict 2-step scanning validation (Scan Bin Location → Scan Pallet Master QR).
- Real-time audio feedback and poka-yoke error prevention.

## Module 9: Vehicle Loading & Gate Pass
- Verifies pallet QR codes as pallets are loaded onto customer trucks.
- Generates official Dispatch Gate Pass document with QR code seal, driver signature block, and truck weight register.

## Module 10: 100% Traceability Audit
- Search any wheel by serial number, job card number, or pallet master QR code.
- Full audit log displaying paint date, packing operator, putaway location, picking timestamp, vehicle gate-out timestamp, and customer invoice number.

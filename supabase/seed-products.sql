-- seed-products.sql
-- Adds 25 demo products across the six existing categories and backfills
-- image_url on any existing rows that are missing one.
--
-- Images use https://picsum.photos/seed/<sku>/600/400 — a deterministic
-- placeholder service, so the same SKU always returns the same image.
--
-- Re-runnable: the INSERT uses gen_random_uuid() so repeat runs simply
-- add more rows. The UPDATE is idempotent (only touches NULL image_urls).

BEGIN;

-- 1. Backfill image_url on existing products that don't have one.
UPDATE public.products
SET image_url = 'https://picsum.photos/seed/' || sku || '/600/400',
    updated_at = now()
WHERE image_url IS NULL;

-- 2. Insert new demo products across the existing categories.
INSERT INTO public.products
  (id, name, sku, description, price, category_id, image_url, status, stock_quantity, reorder_threshold, supplier, created_at, updated_at)
VALUES
  -- Audio — SoundTech GmbH  (category 871584e7-…)
  (gen_random_uuid(), 'Soundbar 2.1 Channel',       'SKU-1960', 'Wireless subwoofer, HDMI eARC, 220W total',        189.00, '871584e7-4b7a-4efe-8975-b2b6e93c35fc', 'https://picsum.photos/seed/SKU-1960/600/400', 'active', 18, 5,  'SoundTech GmbH', now(), now()),
  (gen_random_uuid(), 'USB Condenser Microphone',   'SKU-1975', 'Cardioid, zero-latency monitor, boom arm ready',    89.00, '871584e7-4b7a-4efe-8975-b2b6e93c35fc', 'https://picsum.photos/seed/SKU-1975/600/400', 'active', 24, 8,  'SoundTech GmbH', now(), now()),
  (gen_random_uuid(), 'Desktop DAC / Headphone Amp','SKU-1980', 'ESS Sabre DAC, balanced out, 32-bit/384kHz',       249.00, '871584e7-4b7a-4efe-8975-b2b6e93c35fc', 'https://picsum.photos/seed/SKU-1980/600/400', 'active', 9,  3,  'SoundTech GmbH', now(), now()),
  (gen_random_uuid(), 'Wireless Headphones Plus',   'SKU-1995', 'ANC, 40h battery, LDAC, multipoint',               229.00, '871584e7-4b7a-4efe-8975-b2b6e93c35fc', 'https://picsum.photos/seed/SKU-1995/600/400', 'active', 14, 6,  'SoundTech GmbH', now(), now()),

  -- Monitors — DisplayPro Oy  (category a999b95f-…)
  (gen_random_uuid(), '32" 4K OLED',                'SKU-3255', 'OLED, 240Hz, 0.03ms, USB-C 90W',                   949.00, 'a999b95f-e751-4f02-b2f6-7cf5e4303bcf', 'https://picsum.photos/seed/SKU-3255/600/400', 'active', 6,  3,  'DisplayPro Oy',  now(), now()),
  (gen_random_uuid(), 'Portable 17" OLED',          'SKU-3270', 'Touch, USB-C, 1080p, folio stand',                 379.00, 'a999b95f-e751-4f02-b2f6-7cf5e4303bcf', 'https://picsum.photos/seed/SKU-3270/600/400', 'active', 12, 5,  'DisplayPro Oy',  now(), now()),
  (gen_random_uuid(), 'Dual Monitor Arm',           'SKU-3285', 'Gas spring, VESA 75/100, cable management',         89.00, 'a999b95f-e751-4f02-b2f6-7cf5e4303bcf', 'https://picsum.photos/seed/SKU-3285/600/400', 'active', 30, 10, 'DisplayPro Oy',  now(), now()),
  (gen_random_uuid(), '24" Office Monitor',         'SKU-3240', 'IPS, 75Hz, HDMI + DP, height adjustable',          149.00, 'a999b95f-e751-4f02-b2f6-7cf5e4303bcf', 'https://picsum.photos/seed/SKU-3240/600/400', 'active', 52, 15, 'DisplayPro Oy',  now(), now()),

  -- Keyboards — KeyCraft Ltd  (category 64ae0369-…)
  (gen_random_uuid(), 'TKL Wireless Keyboard',      'SKU-0460', 'Hot-swap, 2.4GHz + BT, PBT doubleshot',            139.00, '64ae0369-bad5-46f9-92b7-635d871e7a35', 'https://picsum.photos/seed/SKU-0460/600/400', 'active', 21, 8,  'KeyCraft Ltd',    now(), now()),
  (gen_random_uuid(), 'Low-Profile Mechanical',     'SKU-0475', 'Chocolate V2 switches, slim ABS keycaps',          129.00, '64ae0369-bad5-46f9-92b7-635d871e7a35', 'https://picsum.photos/seed/SKU-0475/600/400', 'active', 17, 8,  'KeyCraft Ltd',    now(), now()),
  (gen_random_uuid(), 'Bluetooth Numpad',           'SKU-0490', 'Bluetooth 5.1, rechargeable, slim',                 39.00, '64ae0369-bad5-46f9-92b7-635d871e7a35', 'https://picsum.photos/seed/SKU-0490/600/400', 'active', 44, 15, 'KeyCraft Ltd',    now(), now()),

  -- Chargers — ChargeCo  (category ce5185e7-…)
  (gen_random_uuid(), 'Car Charger 45W Dual',       'SKU-7850', '2x USB-C PD, compact aluminium body',               29.00, 'ce5185e7-1da5-4370-9316-aaaa03cc74c2', 'https://picsum.photos/seed/SKU-7850/600/400', 'active', 60, 20, 'ChargeCo',        now(), now()),
  (gen_random_uuid(), 'MagSafe 3-in-1 Stand',       'SKU-7865', 'Phone, watch, earbuds charging, fast wake',         99.00, 'ce5185e7-1da5-4370-9316-aaaa03cc74c2', 'https://picsum.photos/seed/SKU-7865/600/400', 'active', 22, 8,  'ChargeCo',        now(), now()),
  (gen_random_uuid(), 'Travel Adapter World',       'SKU-7880', 'UK/EU/US/AU, 2x USB-C + 1x USB-A',                  25.00, 'ce5185e7-1da5-4370-9316-aaaa03cc74c2', 'https://picsum.photos/seed/SKU-7880/600/400', 'active', 70, 25, 'ChargeCo',        now(), now()),

  -- Cables — CableWorks AB  (category 3a301c8d-…)
  (gen_random_uuid(), 'DisplayPort 2.1 Cable 2m',   'SKU-2890', 'UHBR20, 8K/120Hz, DSC',                             35.00, '3a301c8d-e34d-4f85-9be7-bd8ae74c22be', 'https://picsum.photos/seed/SKU-2890/600/400', 'active', 58, 20, 'CableWorks AB',   now(), now()),
  (gen_random_uuid(), 'USB-C 100W Cable 2m',        'SKU-2905', 'E-marker, 10Gbps data, braided',                    19.00, '3a301c8d-e34d-4f85-9be7-bd8ae74c22be', 'https://picsum.photos/seed/SKU-2905/600/400', 'active', 140, 40,'CableWorks AB',   now(), now()),
  (gen_random_uuid(), 'Ethernet Cat8 3m',           'SKU-2920', 'Shielded, 40Gbps, 2000MHz',                         15.00, '3a301c8d-e34d-4f85-9be7-bd8ae74c22be', 'https://picsum.photos/seed/SKU-2920/600/400', 'active', 95, 30, 'CableWorks AB',   now(), now()),
  (gen_random_uuid(), 'USB-C to Lightning 1m',      'SKU-2935', 'MFi certified, PD fast charge',                     22.00, '3a301c8d-e34d-4f85-9be7-bd8ae74c22be', 'https://picsum.photos/seed/SKU-2935/600/400', 'active', 110, 40,'CableWorks AB',   now(), now()),
  (gen_random_uuid(), '3.5mm AUX Cable 1m',         'SKU-2950', 'Oxygen-free copper, gold plated',                    8.00, '3a301c8d-e34d-4f85-9be7-bd8ae74c22be', 'https://picsum.photos/seed/SKU-2950/600/400', 'active', 180, 50,'CableWorks AB',   now(), now()),

  -- Peripherals — PeripheralPlus  (category 252de693-…)
  (gen_random_uuid(), 'Aluminium Laptop Stand',     'SKU-5570', 'Adjustable angle, heat dissipation, 11-17"',         45.00, '252de693-35b0-4cde-84bd-2d11dd31c6a3', 'https://picsum.photos/seed/SKU-5570/600/400', 'active', 48, 15, 'PeripheralPlus',  now(), now()),
  (gen_random_uuid(), '1080p Privacy Webcam',       'SKU-5585', 'Physical shutter, dual mic, autofocus',              55.00, '252de693-35b0-4cde-84bd-2d11dd31c6a3', 'https://picsum.photos/seed/SKU-5585/600/400', 'active', 33, 12, 'PeripheralPlus',  now(), now()),
  (gen_random_uuid(), 'Ring Light USB 10"',         'SKU-5600', '3 colour temps, dimmable, phone mount',              29.00, '252de693-35b0-4cde-84bd-2d11dd31c6a3', 'https://picsum.photos/seed/SKU-5600/600/400', 'active', 26, 10, 'PeripheralPlus',  now(), now()),
  (gen_random_uuid(), 'Silicone Wrist Rest',        'SKU-5615', 'Memory foam core, non-slip base, matte',             19.00, '252de693-35b0-4cde-84bd-2d11dd31c6a3', 'https://picsum.photos/seed/SKU-5615/600/400', 'active', 72, 25, 'PeripheralPlus',  now(), now()),
  (gen_random_uuid(), 'Cable Organiser Kit',        'SKU-5630', 'Under-desk tray + 20 clips + sleeves',               25.00, '252de693-35b0-4cde-84bd-2d11dd31c6a3', 'https://picsum.photos/seed/SKU-5630/600/400', 'active', 88, 30, 'PeripheralPlus',  now(), now()),
  (gen_random_uuid(), 'Standing Desk Anti-Fatigue Mat','SKU-5645','Contoured, 3/4" thick, non-slip',                  49.00, '252de693-35b0-4cde-84bd-2d11dd31c6a3', 'https://picsum.photos/seed/SKU-5645/600/400', 'active', 19, 8,  'PeripheralPlus',  now(), now());

COMMIT;

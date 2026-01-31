-- Minimal seed (optional): locations + example variant + example kit

insert into public.locations (name, type) values
('WH_MAIN', 'WAREHOUSE'),
('WIP_MAIN', 'WIP'),
('FG_MAIN', 'FINISHED_GOODS'),
('QUARANTINE', 'QUARANTINE')
on conflict (name) do nothing;

insert into public.items (item_id, name, item_type, is_stocked) values
('FG-BATSURE-GO-EU', 'BatSure GO EU', 'FINISHED_GOOD', true),
('KIT-BATSURE-GO-NL-EN', 'Kit BatSure GO NL/EN', 'PACKAGING', true)
on conflict (item_id) do nothing;

insert into public.product_variants (finished_item_id, variant_code, default_language_set)
values ('FG-BATSURE-GO-EU', 'BATSURE_GO_EU', 'NL-EN')
on conflict (variant_code) do nothing;

insert into public.variant_rules (variant_id, allowed_hw_revs, firmware_policy, packaging_policy)
select variant_id,
       '["HW1.2","HW1.3"]'::jsonb,
       '{"required_prefix":"TRACS SYSTEM 1.","require_build_hash":true}'::jsonb,
       '{"require_device_label":false}'::jsonb
from public.product_variants
where variant_code='BATSURE_GO_EU'
on conflict (variant_id) do update set
allowed_hw_revs=excluded.allowed_hw_revs,
firmware_policy=excluded.firmware_policy,
packaging_policy=excluded.packaging_policy,
updated_at=now();

insert into public.packaging_kits (kit_id, language_set, compatible_variant_codes)
values ('KIT-BATSURE-GO-NL-EN', 'NL-EN', array['BATSURE_GO_EU'])
on conflict (kit_id) do update set compatible_variant_codes=excluded.compatible_variant_codes;

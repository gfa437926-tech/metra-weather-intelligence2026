-- Deterministic replay bootstrap for the transitional public schema.
-- These role catalogue rows were present when this migration ran on the live
-- project but were not represented by an earlier migration. The later
-- greenfield rebuild replaces this temporary public schema with iam.roles.
INSERT INTO public.metra_role_catalogue
  (role_code, name_ar, name_en, is_requestable, is_active, display_order)
VALUES
  ('observer', 'راصد جوي', 'Weather observer', false, true, 100),
  ('station_head', 'رئيس محطة', 'Station head', false, true, 110),
  ('station_auditor', 'مدقق محطة', 'Station auditor', false, true, 120),
  ('chief_auditor', 'مدقق رئيسي', 'Chief auditor', false, true, 130),
  ('network_director', 'مدير شبكة', 'Network director', false, true, 140),
  ('system_admin', 'مدير النظام', 'System administrator', false, true, 150)
ON CONFLICT (role_code) DO NOTHING;

INSERT INTO public.metra_role_permissions (role_code, permission_code)
VALUES
    ('observer', 'observation.create'),
    ('observer', 'observation.edit_own_draft'),
    ('observer', 'observation.submit'),
    ('station_head', 'observation.review'),
    ('station_head', 'observation.return_for_correction'),
    ('station_auditor', 'observation.review'),
    ('station_auditor', 'observation.return_for_correction'),
    ('chief_auditor', 'observation.approve'),
    ('chief_auditor', 'observation.return_for_correction')
ON CONFLICT (role_code, permission_code) DO NOTHING;
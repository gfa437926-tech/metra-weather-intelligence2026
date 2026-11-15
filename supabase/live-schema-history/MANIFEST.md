# Recovered live migration archive manifest

- Source repository: `gfa437926-tech/metra2027`
- Source branch: `work/metra-all-workspaces-ui-2026-11-15`
- Captured from source commit: `2dd3f97acaf4b288517f1ca6a029ba737c7e0c18`
- Target repository: `gfa437926-tech/metra-weather-intelligence2026`
- Target branch: `feat/flutter-complete-interface-suite`
- Files: 86
- Exact Git blob SHA matches after copy: 86/86

Git blob SHA-1 values below are content identifiers. Every archive SQL file in this repository was verified to have the same Git blob SHA as its source counterpart in the source repository.

| Version | Filename | Git blob SHA-1 |
|---|---|---|
| `20261102154652` | `20261102154652_create_independent_station_catalogue.sql` | `4c084f65d77f1f3ce084b2cb768c3c1149965f08` |
| `20261102155101` | `20261102155101_index_station_catalogue_foreign_keys.sql` | `66f16bfba05495fa33ccbc5bcae3b37ff507a780` |
| `20261102155110` | `20261102155110_add_catalogue_integrity_triggers.sql` | `4f79ea3116bd5c0ba5c406ee7b775cc99bc63780` |
| `20261102155119` | `20261102155119_lock_station_catalogue_client_access.sql` | `6109947fd400df6fa7d81d3984f631b78578e0cd` |
| `20261102163034` | `20261102163034_enforce_station_temporal_integrity.sql` | `64a8d03ae8e4a472b7ae6d388c3db408c2968772` |
| `20261102165436` | `20261102165436_add_identity_membership_and_station_assignment.sql` | `f3dba2a8171887d5bc6ff04f6dcb2141d954d383` |
| `20261102165505` | `20261102165505_lock_identity_tables_and_index_foreign_keys.sql` | `4f3ea283f6adaa15b2bd7efb3f36f60a174ccad9` |
| `20261102165724` | `20261102165724_add_user_profile_and_align_account_lifecycle.sql` | `7da36f32431c8c6575cd994e49a275cbd58688b8` |
| `20261102165758` | `20261102165758_index_account_state_requester.sql` | `450f4f608f585b306b36f9527495c049ede043ea` |
| `20261102171030` | `20261102171030_add_station_source_provenance_and_demo_flags.sql` | `03f7dcfb1610715e693eb3ce3ae007129fca2fe9` |
| `20261102171037` | `20261102171037_support_unverified_station_operational_status.sql` | `b2defa69e2165ca43cb31dc6a7a86f502c843867` |
| `20261102172226` | `20261102172226_create_provenance_preserving_observation_store.sql` | `c59bddc5f09769eee28247876a879f2d03805850` |
| `20261102235913` | `20261102235913_create_registration_workflow_persistence.sql` | `4384ee3252fa3349b1b255dae8807455820f74a0` |
| `20261102235937` | `20261102235937_add_atomic_registration_submission_rpc.sql` | `81ddc6719862f68173c9bcf69d5da0763ba60d0b` |
| `20261103000038` | `20261103000038_harden_registration_idempotency_checks.sql` | `7c3822c6fffad2314b17339d8e3162fbe89f827a` |
| `20261103000332` | `20261103000332_provision_least_privilege_api_runtime_role.sql` | `bd3e30a978c36aba2b52b78df9fdecd0ab80ec5a` |
| `20261103000835` | `20261103000835_add_atomic_two_stage_registration_approval.sql` | `8b0b2cacf38e2f9ee9547ffa72829e5dd3649153` |
| `20261103000914` | `20261103000914_grant_runtime_registration_queue_read.sql` | `3d386362666f2cbc71910955a4fa3393f66caebb` |
| `20261103001045` | `20261103001045_harden_registration_approval_expected_state.sql` | `bf75253aeac4a109cdd08cf35e27247e6bab033c` |
| `20261103001209` | `20261103001209_grant_runtime_registration_audit_read.sql` | `4a689dfa748a6ac525e8062d0a593eebbfa42286` |
| `20261103001354` | `20261103001354_use_database_clock_for_registration_approval.sql` | `5e49ce19c4ff746f7c7a359f58397dba74002c6f` |
| `20261103001407` | `20261103001407_move_registration_submission_rpc_to_private_schema.sql` | `2a85bd9604bf41c3be433f101507c423d1642cd4` |
| `20261103001654` | `20261103001654_revoke_public_execute_from_approval_rpc.sql` | `52cbc178b0532ae1b3cccfaf94fcca76dd57865a` |
| `20261103001743` | `20261103001743_drop_obsolete_registration_approval_rpc.sql` | `fda76dcd652224897079fbb3a4d3d79acb7b462b` |
| `20261103001942` | `20261103001942_classify_existing_pending_registration_before_linked_account.sql` | `f6df6d1bd09b41c18a763892dcc38fd533d85940` |
| `20261103002006` | `20261103002006_fix_pending_registration_replay_classification.sql` | `54602740f7121c0e6fdc0d6d26860dc518c64c39` |
| `20261103010120` | `20261103010120_respect_scheduled_permission_revocation.sql` | `f177b8fa1cc31c0ba3556afd463895122b2112fb` |
| `20261103010435` | `20261103010435_add_registration_foreign_key_indexes.sql` | `111c811d3e798dce7e702d07a716232111506fa2` |
| `20261103025556` | `20261103025556_003_add_station_permission_check.sql` | `ee3332979af2615e1364a17fb385abf661e25901` |
| `20261103122944` | `20261103122944_grant_runtime_station_coordinate_read.sql` | `e9b43f4c2ea245ef38fc97a687622f9513b65378` |
| `20261103123005` | `20261103123005_link_membership_and_assignment_roles.sql` | `ae7a132e6ded4a06901988c444154a3f8e7015a0` |
| `20261103123127` | `20261103123127_index_role_catalogue_foreign_keys.sql` | `457dff7272f2b225a0c2258c983275db71981dfd` |
| `20261103162707` | `20261103162707_enforce_explicit_role_permission_allowlist.sql` | `83f557849ea6e62ce27ad1908d14d1ee6eca31e1` |
| `20261103162738` | `20261103162738_seed_conservative_observation_role_permissions.sql` | `08b1006addb73ca54ac0c907c5ca743bdcf6e50e` |
| `20261103164003` | `20261103164003_create_operational_observation_submission.sql` | `9f58d9bd496a44c216a4f10058d902871d537ea7` |
| `20261103164045` | `20261103164045_deny_client_access_to_operational_observations.sql` | `b63a8703f3af29ef3fda7c71cdf01f4262be785c` |
| `20261103164638` | `20261103164638_index_operational_observation_foreign_keys.sql` | `e17d6ccd2c53cddfe4e197798bf41939b676b5e7` |
| `20261103185454` | `20261103185454_20261103215400_observation_review_decision.sql` | `bc62268432c94d481e5e274625c5d59eea8ce528` |
| `20261103185955` | `20261103185955_harden_observation_decision_null_validation.sql` | `f7945fc95d7f3cd1a1d29a76ae38dfe29f2e58a2` |
| `20261104014631` | `20261104014631_registration_authenticated_entrypoint.sql` | `e31ed9e457e35f389fc6fd95fff38eb6b20c4c72` |
| `20261104014827` | `20261104014827_registration_server_timestamp_and_terms_guard.sql` | `94dfee1b9d436093db8df6a61b58147764a4b7f2` |
| `20261104015029` | `20261104015029_authenticated_registration_decision_entrypoint.sql` | `f811dda30c555745f638baec822b994c575f8662` |
| `20261104015823` | `20261104015823_restrict_registration_rpc_to_server_runtime.sql` | `0f37845948fb618ec425219088be194a3b1f1619` |
| `20261104021613` | `20261104021613_20261104110000_secure_station_catalogue_review.sql` | `21d2fe26a67d10334e5d33480bc9eac530a94550` |
| `20261104024652` | `20261104024652_harden_station_catalogue_review_null_validation.sql` | `df97829085493f285ba8c2ed5806f9d6c041918c` |
| `20261104030506` | `20261104030506_004_station_catalogue_review_permission.sql` | `a7fbeb93f4c0673233be12cf53c5d91c9bbf9e93` |
| `20261104031431` | `20261104031431_005_station_registration_review_permission.sql` | `3be0c8398881276549406043180b3c4d30874c2a` |
| `20261104031432` | `20261104031432_006_station_bound_registration_decision.sql` | `b148d7bf6d84560a6b08c1de785b3e3eca6c444d` |
| `20261104031434` | `20261104031434_007_system_registration_review_permission.sql` | `0152b500cb6025ceb9c4b7f72a91088a5d51b26b` |
| `20261104032044` | `20261104032044_008_registration_review_read_models.sql` | `ce94d661fddddcd27c3a7234f65a6b57c4754bb2` |
| `20261104032342` | `20261104032342_009_secure_registration_submission_and_status.sql` | `7e8f7e9da67a74718c0bc9f02ed3b740db87b5eb` |
| `20261104033138` | `20261104033138_010_station_user_directory_read_model.sql` | `b631185dcbb9dfc886ba39256e20c3694a90769b` |
| `20261104033144` | `20261104033144_011_station_user_directory_permission.sql` | `7eb401cebdf481ecaa0ea76db71c92917b4b22a6` |
| `20261104033839` | `20261104033839_012_station_assignment_workflow.sql` | `cfdf10a70656fda65a21b51664291bbc97f29efe` |
| `20261104034246` | `20261104034246_013_station_assignment_revocation.sql` | `0ede9379a8251d100c68997f3b648f2793170cea` |
| `20261104035035` | `20261104035035_014_station_audit_read_model.sql` | `5a1f62d1b47e2f37f73ad182897c57e0f71e9ff3` |
| `20261104042128` | `20261104042128_require_approved_active_station_for_registration.sql` | `bd9312772ec423db50730336cb8f85edda3b0ff3` |
| `20261104043402` | `20261104043402_015_authority_scoped_permission_rpc.sql` | `d181fd9188c02aaf15f59b99e3ee81769bda497f` |
| `20261104043806` | `20261104043806_016_authority_scoped_station_catalogue_review.sql` | `05ac8cf7993ac5b2f262b4aea54c92dc7eb79f6f` |
| `20261104044653` | `20261104044653_authority_scoped_system_registration_review.sql` | `3f42d3d31805f42937522975972890753954c264` |
| `20261104045003` | `20261104045003_harden_authority_registration_decision_nulls.sql` | `059ef3990d14b169b7b877bcabc362baa81adfb2` |
| `20261104045241` | `20261104045241_restore_registration_station_binding.sql` | `23bcb95f4a09c3e3aa0459dec53fe0d37b9a3589` |
| `20261104045649` | `20261104045649_authority_membership_and_permission_grant_lifecycle.sql` | `f7a55d0055ed77fdb3790b1004449cfaf1478592` |
| `20261104045710` | `20261104045710_authority_permission_grant_lifecycle.sql` | `d465c25795714e384bc810fe3b80ac692074d904` |
| `20261104045739` | `20261104045739_harden_authority_access_revocation_and_audit_index.sql` | `853acd985b0e036f178b5b16f63c1ec226bed286` |
| `20261104050159` | `20261104050159_bind_authority_access_decisions_to_route_scope.sql` | `365e25af104ca2119c2e731826228fa65f52b60b` |
| `20261104050331` | `20261104050331_revoke_direct_service_role_writes_to_authority_audit.sql` | `2ce0515a977ae642c4b0fca4f729d365f55fbac4` |
| `20261104050415` | `20261104050415_require_active_subject_for_authority_approval.sql` | `816cadc847915360c5c0d388e81ee7346cf3e907` |
| `20261104050644` | `20261104050644_add_authority_access_catalogue_read_models.sql` | `8b4aa7a146574ba870509193d5581bf9b0f29019` |
| `20261104050826` | `20261104050826_add_authority_catalogue_read_model.sql` | `951a0deaa0d170f2449569c052dbc34e449f1ce0` |
| `20261104051003` | `20261104051003_extend_authority_access_queue_with_active_directory.sql` | `68f352dd8ddcac2a8a98d9ac41c4a1511d78b65c` |
| `20261104052223` | `20261104052223_029_include_scheduled_access_in_revocation_directory.sql` | `9bf41a12a99642fa1b78eeb11e70a3d56ff4d993` |
| `20261104053507` | `20261104053507_create_legacy_user_migration_staging.sql` | `e0d9ffe6dd4a8f8dc1f25ef562d52d662d15bf8e` |
| `20261104055635` | `20261104055635_allow_missing_legacy_user_role.sql` | `2ec828493625fc080d43510057cbd104d7a8c8a4` |
| `20261104055748` | `20261104055748_secure_legacy_user_staging.sql` | `c5e2808d1c2e675c84fcccfc27498eaceb362790` |
| `20261109065153` | `20261109065153_harden_observation_decision_sod_and_audit.sql` | `5a080ffb35cc4efe4c2188d1e84da9b428726d00` |
| `20261109065219` | `20261109065219_create_equipment_faults_station_scoped.sql` | `019214a9b6a7f7aabe5559bba27043edb97f029b` |
| `20261109065221` | `20261109065221_create_support_incidents_station_scoped.sql` | `42368ca33fd437655eac6f80ede732cf689e4f2b` |
| `20261109065226` | `20261109065226_harden_ops_rls_and_assignee_checks.sql` | `da8404f73e7b73e09d5104d5057258b78497a4dc` |
| `20261114184050` | `20261114184050_harden_ops_audit_functions_and_index_foreign_keys.sql` | `2d328f4a7df06b7c82dbb082adc7f46ce85bf7dd` |
| `20261114184511` | `20261114184511_metra_greenfield_application_schema_rebuild.sql` | `8e88d104d0ac875af6ff0730dec9339dd06327cd` |
| `20261114184541` | `20261114184541_metra_greenfield_integrity_and_foreign_key_index_hardening.sql` | `9238215a5aca4dc4265e20bb255304c741e06859` |
| `20261114184651` | `20261114184651_metra_scope_integrity_and_access_review.sql` | `75af54205583f6e11a914829f96af1cc705e477e` |
| `20261114203913` | `20261114203913_metra_registration_review_permissions_and_father_name.sql` | `8cd379d66adcaeecf6984f6bf7197d6a2c6092ff` |
| `20261114204909` | `20261114204909_metra_api_runtime_privileges.sql` | `6dfbe4b2050ebccb27e78a8fbc5fab53d62f0cd5` |
| `20261114204951` | `20261114204951_metra_api_runtime_privileges.sql` | `25ea50348a5cf706805d6d663b07ce151ca886ae` |
import { supabaseAdmin } from "./supabase.js";

export type GateResult = {
  allowed: boolean;
  blockers: string[];
  expected: Record<string, unknown>;
};

export async function canPack(sn: string): Promise<GateResult> {
  const blockers: string[] = [];
  const expected: Record<string, unknown> = {};

  const { data: unit, error: unitErr } = await supabaseAdmin
    .from("serialized_units")
    .select("sn,status,variant_id,serial_class,hw_rev_detected,fw_version_detected,fw_build_hash")
    .eq("sn", sn)
    .maybeSingle();

  if (unitErr || !unit) return { allowed: false, blockers: ["UNIT_NOT_FOUND"], expected };

  if (!unit.variant_id) blockers.push("UNIT_NOT_ASSIGNED");

  let variant: any = null;
  let rules: any = null;

  if (unit.variant_id) {
    const { data: v } = await supabaseAdmin
      .from("product_variants")
      .select("variant_id,variant_code,default_language_set,finished_item_id")
      .eq("variant_id", unit.variant_id)
      .maybeSingle();
    variant = v;
    if (!variant) blockers.push("VARIANT_NOT_FOUND");

    const { data: r } = await supabaseAdmin
      .from("variant_rules")
      .select("allowed_hw_revs,firmware_policy,packaging_policy,manual_policy")
      .eq("variant_id", unit.variant_id)
      .maybeSingle();
    rules = r ?? null;
  }

  const { data: lastTest } = await supabaseAdmin
    .from("test_runs")
    .select("result,created_at")
    .eq("sn", sn)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!lastTest) blockers.push("NO_TEST_RUN");
  else if (String(lastTest.result).toUpperCase() !== "PASS") blockers.push("TEST_NOT_PASS");

  const allowedHw: string[] = (rules?.allowed_hw_revs ?? []) as any;
  if (allowedHw.length > 0) {
    if (!unit.hw_rev_detected) blockers.push("HW_REV_UNKNOWN");
    else if (!allowedHw.includes(unit.hw_rev_detected)) blockers.push("HW_REV_NOT_ALLOWED");
  }

  const fwPolicy = (rules?.firmware_policy ?? {}) as any;
  expected["firmware_policy"] = fwPolicy;
  if (fwPolicy?.required_prefix) {
    if (!unit.fw_version_detected?.startsWith(fwPolicy.required_prefix)) blockers.push("FW_VERSION_POLICY_FAIL");
  }
  if (fwPolicy?.require_build_hash === true && !unit.fw_build_hash) blockers.push("FW_BUILD_HASH_MISSING");

  const { data: kitEvent } = await supabaseAdmin
    .from("unit_events")
    .select("payload,created_at")
    .eq("sn", sn)
    .eq("event_type", "PACK_KIT_SCANNED")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const kitId = (kitEvent?.payload as any)?.kit_id as string | undefined;
  if (!kitId) blockers.push("PACK_KIT_NOT_SCANNED");
  else {
    const { data: kit } = await supabaseAdmin
      .from("packaging_kits")
      .select("kit_id,compatible_variant_codes,language_set,active,insert_versions")
      .eq("kit_id", kitId)
      .maybeSingle();

    if (!kit || kit.active !== true) blockers.push("PACK_KIT_INVALID");
    else if (variant && !kit.compatible_variant_codes.includes(variant.variant_code)) blockers.push("PACK_KIT_WRONG_VARIANT");
    else expected["packaging_kit"] = kit;
  }

  const requireLabel = (rules?.packaging_policy as any)?.require_device_label === true;
  if (requireLabel) {
    const { data: jobs } = await supabaseAdmin.from("print_jobs").select("job_type,status").eq("sn", sn);
    const deviceLabelDone = (jobs ?? []).some((j: any) => j.job_type === "device_label" && j.status === "DONE");
    if (!deviceLabelDone) blockers.push("DEVICE_LABEL_NOT_PRINTED");
  }

  if (variant) expected["variant"] = variant;

  return { allowed: blockers.length === 0, blockers, expected };
}

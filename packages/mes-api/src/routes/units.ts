import type { FastifyInstance } from "fastify";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabase.js";
import { logUnitEvent } from "../services/events.js";
import { canPack } from "../services/gating.js";
import {
  zAssignVariantRequest,
  zFlashRequest,
  zAssembleRequest,
  zScanKitRequest,
  zMoveToStockRequest
} from "@flexavolt/shared";

export async function unitsRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAuth);

  // Create generic unit (YYMM-GN-00001)
  app.post("/create-generic", async (req, reply) => {
    const body = (req.body as any) ?? {};
    const p_prod_order_id = body.prod_order_id ?? null;

    const { data, error } = await supabaseAdmin.rpc("create_generic_unit", { p_prod_order_id });
    if (error) return reply.code(400).send({ error: error.message });

    return reply.send({ ok: true, sn: data as string });
  });

  // Assign unit to final variant (Pattern A)
  app.post("/:sn/assign-variant", async (req, reply) => {
    const { sn } = req.params as any;
    const parsed = zAssignVariantRequest.safeParse(req.body ?? {});
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.flatten() });

    const user = (req as any).user;
    const { variant_id, assigned_product_code, station_id } = parsed.data;

    const { error } = await supabaseAdmin.rpc("assign_unit_variant", {
      p_sn: sn,
      p_variant_id: variant_id,
      p_assigned_product_code: assigned_product_code,
      p_assigned_by: user.id
    });

    if (error) return reply.code(400).send({ error: error.message });

    await logUnitEvent({
      sn,
      event_type: "UNIT_ASSIGNED_TO_VARIANT",
      station_id: station_id ?? null,
      operator_id: user.id,
      payload: { variant_id, assigned_product_code }
    });

    return reply.send({ ok: true });
  });

  // Flash/provision result
  app.post("/:sn/flash", async (req, reply) => {
    const { sn } = req.params as any;
    const parsed = zFlashRequest.safeParse(req.body ?? {});
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.flatten() });

    const user = (req as any).user;
    const body = parsed.data;

    const { error } = await supabaseAdmin.from("serialized_units").update({
      hw_rev_detected: body.hw_rev_detected ?? null,
      fw_version_detected: body.fw_version_detected ?? null,
      fw_build_hash: body.fw_build_hash ?? null,
      status: "FLASHED",
      updated_at: new Date().toISOString()
    }).eq("sn", sn);

    if (error) return reply.code(400).send({ error: error.message });

    await logUnitEvent({
      sn,
      event_type: "FLASH_OK",
      station_id: body.station_id ?? null,
      operator_id: user.id,
      payload: body as any
    });

    return reply.send({ ok: true });
  });

  // Assembly done
  app.post("/:sn/assemble", async (req, reply) => {
    const { sn } = req.params as any;
    const parsed = zAssembleRequest.safeParse(req.body ?? {});
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.flatten() });

    const user = (req as any).user;
    const body = parsed.data;

    const { error } = await supabaseAdmin.from("serialized_units").update({
      status: "ASSEMBLED",
      updated_at: new Date().toISOString()
    }).eq("sn", sn);

    if (error) return reply.code(400).send({ error: error.message });

    await logUnitEvent({
      sn,
      event_type: "ASSEMBLY_DONE",
      station_id: body.station_id ?? null,
      operator_id: user.id,
      payload: body as any
    });

    return reply.send({ ok: true });
  });

  // Scan packaging kit
  app.post("/:sn/pack/scan-kit", async (req, reply) => {
    const { sn } = req.params as any;
    const parsed = zScanKitRequest.safeParse(req.body ?? {});
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.flatten() });

    const user = (req as any).user;
    const { kit_id, station_id } = parsed.data;

    await logUnitEvent({
      sn,
      event_type: "PACK_KIT_SCANNED",
      station_id: station_id ?? null,
      operator_id: user.id,
      payload: { kit_id }
    });

    return reply.send({ ok: true });
  });

  // Finalize pack (Pack Gate)
  app.post("/:sn/pack/finalize", async (req, reply) => {
    const { sn } = req.params as any;
    const body = (req.body as any) ?? {};
    const user = (req as any).user;

    const gate = await canPack(sn);

    await logUnitEvent({
      sn,
      event_type: "PACK_FINALIZED",
      station_id: body.station_id ?? null,
      operator_id: user.id,
      payload: { allowed: gate.allowed, blockers: gate.blockers }
    });

    if (!gate.allowed) return reply.code(409).send(gate);

    const { error } = await supabaseAdmin.from("serialized_units").update({
      status: "PACKED",
      updated_at: new Date().toISOString()
    }).eq("sn", sn);

    if (error) return reply.code(400).send({ error: error.message });

    return reply.send({ ok: true, gate });
  });

  // Move to finished goods stock
  app.post("/:sn/move-to-stock", async (req, reply) => {
    const { sn } = req.params as any;
    const parsed = zMoveToStockRequest.safeParse(req.body ?? {});
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.flatten() });

    const user = (req as any).user;
    const { finished_item_id, location_id, station_id } = parsed.data;

    const { error: invErr } = await supabaseAdmin.from("inventory_ledger").insert({
      item_id: finished_item_id,
      location_id,
      movement_type: "PRODUCE_FINISHED",
      qty: 1,
      ref_type: "UNIT",
      ref_id: sn,
      created_by: user.id
    });
    if (invErr) return reply.code(400).send({ error: invErr.message });

    const { error: unitErr } = await supabaseAdmin.from("serialized_units").update({
      status: "IN_FINISHED_STOCK",
      updated_at: new Date().toISOString()
    }).eq("sn", sn);
    if (unitErr) return reply.code(400).send({ error: unitErr.message });

    await logUnitEvent({
      sn,
      event_type: "MOVE_TO_STOCK",
      station_id: station_id ?? null,
      operator_id: user.id,
      payload: { finished_item_id, location_id }
    });

    return reply.send({ ok: true });
  });

  // Get unit details
  app.get("/:sn", async (req, reply) => {
    const { sn } = req.params as any;

    const { data: unit, error: unitErr } = await supabaseAdmin
      .from("serialized_units")
      .select("*")
      .eq("sn", sn)
      .maybeSingle();
    if (unitErr) return reply.code(400).send({ error: unitErr.message });

    const { data: lastTest } = await supabaseAdmin
      .from("test_runs")
      .select("*")
      .eq("sn", sn)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const gate = await canPack(sn);

    return reply.send({ unit, lastTest, gate });
  });
}

import type { FastifyInstance } from "fastify";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabase.js";
import { logUnitEvent } from "../services/events.js";

export async function inventoryRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAuth);

  app.post("/move", async (req, reply) => {
    const user = (req as any).user;
    const body = (req.body as any) ?? {};

    const required = ["item_id", "location_id", "movement_type", "qty"];
    for (const k of required) {
      if (body[k] === undefined || body[k] === null) return reply.code(400).send({ error: `Missing ${k}` });
    }

    const { error } = await supabaseAdmin.from("inventory_ledger").insert({
      item_id: body.item_id,
      location_id: body.location_id,
      movement_type: body.movement_type,
      qty: body.qty,
      ref_type: body.ref_type ?? null,
      ref_id: body.ref_id ?? null,
      unit_cost: body.unit_cost ?? null,
      created_by: user.id
    });
    if (error) return reply.code(400).send({ error: error.message });

    if (body.ref_type === "UNIT" && body.ref_id) {
      await logUnitEvent({
        sn: body.ref_id,
        event_type: "INVENTORY_MOVE",
        station_id: body.station_id ?? null,
        operator_id: user.id,
        payload: body
      });
    }

    return reply.send({ ok: true });
  });
}

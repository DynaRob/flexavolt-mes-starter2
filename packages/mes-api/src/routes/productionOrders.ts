import type { FastifyInstance } from "fastify";
import { requireAuth } from "../middleware/requireAuth.js";
import { supabaseAdmin } from "../services/supabase.js";

export async function productionOrdersRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAuth);

  app.post("/", async (req, reply) => {
    const body = (req.body as any) ?? {};
    if (!body.variant_id || !body.qty_planned) return reply.code(400).send({ error: "variant_id and qty_planned required" });

    const { data, error } = await supabaseAdmin.from("production_orders").insert({
      variant_id: body.variant_id,
      qty_planned: body.qty_planned,
      status: "PLANNED",
      due_date: body.due_date ?? null
    }).select("*").single();

    if (error) return reply.code(400).send({ error: error.message });
    return reply.send({ ok: true, production_order: data });
  });

  app.get("/:id", async (req, reply) => {
    const { id } = req.params as any;
    const { data, error } = await supabaseAdmin.from("production_orders").select("*").eq("prod_order_id", id).maybeSingle();
    if (error) return reply.code(400).send({ error: error.message });
    return reply.send({ production_order: data });
  });
}

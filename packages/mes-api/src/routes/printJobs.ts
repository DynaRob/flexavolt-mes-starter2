import type { FastifyInstance } from "fastify";
import { supabaseAdmin } from "../services/supabase.js";
import { config } from "../config.js";
import { logUnitEvent } from "../services/events.js";
import { requireAuth } from "../middleware/requireAuth.js";

export async function printJobsRoutes(app: FastifyInstance) {
  // Create print job (operator auth)
  app.post("/", { preHandler: requireAuth }, async (req, reply) => {
    const user = (req as any).user;
    const body = (req.body as any) ?? {};
    if (!body.job_type) return reply.code(400).send({ error: "job_type required" });

    const { data, error } = await supabaseAdmin.from("print_jobs").insert({
      job_type: body.job_type,
      sn: body.sn ?? null,
      payload: body.payload ?? {},
      status: "QUEUED",
      updated_at: new Date().toISOString()
    }).select("*").single();

    if (error) return reply.code(400).send({ error: error.message });

    await logUnitEvent({
      sn: body.sn ?? null,
      event_type: "PRINT_JOB_CREATED",
      station_id: body.station_id ?? null,
      operator_id: user.id,
      payload: { print_job_id: data.print_job_id, job_type: body.job_type }
    });

    return reply.send({ ok: true, job: data });
  });

  // Agent claims next job atomically using RPC: claim_next_print_job(agent_id)
  app.get("/next", async (req, reply) => {
    const token = (req.headers["x-agent-token"] as string) ?? "";
    if (config.printAgentToken && token !== config.printAgentToken) {
      return reply.code(401).send({ error: "Invalid agent token" });
    }

    const agent_id = String((req.query as any).agent_id ?? "").trim();
    if (!agent_id) return reply.code(400).send({ error: "agent_id required" });

    const { data, error } = await supabaseAdmin.rpc("claim_next_print_job", { p_agent_id: agent_id });
    if (error) return reply.code(400).send({ error: error.message });

    // data is either null or a print_jobs row
    return reply.send({ job: data });
  });

  app.post("/:id/done", async (req, reply) => {
    const token = (req.headers["x-agent-token"] as string) ?? "";
    if (config.printAgentToken && token !== config.printAgentToken) {
      return reply.code(401).send({ error: "Invalid agent token" });
    }
    const { id } = req.params as any;
    const body = (req.body as any) ?? {};

    await supabaseAdmin.from("print_jobs").update({
      status: "DONE",
      updated_at: new Date().toISOString()
    }).eq("print_job_id", id);

    if (body.sn) {
      await logUnitEvent({
        sn: body.sn,
        event_type: "PRINT_JOB_DONE",
        station_id: body.station_id ?? null,
        payload: { print_job_id: id }
      });
    }

    return reply.send({ ok: true });
  });

  app.post("/:id/fail", async (req, reply) => {
    const token = (req.headers["x-agent-token"] as string) ?? "";
    if (config.printAgentToken && token !== config.printAgentToken) {
      return reply.code(401).send({ error: "Invalid agent token" });
    }
    const { id } = req.params as any;
    const body = (req.body as any) ?? {};

    await supabaseAdmin.from("print_jobs").update({
      status: "FAIL",
      error: String(body.error ?? "unknown"),
      updated_at: new Date().toISOString()
    }).eq("print_job_id", id);

    if (body.sn) {
      await logUnitEvent({
        sn: body.sn,
        event_type: "PRINT_JOB_FAIL",
        station_id: body.station_id ?? null,
        payload: { print_job_id: id, error: body.error ?? "unknown" }
      });
    }

    return reply.send({ ok: true });
  });
}

import type { FastifyInstance } from "fastify";
import { supabaseAdmin } from "../services/supabase.js";
import { config } from "../config.js";
import { zFixtureTestResult } from "@flexavolt/shared/src/zod.js";
import { logUnitEvent } from "../services/events.js";

export async function testResultsRoutes(app: FastifyInstance) {
  app.post("/", async (req, reply) => {
    const token = (req.headers["x-fixture-token"] as string) ?? "";
    if (config.fixtureToken && token !== config.fixtureToken) {
      return reply.code(401).send({ error: "Invalid fixture token" });
    }

    const parsed = zFixtureTestResult.safeParse(req.body ?? {});
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.flatten() });

    const body = parsed.data;

    const { error: insErr } = await supabaseAdmin.from("test_runs").insert({
      sn: body.sn,
      fixture_id: body.fixture_id,
      result: body.result,
      metrics: body.metrics ?? {},
      fw_readback: body.fw_readback ?? {}
    });
    if (insErr) return reply.code(400).send({ error: insErr.message });

    await logUnitEvent({
      sn: body.sn,
      event_type: body.result === "PASS" ? "TEST_PASS" : "TEST_FAIL",
      station_id: body.station_id ?? `FIXTURE:${body.fixture_id}`,
      payload: { metrics: body.metrics ?? {}, fw_readback: body.fw_readback ?? {} }
    });

    if (body.result === "PASS") {
      await supabaseAdmin.from("serialized_units").update({
        status: "TEST_PASS",
        updated_at: new Date().toISOString(),
        hw_rev_detected: body.hw_rev_detected ?? undefined,
        fw_version_detected: body.fw_version_detected ?? undefined,
        fw_build_hash: body.fw_build_hash ?? undefined
      }).eq("sn", body.sn);
    }

    return reply.send({ ok: true });
  });
}

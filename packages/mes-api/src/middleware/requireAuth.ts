import type { FastifyRequest, FastifyReply } from "fastify";
import { verifySupabaseBearerToken } from "../services/auth.js";

export async function requireAuth(req: FastifyRequest, reply: FastifyReply) {
  try {
    const user = await verifySupabaseBearerToken(req.headers.authorization);
    (req as any).user = user;
  } catch (e: any) {
    return reply.code(401).send({ error: e?.message ?? "Unauthorized" });
  }
}

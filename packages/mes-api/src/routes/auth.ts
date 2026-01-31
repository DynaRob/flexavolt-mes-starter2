import type { FastifyInstance } from "fastify";
import { requireAuth } from "../middleware/requireAuth.js";

export async function authRoutes(app: FastifyInstance) {
  app.get("/auth/me", { preHandler: requireAuth }, async (req) => {
    const user = (req as any).user;
    return { id: user.id, email: user.email, role: "operator" };
  });
}

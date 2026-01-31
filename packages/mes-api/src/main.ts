import Fastify from "fastify";
import cors from "@fastify/cors";
import { assertConfig, config } from "./config.js";

import { healthRoutes } from "./routes/health.js";
import { authRoutes } from "./routes/auth.js";
import { unitsRoutes } from "./routes/units.js";
import { testResultsRoutes } from "./routes/testResults.js";
import { inventoryRoutes } from "./routes/inventory.js";
import { printJobsRoutes } from "./routes/printJobs.js";
import { productionOrdersRoutes } from "./routes/productionOrders.js";

async function start() {
  assertConfig();

  const app = Fastify({
    logger: {
      transport: config.nodeEnv === "development" ? { target: "pino-pretty" } : undefined
    } as any
  });

  await app.register(cors, { origin: true });

  await app.register(healthRoutes);
  await app.register(authRoutes);
  await app.register(productionOrdersRoutes, { prefix: "/production-orders" });
  await app.register(unitsRoutes, { prefix: "/units" });
  await app.register(testResultsRoutes, { prefix: "/test-results" });
  await app.register(inventoryRoutes, { prefix: "/inventory" });
  await app.register(printJobsRoutes, { prefix: "/print-jobs" });

  await app.listen({ port: config.port, host: "0.0.0.0" });
}

start().catch((e) => {
  console.error(e);
  process.exit(1);
});

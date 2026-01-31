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
  try {
    console.log("Starting application...");
    console.log("NODE_ENV:", process.env.NODE_ENV);
    console.log("PORT:", process.env.PORT);
    console.log("BASE_URL:", process.env.BASE_URL || "not set");
    console.log("SUPABASE_URL:", process.env.SUPABASE_URL ? "set" : "NOT SET");
    console.log("SUPABASE_ANON_KEY:", process.env.SUPABASE_ANON_KEY ? "set" : "NOT SET");
    console.log("SUPABASE_SERVICE_ROLE_KEY:", process.env.SUPABASE_SERVICE_ROLE_KEY ? "set" : "NOT SET");
    
    assertConfig();
    console.log("Configuration validated successfully");

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
    console.log(`Server listening on port ${config.port}`);
  } catch (error) {
    console.error("Failed to start application:", error);
    if (error instanceof Error) {
      console.error("Error message:", error.message);
      console.error("Error stack:", error.stack);
    }
    process.exit(1);
  }
}

start().catch((e) => {
  console.error("Unhandled error:", e);
  process.exit(1);
});

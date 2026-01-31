export const config = {
  nodeEnv: process.env.NODE_ENV ?? "development",
  port: Number(process.env.PORT ?? 8080),
  baseUrl: process.env.BASE_URL ?? "http://localhost:8080",
  supabaseUrl: process.env.SUPABASE_URL ?? "",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY ?? "",
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? "",
  fixtureToken: process.env.FIXTURE_TOKEN ?? "",
  printAgentToken: process.env.PRINT_AGENT_TOKEN ?? ""
};

export function assertConfig() {
  const missing: string[] = [];
  if (!config.supabaseUrl) missing.push("SUPABASE_URL");
  if (!config.supabaseAnonKey) missing.push("SUPABASE_ANON_KEY");
  if (!config.supabaseServiceRoleKey) missing.push("SUPABASE_SERVICE_ROLE_KEY");
  if (missing.length) throw new Error("Missing env vars: " + missing.join(", "));
}

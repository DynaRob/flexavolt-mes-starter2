import { supabaseAnon } from "./supabase.js";

export async function verifySupabaseBearerToken(authorizationHeader?: string) {
  const auth = authorizationHeader ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!token) throw new Error("Missing bearer token");

  const { data, error } = await supabaseAnon.auth.getUser(token);
  if (error || !data?.user) throw new Error("Invalid token");
  return data.user;
}

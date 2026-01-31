import { supabaseAdmin } from "./supabase.js";

export async function logUnitEvent(args: {
  sn: string | null;
  event_type: string;
  station_id?: string | null;
  operator_id?: string | null;
  payload?: Record<string, unknown>;
}) {
  const { error } = await supabaseAdmin.from("unit_events").insert({
    sn: args.sn,
    event_type: args.event_type,
    station_id: args.station_id ?? null,
    operator_id: args.operator_id ?? null,
    payload: args.payload ?? {}
  });
  if (error) throw new Error("Failed to log unit event: " + error.message);
}

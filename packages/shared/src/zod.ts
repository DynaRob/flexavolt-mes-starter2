import { z } from "zod";

export const zAssignVariantRequest = z.object({
  variant_id: z.string().uuid(),
  assigned_product_code: z.string().min(2).max(8),
  station_id: z.string().optional()
});

export const zFlashRequest = z.object({
  station_id: z.string().optional(),
  hw_rev_detected: z.string().optional(),
  fw_version_detected: z.string().optional(),
  fw_build_hash: z.string().optional()
});

export const zAssembleRequest = z.object({
  station_id: z.string().optional(),
  notes: z.string().optional()
});

export const zScanKitRequest = z.object({
  station_id: z.string().optional(),
  kit_id: z.string().min(3).max(80)
});

export const zMoveToStockRequest = z.object({
  station_id: z.string().optional(),
  finished_item_id: z.string().min(3).max(80),
  location_id: z.string().uuid()
});

export const zFixtureTestResult = z.object({
  sn: z.string().min(6).max(64),
  fixture_id: z.string().min(2).max(64),
  result: z.enum(["PASS", "FAIL"]),
  metrics: z.record(z.any()).optional(),
  fw_readback: z.record(z.any()).optional(),
  hw_rev_detected: z.string().optional(),
  fw_version_detected: z.string().optional(),
  fw_build_hash: z.string().optional(),
  station_id: z.string().optional()
});

export type GateResult = {
  allowed: boolean;
  blockers: string[];
  expected?: Record<string, unknown>;
};

export type AssignVariantRequest = {
  variant_id: string;
  assigned_product_code: string; // e.g. BS/PT/BT
  station_id?: string;
};

export type FlashRequest = {
  station_id?: string;
  hw_rev_detected?: string;
  fw_version_detected?: string;
  fw_build_hash?: string;
};

export type AssembleRequest = {
  station_id?: string;
  notes?: string;
};

export type ScanKitRequest = {
  station_id?: string;
  kit_id: string;
};

export type MoveToStockRequest = {
  station_id?: string;
  finished_item_id: string;
  location_id: string;
};

export type FixtureTestResult = {
  sn: string;
  fixture_id: string;
  result: "PASS" | "FAIL";
  metrics?: Record<string, unknown>;
  fw_readback?: Record<string, unknown>;
  hw_rev_detected?: string;
  fw_version_detected?: string;
  fw_build_hash?: string;
  station_id?: string;
};

import fetch from "node-fetch";

const BASE_URL = process.env.BASE_URL || "http://mes-api:8080";
const AGENT_ID = process.env.PRINT_AGENT_ID || "AGENT01";
const TOKEN = process.env.PRINT_AGENT_TOKEN || "";

async function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

// MVP print stub. Replace with actual printer output.
// Expect payload.zpl or payload.raw.
async function print(payload: any) {
  console.log("PRINT JOB PAYLOAD:", JSON.stringify(payload, null, 2));
  const zpl = payload?.zpl;
  if (zpl) console.log("=== ZPL START ===\n" + zpl + "\n=== ZPL END ===");
}

async function main() {
  console.log(`Print Agent starting. BASE_URL=${BASE_URL} AGENT_ID=${AGENT_ID}`);
  while (true) {
    try {
      const res = await fetch(`${BASE_URL}/print-jobs/next?agent_id=${encodeURIComponent(AGENT_ID)}`, {
        headers: { "x-agent-token": TOKEN }
      });
      const data = await res.json() as { job?: any };
      const job = data.job;

      if (!job) {
        await sleep(800);
        continue;
      }

      await print(job.payload);

      await fetch(`${BASE_URL}/print-jobs/${job.print_job_id}/done`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-agent-token": TOKEN },
        body: JSON.stringify({ sn: job.sn })
      });
    } catch (e: any) {
      console.error("Print Agent error:", e?.message ?? e);
      await sleep(1200);
    }
  }
}

main();

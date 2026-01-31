-- FlexaVolt MES Starter - Functions v1
-- Pattern A: GN serial immutable + later assignment to final variant.
-- Includes atomic print-job claim function.

create or replace function public.create_generic_unit(
  p_prod_order_id uuid default null
)
returns text
language plpgsql
as $$
declare
  v_yymm text := to_char(now(), 'YYMM');
  v_seq int;
  v_sn text;
  v_product_code text := 'GN';
begin
  insert into public.serial_sequences (yymm, product_code, next_seq)
  values (v_yymm, v_product_code, 1)
  on conflict (yymm, product_code) do nothing;

  update public.serial_sequences
     set next_seq = next_seq + 1
   where yymm = v_yymm
     and product_code = v_product_code
  returning next_seq - 1 into v_seq;

  v_sn := v_yymm || '-' || v_product_code || '-' || lpad(v_seq::text, 5, '0');

  insert into public.serialized_units (
    sn, prod_order_id, variant_id, product_code, status, production_stage, serial_class
  ) values (
    v_sn, p_prod_order_id, null, v_product_code, 'CREATED', 'CREATED', 'GENERIC'
  );

  insert into public.unit_events (sn, event_type, payload)
  values (
    v_sn, 'UNIT_CREATED',
    jsonb_build_object('yymm', v_yymm, 'seq', v_seq, 'product_code', v_product_code, 'prod_order_id', p_prod_order_id)
  );

  return v_sn;
end;
$$;

create or replace function public.assign_unit_variant(
  p_sn text,
  p_variant_id uuid,
  p_assigned_product_code text,
  p_assigned_by uuid
)
returns void
language plpgsql
as $$
begin
  if exists (
    select 1 from public.serialized_units
    where sn = p_sn and status in ('PACKED','IN_FINISHED_STOCK','SCRAPPED')
  ) then
    raise exception 'UNIT_NOT_ASSIGNABLE_IN_CURRENT_STATUS';
  end if;

  update public.serialized_units
     set assigned_variant_id = p_variant_id,
         assigned_product_code = p_assigned_product_code,
         assigned_at = now(),
         assigned_by = p_assigned_by,
         serial_class = 'FINAL',
         variant_id = p_variant_id,
         updated_at = now()
   where sn = p_sn;

  if not found then
    raise exception 'UNIT_NOT_FOUND';
  end if;

  insert into public.unit_events (sn, event_type, payload, operator_id)
  values (
    p_sn,
    'UNIT_ASSIGNED_TO_VARIANT',
    jsonb_build_object('assigned_variant_id', p_variant_id, 'assigned_product_code', p_assigned_product_code),
    p_assigned_by
  );
end;
$$;

-- Atomic claim of next queued print job (prevents double-claim under concurrency)
-- Returns a full row from public.print_jobs or NULL.
create or replace function public.claim_next_print_job(p_agent_id text)
returns public.print_jobs
language plpgsql
as $$
declare
  v_job public.print_jobs;
begin
  select *
    into v_job
    from public.print_jobs
   where status = 'QUEUED'
   order by created_at asc
   for update skip locked
   limit 1;

  if not found then
    return null;
  end if;

  update public.print_jobs
     set status = 'PRINTING',
         assigned_agent_id = p_agent_id,
         updated_at = now()
   where print_job_id = v_job.print_job_id;

  select * into v_job from public.print_jobs where print_job_id = v_job.print_job_id;
  return v_job;
end;
$$;

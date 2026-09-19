-- Refresh time-based operational task statuses without creating duplicate rows.
CREATE OR REPLACE FUNCTION public.refresh_operational_task_statuses()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin role required' USING ERRCODE = '42501';
  END IF;

  WITH desired AS (
    SELECT
      t.id,
      CASE
        WHEN t.due_at < now() THEN 'overdue'::task_status
        WHEN t.due_at <= now() + make_interval(days => COALESCE(s.upcoming_days, 7)) THEN 'due_soon'::task_status
        WHEN t.due_at::date = current_date THEN 'due'::task_status
        ELSE 'upcoming'::task_status
      END AS next_status
    FROM public.operational_tasks t
    LEFT JOIN public.task_settings s ON s.telecom_company_id = t.telecom_company_id
    WHERE t.status NOT IN ('completed', 'cancelled')
  )
  UPDATE public.operational_tasks t
  SET status = desired.next_status, updated_at = now()
  FROM desired
  WHERE t.id = desired.id AND t.status IS DISTINCT FROM desired.next_status;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION public.refresh_operational_task_statuses() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refresh_operational_task_statuses() TO authenticated;

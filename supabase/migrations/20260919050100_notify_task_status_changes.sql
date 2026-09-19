-- Extend task status refresh with idempotent admin notifications.
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

  INSERT INTO public.notifications (
    recipient_id, title, content, type, related_entity_type, related_entity_id
  )
  SELECT
    p.id,
    CASE WHEN t.status = 'overdue' THEN 'مهمة متأخرة' ELSE 'مهمة قريبة' END,
    CASE WHEN t.status = 'overdue'
      THEN 'توجد مهمة تشغيلية متأخرة وتحتاج إلى متابعة.'
      ELSE 'توجد مهمة تشغيلية قريبة من موعد الاستحقاق.'
    END,
    'operational_task_' || t.status,
    'operational_task',
    t.id
  FROM public.operational_tasks t
  CROSS JOIN public.profiles p
  WHERE p.role = 'admin'
    AND t.status IN ('due_soon', 'overdue')
    AND NOT EXISTS (
      SELECT 1
      FROM public.notifications n
      WHERE n.recipient_id = p.id
        AND n.related_entity_type = 'operational_task'
        AND n.related_entity_id = t.id
        AND n.type = 'operational_task_' || t.status
    );

  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION public.refresh_operational_task_statuses() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refresh_operational_task_statuses() TO authenticated;

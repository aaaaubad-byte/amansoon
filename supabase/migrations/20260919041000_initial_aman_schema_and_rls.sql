-- Applied to Supabase project amansoon (yqsnnooupyhahohyyiho)
-- Initial schema and RLS were applied before this repository was synchronized.
-- Keep future schema changes as versioned SQL migrations.

-- Review operations are transactional and enforce the admin role server-side.
CREATE OR REPLACE FUNCTION public.approve_protection_request(p_request_id uuid) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_request public.protection_requests%ROWTYPE;
  v_protection_id uuid;
  v_task_amount numeric := 0;
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin role required' USING ERRCODE = '42501'; END IF;
  SELECT * INTO v_request FROM public.protection_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'request not found' USING ERRCODE = 'P0002'; END IF;
  IF v_request.status <> 'under_review' THEN RAISE EXCEPTION 'request is not under review' USING ERRCODE = '22023'; END IF;
  SELECT COALESCE(task_amount, 0) INTO v_task_amount FROM public.task_settings WHERE telecom_company_id = v_request.telecom_company_id LIMIT 1;
  UPDATE public.protection_requests SET status = 'approved', reviewed_by = auth.uid(), reviewed_at = now(), updated_at = now() WHERE id = v_request.id;
  INSERT INTO public.protections (request_id, customer_id, customer_number_id, telecom_company_id, package_id, protection_value, duration_days, starts_at, expires_at)
  VALUES (v_request.id, v_request.customer_id, v_request.customer_number_id, v_request.telecom_company_id, v_request.package_id, v_request.protection_value_snapshot, v_request.duration_days_snapshot, now(), now() + make_interval(days => v_request.duration_days_snapshot))
  RETURNING id INTO v_protection_id;
  UPDATE public.customer_numbers SET is_protected = true, updated_at = now() WHERE id = v_request.customer_number_id AND customer_id = v_request.customer_id AND is_protected = false;
  IF NOT FOUND THEN RAISE EXCEPTION 'number is already protected' USING ERRCODE = '23505'; END IF;
  INSERT INTO public.operational_tasks (protection_id, telecom_company_id, task_amount, due_at, cycle_number) VALUES (v_protection_id, v_request.telecom_company_id, v_task_amount, now(), 1);
  INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, after_data) VALUES (auth.uid(), 'approve', 'protection_request', v_request.id, jsonb_build_object('protection_id', v_protection_id));
  INSERT INTO public.notifications (recipient_id, title, content, type, related_entity_type, related_entity_id) VALUES (v_request.customer_id, 'تم قبول طلب الحماية', 'تم قبول طلب حماية رقمك وإنشاء الحماية والمهمة الأولى.', 'protection_approved', 'protection_request', v_request.id);
  RETURN v_protection_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_protection_request(p_request_id uuid, p_reason text) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_request public.protection_requests%ROWTYPE;
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin role required' USING ERRCODE = '42501'; END IF;
  IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN RAISE EXCEPTION 'rejection reason required' USING ERRCODE = '22023'; END IF;
  SELECT * INTO v_request FROM public.protection_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'request not found' USING ERRCODE = 'P0002'; END IF;
  IF v_request.status <> 'under_review' THEN RAISE EXCEPTION 'request is not under review' USING ERRCODE = '22023'; END IF;
  UPDATE public.protection_requests SET status = 'rejected', rejection_reason = trim(p_reason), reviewed_by = auth.uid(), reviewed_at = now(), updated_at = now() WHERE id = v_request.id;
  INSERT INTO public.audit_logs (actor_id, action, entity_type, entity_id, after_data) VALUES (auth.uid(), 'reject', 'protection_request', v_request.id, jsonb_build_object('reason', trim(p_reason)));
  INSERT INTO public.notifications (recipient_id, title, content, type, related_entity_type, related_entity_id) VALUES (v_request.customer_id, 'تم رفض طلب الحماية', trim(p_reason), 'protection_rejected', 'protection_request', v_request.id);
  RETURN v_request.id;
END;
$$;

REVOKE ALL ON FUNCTION public.approve_protection_request(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_protection_request(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.reject_protection_request(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_protection_request(uuid, text) TO authenticated;

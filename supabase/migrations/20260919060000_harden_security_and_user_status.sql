-- Harden exposed helper access, protect user role/status, and cover foreign keys.
REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM anon;
REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM authenticated;

CREATE OR REPLACE FUNCTION public.guard_profile_role_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() AND (NEW.role IS DISTINCT FROM OLD.role OR NEW.status IS DISTINCT FROM OLD.status) THEN
    RAISE EXCEPTION 'only an admin can change role or status' USING ERRCODE = '42501';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_guard_role_status ON public.profiles;
CREATE TRIGGER profiles_guard_role_status
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.guard_profile_role_status();

CREATE OR REPLACE FUNCTION public.admin_set_profile_status(p_user_id uuid, p_active boolean)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin role required' USING ERRCODE = '42501'; END IF;
  IF p_user_id = auth.uid() AND p_active = false THEN
    RAISE EXCEPTION 'cannot deactivate current admin' USING ERRCODE = '22023';
  END IF;
  UPDATE public.profiles
  SET status = CASE WHEN p_active THEN 'active'::record_status ELSE 'inactive'::record_status END,
      updated_at = now()
  WHERE id = p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile not found' USING ERRCODE = 'P0002'; END IF;
  INSERT INTO public.audit_logs(actor_id, action, entity_type, entity_id, after_data)
  VALUES (auth.uid(), CASE WHEN p_active THEN 'activate' ELSE 'deactivate' END, 'profile', p_user_id, jsonb_build_object('status', CASE WHEN p_active THEN 'active' ELSE 'inactive' END));
  RETURN p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_profile_status(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_profile_status(uuid, boolean) TO authenticated;

CREATE INDEX IF NOT EXISTS audit_logs_actor_id_idx ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS customer_numbers_telecom_company_id_idx ON public.customer_numbers(telecom_company_id);
CREATE INDEX IF NOT EXISTS operational_tasks_completed_by_idx ON public.operational_tasks(completed_by);
CREATE INDEX IF NOT EXISTS operational_tasks_telecom_company_id_idx ON public.operational_tasks(telecom_company_id);
CREATE INDEX IF NOT EXISTS protection_requests_customer_number_id_idx ON public.protection_requests(customer_number_id);
CREATE INDEX IF NOT EXISTS protection_requests_package_id_idx ON public.protection_requests(package_id);
CREATE INDEX IF NOT EXISTS protection_requests_payment_method_id_idx ON public.protection_requests(payment_method_id);
CREATE INDEX IF NOT EXISTS protection_requests_reviewed_by_idx ON public.protection_requests(reviewed_by);
CREATE INDEX IF NOT EXISTS protection_requests_telecom_company_id_idx ON public.protection_requests(telecom_company_id);
CREATE INDEX IF NOT EXISTS protections_customer_number_id_idx ON public.protections(customer_number_id);
CREATE INDEX IF NOT EXISTS protections_package_id_idx ON public.protections(package_id);
CREATE INDEX IF NOT EXISTS protections_telecom_company_id_idx ON public.protections(telecom_company_id);

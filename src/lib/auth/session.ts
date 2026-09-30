import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function requireUser() {
  const supabase = await createSupabaseServerClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login");
  return { supabase, user };
}

export async function getActiveWorkspace() {
  const { supabase, user } = await requireUser();
  const { data, error } = await supabase
    .from("workspace_members")
    .select("workspace_id, role, workspaces(id,name,industry)")
    .eq("user_id", user.id)
    .limit(1)
    .maybeSingle();
  if (error) throw new Error("WORKSPACE_LOOKUP_FAILED");
  if (!data) redirect("/onboarding");
  return { supabase, user, membership: data };
}

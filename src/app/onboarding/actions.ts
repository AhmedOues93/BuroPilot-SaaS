"use server";
import { redirect } from "next/navigation";
import { requireUser } from "@/lib/auth/session";

export async function createWorkspace(form: FormData) {
  const { supabase }=await requireUser();
  const name=String(form.get("name")??"").trim();
  const industry=String(form.get("industry")??"").trim();
  if(name.length<2) redirect("/onboarding?error=name");
  const { error }=await supabase.rpc("create_workspace",{workspace_name:name,workspace_industry:industry||null});
  if(error) redirect("/onboarding?error=workspace");
  redirect("/dashboard");
}

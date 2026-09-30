"use server";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

function value(form: FormData, key: string) { return String(form.get(key) ?? "").trim(); }

export async function signIn(form: FormData) {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email: value(form,"email"), password: value(form,"password") });
  if (error) redirect("/login?error=invalid_credentials");
  redirect("/dashboard");
}

export async function signUp(form: FormData) {
  const supabase = await createSupabaseServerClient();
  const email=value(form,"email"), password=value(form,"password");
  const appUrl=process.env.APP_URL ?? "http://localhost:3000";
  const { error } = await supabase.auth.signUp({ email, password, options:{ emailRedirectTo: `${appUrl}/auth/callback` } });
  if (error) redirect("/register?error=signup_failed");
  redirect("/login?message=verify_email");
}

export async function requestPasswordReset(form: FormData) {
  const supabase = await createSupabaseServerClient();
  const appUrl=process.env.APP_URL ?? "http://localhost:3000";
  await supabase.auth.resetPasswordForEmail(value(form,"email"), { redirectTo:`${appUrl}/reset-password` });
  redirect("/forgot-password?message=sent");
}

export async function updatePassword(form: FormData) {
  const supabase=await createSupabaseServerClient();
  const password=value(form,"password");
  if(password.length<8) redirect("/reset-password?error=weak_password");
  const { error }=await supabase.auth.updateUser({password});
  if(error) redirect("/reset-password?error=update_failed");
  redirect("/dashboard");
}

export async function signOut() {
  const supabase=await createSupabaseServerClient();
  await supabase.auth.signOut();
  redirect("/login");
}

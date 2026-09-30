import Link from "next/link";
import { signUp } from "@/app/auth/actions";
export default function Register(){return <main className="auth"><form action={signUp} className="panel"><b className="brand">BuroPilot</b><h1>Konto erstellen</h1><p>Starten Sie mit einem sicheren Firmenkonto.</p><label>E-Mail<input name="email" type="email" required autoComplete="email"/></label><label>Passwort<input name="password" type="password" minLength={8} required autoComplete="new-password"/></label><button>Konto erstellen</button><p>Schon registriert? <Link href="/login">Anmelden</Link></p></form></main>}

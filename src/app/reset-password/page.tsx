import { updatePassword } from "@/app/auth/actions";
export default function Reset(){return <main className="auth"><form action={updatePassword} className="panel"><b className="brand">BuroPilot</b><h1>Neues Passwort</h1><label>Passwort<input name="password" type="password" minLength={8} required/></label><button>Passwort speichern</button></form></main>}

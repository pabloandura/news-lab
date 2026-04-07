"use client"

import { useState } from "react"
import { Eye, EyeOff, Loader2, FlaskConical } from "lucide-react"
import { cn } from "@/lib/utils"

interface SignInScreenProps {
  onSignIn: () => void
}

export function SignInScreen({ onSignIn }: SignInScreenProps) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [mode, setMode] = useState<"signin" | "signup">("signin")

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setTimeout(() => {
      setLoading(false)
      onSignIn()
    }, 1400)
  }

  return (
    <div className="flex flex-col min-h-screen bg-background px-6">
      {/* Logo area */}
      <div className="flex flex-col items-center pt-20 pb-10">
        <div className="flex items-center justify-center h-14 w-14 rounded-2xl bg-primary/10 border border-primary/20 mb-5">
          <FlaskConical className="h-7 w-7 text-primary" fill="currentColor" strokeWidth={0} />
        </div>
        <h1 className="text-3xl font-bold tracking-tight text-foreground" style={{ fontFamily: 'var(--font-display)' }}>
          news<span className="text-primary">lab</span>
        </h1>
        <p className="mt-2 text-sm text-muted-foreground text-center text-balance">
          Publish, fact-check, and share stories that matter
        </p>
      </div>

      {/* Mode toggle */}
      <div className="flex rounded-xl bg-muted p-1 mb-8">
        {(["signin", "signup"] as const).map((m) => (
          <button
            key={m}
            onClick={() => setMode(m)}
            className={cn(
              "flex-1 py-2 text-sm font-semibold rounded-lg transition-all",
              mode === m
                ? "bg-card text-foreground shadow-sm"
                : "text-muted-foreground"
            )}
          >
            {m === "signin" ? "Sign In" : "Create Account"}
          </button>
        ))}
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4">
        {mode === "signup" && (
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Full Name</label>
            <input
              type="text"
              placeholder="Jane Reporter"
              className="w-full h-12 rounded-xl bg-card border border-border px-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
            />
          </div>
        )}

        <div className="space-y-1.5">
          <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Email</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="jane@newsroom.com"
            required
            className="w-full h-12 rounded-xl bg-card border border-border px-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
          />
        </div>

        <div className="space-y-1.5">
          <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Password</label>
          <div className="relative">
            <input
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              className="w-full h-12 rounded-xl bg-card border border-border px-4 pr-12 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground p-1"
            >
              {showPassword ? <EyeOff className="h-4 w-4" fill="currentColor" strokeWidth={0} /> : <Eye className="h-4 w-4" fill="currentColor" strokeWidth={0} />}
            </button>
          </div>
        </div>

        {mode === "signin" && (
          <div className="flex justify-end">
            <button type="button" className="text-xs text-primary font-medium">
              Forgot password?
            </button>
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full h-13 rounded-xl bg-primary text-primary-foreground font-bold text-sm tracking-wide mt-2 flex items-center justify-center gap-2 transition-opacity active:opacity-80 disabled:opacity-60"
        >
          {loading ? (
            <><Loader2 className="h-4 w-4 animate-spin" fill="currentColor" strokeWidth={0} /> Authenticating...</>
          ) : (
            mode === "signin" ? "Sign In to Newsroom" : "Create Journalist Account"
          )}
        </button>
      </form>

      {/* Divider */}
      <div className="flex items-center gap-3 my-6">
        <div className="flex-1 h-px bg-border" />
        <span className="text-xs text-muted-foreground uppercase tracking-wider">or continue with</span>
        <div className="flex-1 h-px bg-border" />
      </div>

      {/* Social buttons */}
      <div className="grid grid-cols-2 gap-3">
        {["Google", "Apple"].map((provider) => (
          <button
            key={provider}
            type="button"
            onClick={onSignIn}
            className="h-12 rounded-xl border border-border bg-card text-sm font-semibold text-foreground flex items-center justify-center gap-2 transition-colors active:bg-muted"
          >
            {provider}
          </button>
        ))}
      </div>

      {/* Terms */}
      <p className="mt-8 text-center text-[11px] text-muted-foreground leading-relaxed">
        By continuing, you agree to our{" "}
        <span className="text-primary font-medium">Terms of Service</span> and{" "}
        <span className="text-primary font-medium">Privacy Policy</span>
      </p>
    </div>
  )
}

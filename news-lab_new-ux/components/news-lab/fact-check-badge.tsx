"use client"

import { cn } from "@/lib/utils"
import { ShieldCheck, ShieldAlert, ShieldX, Loader2 } from "lucide-react"

export type CredibilityLevel = "high" | "mid" | "low" | "unverified"

interface FactCheckBadgeProps {
  level: CredibilityLevel
  score?: number // 0-100 community score
  aiVerified?: boolean
  compact?: boolean
  className?: string
}

const CRED_CONFIG = {
  high: {
    label: "Credible",
    Icon: ShieldCheck,
    bg: "bg-[#1a2b25]",
    text: "text-[oklch(0.68_0.14_155)]",
    border: "border-[oklch(0.32_0.10_155)]",
    ring: "oklch(0.62_0.15_155)",
  },
  mid: {
    label: "Mixed",
    Icon: ShieldAlert,
    bg: "bg-[#2a1f12]",
    text: "text-[#BF5B04]",
    border: "border-[#733917]",
    ring: "#BF5B04",
  },
  low: {
    label: "Disputed",
    Icon: ShieldX,
    bg: "bg-[oklch(0.18_0.06_18)]",
    text: "text-[oklch(0.70_0.20_18)]",
    border: "border-[oklch(0.34_0.14_18)]",
    ring: "oklch(0.55_0.21_18)",
  },
  unverified: {
    label: "Unverified",
    Icon: ShieldCheck,
    bg: "bg-muted",
    text: "text-muted-foreground",
    border: "border-border",
    ring: "#65768C",
  },
}

export function FactCheckBadge({
  level,
  score,
  aiVerified,
  compact = false,
  className,
}: FactCheckBadgeProps) {
  const cfg = CRED_CONFIG[level]
  const { Icon } = cfg

  if (compact) {
    return (
      <span
        className={cn(
          "inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[10px] font-semibold tracking-wide uppercase",
          cfg.bg,
          cfg.text,
          cfg.border,
          className
        )}
      >
        <Icon className="h-2.5 w-2.5" fill="currentColor" strokeWidth={0} />
        {cfg.label}
        {score !== undefined && <span className="opacity-70 ml-0.5">·{score}%</span>}
      </span>
    )
  }

  return (
    <div className={cn("rounded-xl border p-3 space-y-2", cfg.bg, cfg.border, className)}>
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">
          Fact Check
        </span>
        <span className={cn("flex items-center gap-1 text-xs font-bold", cfg.text)}>
          <Icon className="h-3.5 w-3.5" fill="currentColor" strokeWidth={0} />
          {cfg.label}
        </span>
      </div>

      {score !== undefined && (
        <>
          <div className="flex items-center justify-between text-[11px] text-muted-foreground">
            <span>Community credibility score</span>
            <span className={cn("font-bold", cfg.text)}>{score}%</span>
          </div>
          <div className="h-1.5 rounded-full bg-muted overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-500"
              style={{ width: `${score}%`, background: cfg.ring }}
            />
          </div>
        </>
      )}

      {aiVerified !== undefined && (
        <div className={cn("flex items-center gap-1.5 text-[11px]", cfg.text)}>
          {aiVerified ? (
            <ShieldCheck className="h-3 w-3" fill="currentColor" strokeWidth={0} />
          ) : (
            <Loader2 className="h-3 w-3 animate-spin" fill="currentColor" strokeWidth={0} />
          )}
          <span>{aiVerified ? "AI verified · Ollama LLM" : "AI check pending..."}</span>
        </div>
      )}
    </div>
  )
}

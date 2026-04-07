"use client"

import { cn } from "@/lib/utils"

export type BiasLean = "left" | "center" | "right"

interface BiasBadgeProps {
  lean: BiasLean
  score?: number // 0-100
  compact?: boolean
  className?: string
}

const BIAS_CONFIG = {
  left: {
    label: "Left",
    icon: "◀",
    bg: "bg-[oklch(0.20_0.07_18)]",
    text: "text-[oklch(0.72_0.20_18)]",
    border: "border-[oklch(0.36_0.14_18)]",
    dot: "bg-[oklch(0.60_0.22_18)]",
  },
  center: {
    label: "Center",
    icon: "◆",
    bg: "bg-[#1e2b33]",
    text: "text-[#65768C]",
    border: "border-[#2e434f]",
    dot: "bg-[#65768C]",
  },
  right: {
    label: "Right",
    icon: "▶",
    bg: "bg-[oklch(0.18_0.06_240)]",
    text: "text-[oklch(0.68_0.16_240)]",
    border: "border-[oklch(0.34_0.12_240)]",
    dot: "bg-[oklch(0.58_0.18_240)]",
  },
}

export function BiasBadge({ lean, score, compact = false, className }: BiasBadgeProps) {
  const cfg = BIAS_CONFIG[lean]

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
        <span className={cn("h-1.5 w-1.5 rounded-full", cfg.dot)} />
        {cfg.label}
      </span>
    )
  }

  return (
    <div className={cn("rounded-xl border p-3", cfg.bg, cfg.border, className)}>
      <div className="flex items-center justify-between mb-2">
        <span className={cn("text-xs font-semibold uppercase tracking-widest", cfg.text)}>
          AI Bias Analysis
        </span>
        <span className={cn("text-xs font-bold", cfg.text)}>{cfg.icon} {cfg.label}</span>
      </div>
      {/* Bias spectrum bar */}
      <div className="relative h-2 rounded-full bg-muted overflow-hidden">
        <div className="absolute inset-0 flex">
          <div className="flex-1 bg-[oklch(0.55_0.20_18)]/40 rounded-l-full" />
          <div className="flex-1 bg-[#65768C]/30" />
          <div className="flex-1 bg-[oklch(0.52_0.16_240)]/40 rounded-r-full" />
        </div>
        <div
          className={cn("absolute top-0 h-2 w-2 rounded-full border-2 border-background -translate-x-1/2", cfg.dot)}
          style={{
            left: lean === "left" ? "16%" : lean === "center" ? "50%" : "84%",
          }}
        />
      </div>
      <div className="flex justify-between mt-1">
        <span className="text-[9px] text-muted-foreground uppercase tracking-wider">Left</span>
        <span className="text-[9px] text-muted-foreground uppercase tracking-wider">Center</span>
        <span className="text-[9px] text-muted-foreground uppercase tracking-wider">Right</span>
      </div>
      {score !== undefined && (
        <p className={cn("mt-1.5 text-[11px]", cfg.text)}>
          Confidence: <span className="font-bold">{score}%</span>
        </p>
      )}
    </div>
  )
}

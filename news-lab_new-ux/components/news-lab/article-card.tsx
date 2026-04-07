"use client"

import { cn } from "@/lib/utils"
import { BiasBadge, type BiasLean } from "./bias-badge"
import { FactCheckBadge, type CredibilityLevel } from "./fact-check-badge"
import { Clock, ExternalLink } from "lucide-react"

export interface Article {
  id: string
  title: string
  description: string
  category: string
  author: string
  authorAvatar?: string
  publishedAt: string
  thumbnail?: string
  biasLean?: BiasLean
  credibility?: CredibilityLevel
  credibilityScore?: number
  readTime?: number
  isOwn?: boolean
  source?: string
}

interface ArticleCardProps {
  article: Article
  onClick?: () => void
  variant?: "default" | "featured" | "compact"
  className?: string
}

// Warm topics use the burnt-orange accent; cool/neutral topics use the slate-blue muted tone
const CATEGORY_COLORS: Record<string, string> = {
  Politics:      "text-[#BF5B04] border-[#733917] bg-[#1f1208]",
  Tech:          "text-[#65768C] border-[#2e434f] bg-[#1a2228]",
  Science:       "text-[#65768C] border-[#2e434f] bg-[#1a2228]",
  Health:        "text-[#65768C] border-[#2e434f] bg-[#1a2228]",
  Business:      "text-[#BF5B04] border-[#733917] bg-[#1f1208]",
  World:         "text-[#65768C] border-[#2e434f] bg-[#1a2228]",
  Sports:        "text-[#BF5B04] border-[#733917] bg-[#1f1208]",
  Entertainment: "text-[#BF5B04] border-[#733917] bg-[#1f1208]",
}

function CategoryPill({ category }: { category: string }) {
  const colors = CATEGORY_COLORS[category] ?? "text-muted-foreground border-border bg-muted"
  return (
    <span className={cn("inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider", colors)}>
      {category}
    </span>
  )
}

export function ArticleCard({ article, onClick, variant = "default", className }: ArticleCardProps) {
  if (variant === "compact") {
    const Comp = onClick ? "button" : "div"
    return (
      <Comp
        {...(onClick ? { onClick } : {})}
        className={cn(
          "w-full flex gap-3 p-3 rounded-xl border border-border bg-card text-left transition-colors active:bg-muted",
          className
        )}
      >
        {article.thumbnail && (
          <img
            src={article.thumbnail}
            alt={article.title}
            className="h-16 w-16 rounded-lg object-cover flex-shrink-0"
          />
        )}
        <div className="flex-1 min-w-0 space-y-1">
          <div className="flex items-center gap-1.5 flex-wrap">
            <CategoryPill category={article.category} />
            {article.biasLean && <BiasBadge lean={article.biasLean} compact />}
          </div>
          <p className="text-sm font-semibold text-foreground leading-tight line-clamp-2 text-balance">
            {article.title}
          </p>
          <p className="text-[11px] text-muted-foreground">{article.author} · {article.publishedAt}</p>
        </div>
      </Comp>
    )
  }

  if (variant === "featured") {
    return (
      <button
        onClick={onClick}
        className={cn(
          "w-full rounded-2xl overflow-hidden border border-border bg-card text-left transition-colors active:bg-muted",
          className
        )}
      >
        {article.thumbnail && (
          <div className="relative h-48 w-full overflow-hidden">
            <img
              src={article.thumbnail}
              alt={article.title}
              className="h-full w-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
            <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between">
              <CategoryPill category={article.category} />
              {article.source && (
                <span className="flex items-center gap-1 text-[10px] text-white/70">
                  <ExternalLink className="h-2.5 w-2.5" fill="currentColor" strokeWidth={0} />
                  {article.source}
                </span>
              )}
            </div>
          </div>
        )}
        <div className="p-4 space-y-3">
          <h3 className="text-base font-bold text-foreground leading-snug text-balance">{article.title}</h3>
          <p className="text-xs text-muted-foreground leading-relaxed line-clamp-2">{article.description}</p>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              {article.authorAvatar ? (
                <img src={article.authorAvatar} alt={article.author} className="h-5 w-5 rounded-full object-cover" />
              ) : (
                <div className="h-5 w-5 rounded-full bg-primary/20 flex items-center justify-center">
                  <span className="text-[9px] font-bold text-primary">{article.author[0]}</span>
                </div>
              )}
              <span className="text-[11px] text-muted-foreground">{article.author}</span>
            </div>
            <div className="flex items-center gap-1.5">
              {article.readTime && (
                <span className="flex items-center gap-0.5 text-[10px] text-muted-foreground">
                  <Clock className="h-2.5 w-2.5" fill="currentColor" strokeWidth={0} />
                  {article.readTime}m
                </span>
              )}
            </div>
          </div>
          {/* AI badges row */}
          <div className="flex items-center gap-2 pt-1 border-t border-border flex-wrap">
            {article.biasLean && <BiasBadge lean={article.biasLean} compact />}
            {article.credibility && (
              <FactCheckBadge
                level={article.credibility}
                score={article.credibilityScore}
                compact
              />
            )}
          </div>
        </div>
      </button>
    )
  }

  // default
  return (
    <button
      onClick={onClick}
      className={cn(
        "w-full flex gap-3 p-4 border-b border-border bg-transparent text-left transition-colors active:bg-muted",
        className
      )}
    >
      <div className="flex-1 min-w-0 space-y-2">
        <div className="flex items-center gap-1.5 flex-wrap">
          <CategoryPill category={article.category} />
          {article.isOwn && (
            <span className="inline-flex items-center rounded-full border border-primary/40 bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary uppercase tracking-wider">
              Your Article
            </span>
          )}
        </div>
        <h3 className="text-sm font-bold text-foreground leading-snug text-balance">{article.title}</h3>
        <p className="text-xs text-muted-foreground leading-relaxed line-clamp-2">{article.description}</p>
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-[10px] text-muted-foreground">{article.author} · {article.publishedAt}</span>
          {article.readTime && (
            <span className="flex items-center gap-0.5 text-[10px] text-muted-foreground">
              <Clock className="h-2.5 w-2.5" fill="currentColor" strokeWidth={0} />{article.readTime}m
            </span>
          )}
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          {article.biasLean && <BiasBadge lean={article.biasLean} compact />}
          {article.credibility && (
            <FactCheckBadge
              level={article.credibility}
              score={article.credibilityScore}
              compact
            />
          )}
        </div>
      </div>
      {article.thumbnail && (
        <img
          src={article.thumbnail}
          alt={article.title}
          className="h-20 w-20 rounded-xl object-cover flex-shrink-0"
        />
      )}
    </button>
  )
}

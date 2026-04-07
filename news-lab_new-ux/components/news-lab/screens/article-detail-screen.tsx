"use client"

import { useState } from "react"
import {
  ArrowLeft, BookmarkPlus, Share2, ThumbsUp, ThumbsDown, Loader2,
  ChevronDown, ChevronUp, Sparkles
} from "lucide-react"
import { type Article } from "../article-card"
import { BiasBadge } from "../bias-badge"
import { FactCheckBadge } from "../fact-check-badge"
import { ArticleCard } from "../article-card"
import { cn } from "@/lib/utils"

const SIMILAR_ARTICLES: Article[] = [
  {
    id: "s1",
    title: "House Intelligence Committee holds emergency session on frontier AI systems",
    description: "Emergency hearing convened following publication of a leaked internal safety report.",
    category: "Politics",
    author: "Reuters",
    publishedAt: "3h ago",
    thumbnail: "https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=200&q=80",
    biasLean: "center",
    credibility: "high",
    credibilityScore: 82,
    readTime: 4,
    source: "News API",
  },
  {
    id: "s2",
    title: "Tech giants form voluntary AI safety coalition ahead of Senate vote",
    description: "Seven companies sign a memorandum committing to third-party audits.",
    category: "Tech",
    author: "Wired",
    publishedAt: "5h ago",
    thumbnail: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=200&q=80",
    biasLean: "left",
    credibility: "high",
    credibilityScore: 79,
    readTime: 5,
    source: "News API",
  },
  {
    id: "s3",
    title: "Opinion: The AI Act is already outdated before it becomes law",
    description: "A veteran technology policy analyst argues the bill cannot keep pace with model capabilities.",
    category: "Tech",
    author: "Jake Morris",
    publishedAt: "1d ago",
    thumbnail: "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=200&q=80",
    biasLean: "right",
    credibility: "mid",
    credibilityScore: 54,
    readTime: 6,
  },
]

const ARTICLE_BODY = `The legislation, which cleared the Senate by a 62–38 bipartisan margin on Thursday, represents the most significant federal effort to regulate artificial intelligence since the technology entered mainstream use.

At its core, the AI Governance Act would require any company training a model above a compute threshold of 10²⁶ FLOPs to submit to mandatory red-teaming exercises overseen by a newly created Office of AI Safety (OAIS), housed within NIST.

"This is not about stifling innovation," said Sen. Amy Torres (D-CA), the bill's lead sponsor. "It is about ensuring that the most powerful systems humans have ever built are held to the same standards of accountability we apply everywhere else."

Industry opposition has been fierce. OpenAI, Anthropic, and Google DeepMind each released statements expressing concern that the reporting requirements could expose proprietary model architectures to foreign adversaries. A coalition of venture-backed startups warned that compliance costs would make it impossible for smaller players to compete.

**What the bill actually requires**

- Frontier model developers must register with OAIS within 30 days of reaching the compute threshold
- Mandatory third-party safety evaluations before any public deployment
- Incident reporting within 72 hours of discovering a significant safety failure
- A new civil liability framework allowing individuals to sue for demonstrable harm

The bill now moves to the House, where it is expected to face a harder road. Speaker Mike Halverson (R-TX) called it "regulatory overreach that will push America's best engineers to jurisdictions without the same bureaucratic handcuffs."`

interface ArticleDetailScreenProps {
  article: Article
  onBack: () => void
  onArticleClick: (article: Article) => void
}

export function ArticleDetailScreen({ article, onBack, onArticleClick }: ArticleDetailScreenProps) {
  const [factCheckExpanded, setFactCheckExpanded] = useState(false)
  const [aiRunning, setAiRunning] = useState(false)
  const [aiDone, setAiDone] = useState(false)
  const [userVote, setUserVote] = useState<"up" | "down" | null>(null)
  const [biasExpanded, setBiasExpanded] = useState(false)
  const [similarExpanded, setSimilarExpanded] = useState(false)
  const [bookmarked, setBookmarked] = useState(false)

  function runAiCheck() {
    setAiRunning(true)
    setTimeout(() => {
      setAiRunning(false)
      setAiDone(true)
    }, 2200)
  }

  return (
    <div className="flex flex-col min-h-screen bg-background pb-8">
      {/* Top bar */}
      <div className="sticky top-0 z-40 flex items-center justify-between px-4 h-14 bg-background/95 backdrop-blur-md border-b border-border">
        <button
          onClick={onBack}
          className="h-9 w-9 rounded-xl flex items-center justify-center text-muted-foreground active:bg-muted"
        >
          <ArrowLeft className="h-5 w-5" fill="currentColor" strokeWidth={0} />
        </button>
        <div className="flex items-center gap-1">
          <button
            onClick={() => setBookmarked(!bookmarked)}
            className={cn(
              "h-9 w-9 rounded-xl flex items-center justify-center transition-colors active:bg-muted",
              bookmarked ? "text-primary" : "text-muted-foreground"
            )}
          >
            <BookmarkPlus className="h-5 w-5" fill="currentColor" strokeWidth={0} />
          </button>
          <button className="h-9 w-9 rounded-xl flex items-center justify-center text-muted-foreground active:bg-muted">
            <Share2 className="h-5 w-5" fill="currentColor" strokeWidth={0} />
          </button>
        </div>
      </div>

      {/* Hero thumbnail */}
      {article.thumbnail && (
        <div className="relative h-52 w-full overflow-hidden">
          <img src={article.thumbnail} alt={article.title} className="h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/30 to-transparent" />
        </div>
      )}

      {/* Content */}
      <div className="px-4 -mt-2 space-y-4">
        {/* Category + meta */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-xs font-bold text-primary uppercase tracking-widest">{article.category}</span>
          {article.source && (
            <span className="text-xs text-muted-foreground">· {article.source}</span>
          )}
        </div>

        {/* Title */}
        <h1 className="text-xl font-extrabold leading-tight text-foreground text-balance" style={{ fontFamily: 'var(--font-display)' }}>
          {article.title}
        </h1>

        {/* Author row */}
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
            <span className="text-sm font-bold text-primary">{article.author[0]}</span>
          </div>
          <div>
            <p className="text-sm font-semibold text-foreground">{article.author}</p>
            <p className="text-xs text-muted-foreground">{article.publishedAt} · {article.readTime ?? 6}min read</p>
          </div>
        </div>

        {/* Inline AI badges */}
        <div className="flex items-center gap-2 flex-wrap py-1">
          {article.biasLean && <BiasBadge lean={article.biasLean} compact />}
          {article.credibility && (
            <FactCheckBadge level={article.credibility} score={article.credibilityScore} compact />
          )}
        </div>

        {/* Article body */}
        <div className="text-sm text-foreground leading-relaxed space-y-4 border-t border-border pt-4">
          {ARTICLE_BODY.split("\n\n").map((para, i) => (
            <p key={i} className={para.startsWith("**") ? "font-bold text-foreground" : "text-muted-foreground leading-6"}>
              {para.replace(/\*\*/g, "")}
            </p>
          ))}
        </div>

        {/* Community vote */}
        <div className="rounded-xl border border-border bg-card p-4 space-y-3">
          <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Community Credibility Vote</p>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setUserVote(userVote === "up" ? null : "up")}
              className={cn(
                "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border text-sm font-semibold transition-all",
                userVote === "up"
                  ? "bg-[#1a2b25] border-[oklch(0.32_0.10_155)] text-[oklch(0.68_0.14_155)]"
                  : "bg-muted border-border text-muted-foreground"
              )}
            >
              <ThumbsUp className="h-4 w-4" fill="currentColor" strokeWidth={0} />
              Credible
            </button>
            <button
              onClick={() => setUserVote(userVote === "down" ? null : "down")}
              className={cn(
                "flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border text-sm font-semibold transition-all",
                userVote === "down"
                  ? "bg-[oklch(0.18_0.06_18)] border-[oklch(0.34_0.14_18)] text-[oklch(0.70_0.20_18)]"
                  : "bg-muted border-border text-muted-foreground"
              )}
            >
              <ThumbsDown className="h-4 w-4" fill="currentColor" strokeWidth={0} />
              Disputed
            </button>
          </div>
          {userVote && (
            <p className="text-[11px] text-muted-foreground text-center">
              Vote recorded. Community score updates in real time.
            </p>
          )}
        </div>

        {/* Fact-check panel */}
        <div className="rounded-xl border border-border bg-card overflow-hidden">
          <button
            onClick={() => setFactCheckExpanded(!factCheckExpanded)}
            className="w-full flex items-center justify-between px-4 py-3.5"
          >
            <span className="text-sm font-semibold text-foreground flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-primary" fill="currentColor" strokeWidth={0} />
              AI Fact-Check Panel
            </span>
            {factCheckExpanded ? <ChevronUp className="h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} /> : <ChevronDown className="h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} />}
          </button>

          {factCheckExpanded && (
            <div className="px-4 pb-4 space-y-3 border-t border-border pt-3">
              <FactCheckBadge
                level={article.credibility ?? "unverified"}
                score={article.credibilityScore}
                aiVerified={aiDone ? true : undefined}
              />

              {!aiDone && (
                <button
                  onClick={runAiCheck}
                  disabled={aiRunning}
                  className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-primary/10 border border-primary/30 text-primary text-sm font-semibold transition-all active:opacity-80 disabled:opacity-60"
                >
                  {aiRunning ? (
                    <><Loader2 className="h-4 w-4 animate-spin" fill="currentColor" strokeWidth={0} /> Running Ollama LLM check...</>
                  ) : (
                    <><Sparkles className="h-4 w-4" fill="currentColor" strokeWidth={0} /> Run AI Fact-Check</>
                  )}
                </button>
              )}

              {aiDone && (
                <div className="rounded-lg bg-muted p-3 text-xs text-muted-foreground leading-relaxed space-y-1">
                  <p className="font-semibold text-foreground">Ollama LLM Analysis</p>
                  <p>The article accurately reports the Senate vote count and key provisions of the AI Governance Act. The attribution to Sen. Torres is verified against Congressional Record. Claims about industry opposition are corroborated by official statements. Minor hedging language used appropriately.</p>
                  <p className="text-primary font-medium mt-1">Verdict: Factually sound. No major inaccuracies detected.</p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Bias analysis panel */}
        <div className="rounded-xl border border-border bg-card overflow-hidden">
          <button
            onClick={() => setBiasExpanded(!biasExpanded)}
            className="w-full flex items-center justify-between px-4 py-3.5"
          >
            <span className="text-sm font-semibold text-foreground">Bias Analysis</span>
            {biasExpanded ? <ChevronUp className="h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} /> : <ChevronDown className="h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} />}
          </button>
          {biasExpanded && (
            <div className="px-4 pb-4 border-t border-border pt-3">
              <BiasBadge lean={article.biasLean ?? "center"} score={74} />
              <p className="mt-3 text-xs text-muted-foreground leading-relaxed">
                The article uses neutral framing for most statements. Political figures are quoted proportionally across party lines. Slight left-of-center lean detected in headline word choice and lead paragraph emphasis.
              </p>
            </div>
          )}
        </div>

        {/* Similar articles */}
        <div className="rounded-xl border border-border bg-card overflow-hidden">
          <button
            onClick={() => setSimilarExpanded(!similarExpanded)}
            className="w-full flex items-center justify-between px-4 py-3.5"
          >
            <span className="text-sm font-semibold text-foreground flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-primary" fill="currentColor" strokeWidth={0} />
              AI Similar Articles
            </span>
            {similarExpanded ? <ChevronUp className="h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} /> : <ChevronDown className="h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} />}
          </button>
          {similarExpanded && (
            <div className="border-t border-border divide-y divide-border">
              {SIMILAR_ARTICLES.map((a) => (
                <ArticleCard key={a.id} article={a} onClick={() => onArticleClick(a)} variant="compact" className="rounded-none border-0" />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

"use client"

import { useState } from "react"
import { Search } from "lucide-react"
import { ArticleCard, type Article } from "../article-card"
import { cn } from "@/lib/utils"

// Warm topics: burnt-orange accent. Cool/neutral topics: slate-blue muted.
const CATEGORY_GRID = [
  { label: "Politics",      icon: "🏛", color: "bg-[#1f1208] border-[#733917] text-[#BF5B04]" },
  { label: "Tech",          icon: "💻", color: "bg-[#1a2228] border-[#2e434f] text-[#65768C]" },
  { label: "Science",       icon: "🔬", color: "bg-[#1a2228] border-[#2e434f] text-[#65768C]" },
  { label: "Health",        icon: "🩺", color: "bg-[#1a2228] border-[#2e434f] text-[#65768C]" },
  { label: "Business",      icon: "📈", color: "bg-[#1f1208] border-[#733917] text-[#BF5B04]" },
  { label: "World",         icon: "🌍", color: "bg-[#1a2228] border-[#2e434f] text-[#65768C]" },
  { label: "Entertainment", icon: "🎬", color: "bg-[#1f1208] border-[#733917] text-[#BF5B04]" },
  { label: "Sports",        icon: "⚽", color: "bg-[#1f1208] border-[#733917] text-[#BF5B04]" },
]

const TRENDING: Article[] = [
  {
    id: "e1",
    title: "Quantum breakthrough: IBM achieves 1,000-qubit fault-tolerant processor",
    description: "The achievement could accelerate timelines for commercially viable quantum computing by five years.",
    category: "Tech",
    author: "Sam Watkins",
    publishedAt: "1h ago",
    thumbnail: "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=200&q=80",
    biasLean: "center",
    credibility: "high",
    credibilityScore: 91,
    readTime: 5,
    source: "News API",
  },
  {
    id: "e2",
    title: "WHO declares end to mpox health emergency in Central Africa",
    description: "Vaccination campaigns across DRC, CAR, and Uganda have driven transmission rates below outbreak threshold.",
    category: "Health",
    author: "Global Health Desk",
    publishedAt: "4h ago",
    thumbnail: "https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?w=200&q=80",
    biasLean: "center",
    credibility: "high",
    credibilityScore: 96,
    readTime: 3,
    source: "News API",
  },
  {
    id: "e3",
    title: "Apple unveils spatial computing headset with neural interface support",
    description: "The device allows hands-free control through detected facial and eye micro-movements.",
    category: "Tech",
    author: "Aria Patel",
    publishedAt: "6h ago",
    thumbnail: "https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=200&q=80",
    biasLean: "left",
    credibility: "mid",
    credibilityScore: 63,
    readTime: 6,
  },
]

interface ExploreScreenProps {
  onArticleClick: (article: Article) => void
}

export function ExploreScreen({ onArticleClick }: ExploreScreenProps) {
  const [activeCategory, setActiveCategory] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState("")

  const filteredTrending = TRENDING.filter((a) => {
    const matchCat = !activeCategory || a.category === activeCategory
    const matchSearch = !searchQuery || a.title.toLowerCase().includes(searchQuery.toLowerCase())
    return matchCat && matchSearch
  })

  return (
    <div className="flex flex-col min-h-screen bg-background pb-20">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-border px-4 pt-4 pb-3 space-y-3">
        <h2 className="text-xl font-bold tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>Explore</h2>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" fill="currentColor" strokeWidth={0} />
          <input
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search topics, journalists, stories..."
            className="w-full h-11 rounded-xl bg-muted border-0 pl-9 pr-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50"
          />
        </div>
      </header>

      <div className="px-4 pt-4 space-y-6 pb-4">
        {/* Category grid */}
        <section>
          <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-3">Browse by Category</h3>
          <div className="grid grid-cols-4 gap-2">
            {CATEGORY_GRID.map(({ label, icon, color }) => (
              <button
                key={label}
                onClick={() => setActiveCategory(activeCategory === label ? null : label)}
                className={cn(
                  "flex flex-col items-center gap-1.5 rounded-xl border py-3 px-1 transition-all",
                  color,
                  activeCategory === label ? "ring-2 ring-primary ring-offset-1 ring-offset-background" : ""
                )}
              >
                <span className="text-xl leading-none">{icon}</span>
                <span className="text-[10px] font-semibold leading-tight text-center">{label}</span>
              </button>
            ))}
          </div>
        </section>

        {/* Trending */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">
              {activeCategory ? `${activeCategory} Stories` : "Trending Now"}
            </h3>
            {activeCategory && (
              <button
                onClick={() => setActiveCategory(null)}
                className="text-xs text-primary font-medium"
              >
                Clear
              </button>
            )}
          </div>

          {filteredTrending.length > 0 ? (
            <div className="space-y-3">
              {filteredTrending.map((article, i) => (
                <div key={article.id} className="flex gap-3">
                  <span className="text-2xl font-black text-muted/60 leading-none w-6 flex-shrink-0 mt-1">{i + 1}</span>
                  <ArticleCard
                    article={article}
                    onClick={() => onArticleClick(article)}
                    variant="compact"
                    className="flex-1"
                  />
                </div>
              ))}
            </div>
          ) : (
            <div className="py-10 text-center">
              <p className="text-sm text-muted-foreground">No stories found</p>
            </div>
          )}
        </section>

        {/* Bias breakdown section */}
        <section className="rounded-xl border border-border bg-card p-4 space-y-3">
          <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Today&apos;s Bias Breakdown</h3>
          <p className="text-[11px] text-muted-foreground">Based on 247 articles indexed today</p>
          <div className="space-y-2.5">
            {[
              { lean: "Left",   pct: 38, color: "bg-[oklch(0.55_0.21_18)]" },
              { lean: "Center", pct: 29, color: "bg-[#65768C]" },
              { lean: "Right",  pct: 33, color: "bg-[oklch(0.52_0.16_240)]" },
            ].map(({ lean, pct, color }) => (
              <div key={lean} className="space-y-1">
                <div className="flex items-center justify-between text-[11px]">
                  <span className="text-muted-foreground font-medium">{lean}</span>
                  <span className="text-foreground font-semibold">{pct}%</span>
                </div>
                <div className="h-2 rounded-full bg-muted overflow-hidden">
                  <div className={cn("h-full rounded-full", color)} style={{ width: `${pct}%` }} />
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  )
}

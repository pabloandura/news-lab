"use client"

import { useState } from "react"
import { Search, Bell, FlaskConical, SlidersHorizontal } from "lucide-react"
import { ArticleCard, type Article } from "../article-card"
import { cn } from "@/lib/utils"

const CATEGORIES = ["All", "Politics", "Tech", "Science", "Business", "World", "Health"]

const MOCK_ARTICLES: Article[] = [
  {
    id: "1",
    title: "Senate passes sweeping AI Governance Act amid tech industry pushback",
    description: "Bipartisan legislation sets binding requirements on frontier model developers, including mandatory red-teaming and incident reporting to a new federal oversight board.",
    category: "Politics",
    author: "Maria Chen",
    publishedAt: "2h ago",
    thumbnail: "https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=400&q=80",
    biasLean: "center",
    credibility: "high",
    credibilityScore: 88,
    readTime: 6,
    source: "News API",
  },
  {
    id: "2",
    title: "My exclusive interview inside the world's last analogue newsroom",
    description: "I spent a week with the editors at The Butte Record — a paper that still uses hot-metal type — to understand how craft journalism survives the digital age.",
    category: "Tech",
    author: "You",
    publishedAt: "5h ago",
    thumbnail: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400&q=80",
    biasLean: "left",
    credibility: "high",
    credibilityScore: 92,
    readTime: 8,
    isOwn: true,
  },
  {
    id: "3",
    title: "New study links ultra-processed food consumption to accelerated brain aging",
    description: "Researchers at UCL tracked 10,000 participants over 14 years and found a 28% higher risk of cognitive decline in the highest-consumption quartile.",
    category: "Health",
    author: "Dr. Priya Nair",
    publishedAt: "8h ago",
    thumbnail: "https://images.unsplash.com/photo-1550534791-2677533605ab?w=400&q=80",
    biasLean: "center",
    credibility: "high",
    credibilityScore: 95,
    readTime: 5,
    source: "News API",
  },
  {
    id: "4",
    title: "Viral claim: Central banks are secretly buying Bitcoin — the truth",
    description: "A post claiming central banks hold 3% of all Bitcoin went viral. We ran the numbers through three independent auditors. Here is what we found.",
    category: "Business",
    author: "Tom Briggs",
    publishedAt: "12h ago",
    thumbnail: "https://images.unsplash.com/photo-1518546305927-5a555bb7020d?w=400&q=80",
    biasLean: "right",
    credibility: "low",
    credibilityScore: 28,
    readTime: 7,
    source: "News API",
  },
  {
    id: "5",
    title: "Scientists detect repeating radio signal from Andromeda for the first time",
    description: "The signal, observed over 72 consecutive hours, follows a pattern inconsistent with known stellar phenomena. Researchers are careful not to overstate its implications.",
    category: "Science",
    author: "Leila Osei",
    publishedAt: "1d ago",
    thumbnail: "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=400&q=80",
    biasLean: "center",
    credibility: "mid",
    credibilityScore: 61,
    readTime: 4,
    source: "News API",
  },
]

interface HomeFeedScreenProps {
  onArticleClick: (article: Article) => void
}

export function HomeFeedScreen({ onArticleClick }: HomeFeedScreenProps) {
  const [activeCategory, setActiveCategory] = useState("All")
  const [searchOpen, setSearchOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")

  const filtered = MOCK_ARTICLES.filter((a) => {
    const matchCat = activeCategory === "All" || a.category === activeCategory
    const matchSearch = !searchQuery || a.title.toLowerCase().includes(searchQuery.toLowerCase())
    return matchCat && matchSearch
  })

  const featured = filtered[0]
  const rest = filtered.slice(1)

  return (
    <div className="flex flex-col min-h-screen bg-background pb-20">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-border">
        <div className="flex items-center justify-between px-4 h-14">
          {searchOpen ? (
            <div className="flex-1 flex items-center gap-2">
              <input
                autoFocus
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search articles..."
                className="flex-1 h-9 rounded-xl bg-muted border-0 px-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50"
              />
              <button
                onClick={() => { setSearchOpen(false); setSearchQuery("") }}
                className="text-xs text-muted-foreground font-medium px-1"
              >
                Cancel
              </button>
            </div>
          ) : (
            <>
              <h1 className="text-xl font-bold tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>
                news<span className="text-primary">lab</span>
              </h1>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setSearchOpen(true)}
                  className="h-9 w-9 rounded-xl flex items-center justify-center text-muted-foreground active:bg-muted"
                >
                  <Search className="h-4.5 w-4.5" fill="currentColor" strokeWidth={0} />
                </button>
                <button className="h-9 w-9 rounded-xl flex items-center justify-center text-muted-foreground active:bg-muted relative">
                  <Bell className="h-4.5 w-4.5" fill="currentColor" strokeWidth={0} />
                  <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-primary" />
                </button>
              </div>
            </>
          )}
        </div>

        {/* Category filter */}
        <div className="flex gap-2 px-4 pb-3 overflow-x-auto scrollbar-hide">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={cn(
                "flex-shrink-0 px-3 py-1.5 rounded-full text-xs font-semibold uppercase tracking-wide transition-all border",
                activeCategory === cat
                  ? "bg-primary text-primary-foreground border-primary"
                  : "bg-muted text-muted-foreground border-transparent"
              )}
            >
              {cat}
            </button>
          ))}
        </div>
      </header>

      {/* Breaking ticker */}
      <div className="flex items-center gap-2 px-4 py-2 bg-[#1f1208] border-b border-[#733917]">
        <span className="flex-shrink-0 text-[10px] font-bold uppercase tracking-widest text-[#BF5B04] bg-[#733917] px-2 py-0.5 rounded">
          Breaking
        </span>
        <p className="text-[11px] text-[#f0ede8] truncate">
          Senate votes 62–38 to advance AI Governance Act to the President&apos;s desk
        </p>
      </div>

      {/* Feed */}
      <div className="flex flex-col">
        {/* Featured card */}
        {featured && (
          <div className="px-4 pt-4">
            <ArticleCard article={featured} onClick={() => onArticleClick(featured)} variant="featured" />
          </div>
        )}

        {/* Filter bar */}
        <div className="flex items-center justify-between px-4 pt-5 pb-2">
          <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Latest Stories
          </span>
          <button className="flex items-center gap-1 text-xs text-muted-foreground">
            <SlidersHorizontal className="h-3 w-3" fill="currentColor" strokeWidth={0} />
            Filter
          </button>
        </div>

        {/* Default list */}
        <div className="divide-y divide-border">
          {rest.map((article) => (
            <div key={article.id} className="px-4">
              <ArticleCard
                article={article}
                onClick={() => onArticleClick(article)}
                variant="default"
              />
            </div>
          ))}
        </div>

        {filtered.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 text-center px-6">
            <FlaskConical className="h-10 w-10 text-muted-foreground mb-3" fill="currentColor" strokeWidth={0} />
            <p className="text-sm font-semibold text-muted-foreground">No articles found</p>
            <p className="text-xs text-muted-foreground mt-1">Try a different category or search term</p>
          </div>
        )}
      </div>
    </div>
  )
}

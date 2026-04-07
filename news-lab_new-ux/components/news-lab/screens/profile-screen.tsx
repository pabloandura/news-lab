"use client"

import { useState } from "react"
import {
  Settings, LogOut, Pencil, Trash2, CheckCircle2, X, Loader2,
  FileText, Eye, ThumbsUp
} from "lucide-react"
import { BiasBadge } from "../bias-badge"
import { FactCheckBadge } from "../fact-check-badge"
import { ArticleCard, type Article } from "../article-card"
import { cn } from "@/lib/utils"

const MY_ARTICLES: Article[] = [
  {
    id: "p1",
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
    id: "p2",
    title: "The hidden cost of 'free' investigative journalism tools",
    description: "Open-source OSINT tools are reshaping investigative workflows — but at what privacy cost to sources?",
    category: "Tech",
    author: "You",
    publishedAt: "2d ago",
    thumbnail: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&q=80",
    biasLean: "center",
    credibility: "high",
    credibilityScore: 85,
    readTime: 6,
    isOwn: true,
  },
  {
    id: "p3",
    title: "Ground-level report: How local newsrooms are surviving the AI wave",
    description: "A three-month tour of regional newspapers reveals a nuanced picture of adaptation, resistance, and hope.",
    category: "Business",
    author: "You",
    publishedAt: "1w ago",
    thumbnail: "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=400&q=80",
    biasLean: "left",
    credibility: "mid",
    credibilityScore: 71,
    readTime: 10,
    isOwn: true,
  },
]

interface ProfileScreenProps {
  onSignOut: () => void
  onArticleClick: (article: Article) => void
}

type EditState = { id: string; field: "title" | "description"; value: string } | null

export function ProfileScreen({ onSignOut, onArticleClick }: ProfileScreenProps) {
  const [articles, setArticles] = useState(MY_ARTICLES)
  const [editing, setEditing] = useState<EditState>(null)
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [activeTab, setActiveTab] = useState<"articles" | "stats">("articles")

  function startEdit(id: string, field: "title" | "description") {
    const art = articles.find((a) => a.id === id)!
    setEditing({ id, field, value: field === "title" ? art.title : art.description })
  }

  function saveEdit() {
    if (!editing) return
    setSaving(true)
    setTimeout(() => {
      setArticles((prev) =>
        prev.map((a) =>
          a.id === editing.id ? { ...a, [editing.field]: editing.value } : a
        )
      )
      setSaving(false)
      setEditing(null)
    }, 800)
  }

  function confirmDelete(id: string) {
    setDeletingId(id)
    setTimeout(() => {
      setArticles((prev) => prev.filter((a) => a.id !== id))
      setDeletingId(null)
    }, 1000)
  }

  return (
    <div className="flex flex-col min-h-screen bg-background pb-20">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-border px-4 h-14 flex items-center justify-between">
        <h2 className="text-xl font-bold tracking-tight" style={{ fontFamily: 'var(--font-display)' }}>Profile</h2>
        <div className="flex items-center gap-1">
          <button className="h-9 w-9 rounded-xl flex items-center justify-center text-muted-foreground active:bg-muted">
            <Settings className="h-4.5 w-4.5" fill="currentColor" strokeWidth={0} />
          </button>
          <button
            onClick={onSignOut}
            className="h-9 w-9 rounded-xl flex items-center justify-center text-muted-foreground active:bg-muted"
          >
            <LogOut className="h-4.5 w-4.5" fill="currentColor" strokeWidth={0} />
          </button>
        </div>
      </header>

      {/* Profile card */}
      <div className="px-4 pt-5">
        <div className="rounded-2xl border border-border bg-card p-5 flex items-center gap-4">
          <div className="h-16 w-16 rounded-2xl bg-primary/15 border border-primary/20 flex items-center justify-center flex-shrink-0">
            <span className="text-2xl font-black text-primary">J</span>
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-base font-bold text-foreground">Jane Reporter</h3>
            <p className="text-xs text-muted-foreground truncate">jane@newsroom.com</p>
            <div className="flex items-center gap-2 mt-2">
              <span className="text-[10px] font-semibold text-primary bg-primary/10 border border-primary/20 rounded-full px-2 py-0.5 uppercase tracking-wider">
                Journalist
              </span>
              <span className="text-[10px] text-muted-foreground">Member since Jan 2024</span>
            </div>
          </div>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-3 gap-3 px-4 mt-4">
        {[
          { label: "Articles", value: articles.length, Icon: FileText },
          { label: "Total Views", value: "12.4k", Icon: Eye },
          { label: "Upvotes", value: "847", Icon: ThumbsUp },
        ].map(({ label, value, Icon }) => (
          <div key={label} className="rounded-xl border border-border bg-card p-3 text-center space-y-1">
            <Icon className="h-4 w-4 text-primary mx-auto" fill="currentColor" strokeWidth={0} />
            <p className="text-lg font-extrabold text-foreground">{value}</p>
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider">{label}</p>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-0 px-4 mt-5 border-b border-border">
        {(["articles", "stats"] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              "flex-1 py-2.5 text-sm font-semibold capitalize transition-all border-b-2 -mb-px",
              activeTab === tab
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground"
            )}
          >
            {tab === "articles" ? "My Articles" : "Analytics"}
          </button>
        ))}
      </div>

      {activeTab === "articles" && (
        <div className="px-4 pt-4 space-y-4">
          {articles.map((article) => (
            <div
              key={article.id}
              className={cn(
                "rounded-2xl border border-border bg-card overflow-hidden transition-opacity",
                deletingId === article.id && "opacity-50 scale-95"
              )}
            >
              {/* Article preview */}
              <div
                role="button"
                tabIndex={0}
                onClick={() => onArticleClick(article)}
                onKeyDown={(e) => e.key === "Enter" && onArticleClick(article)}
                className="w-full text-left cursor-pointer"
              >
                <ArticleCard article={article} variant="compact" className="rounded-none border-0 p-4" />
              </div>

              {/* Edit / Delete actions */}
              <div className="flex border-t border-border divide-x divide-border">
                <button
                  onClick={() => startEdit(article.id, "title")}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold text-muted-foreground active:bg-muted"
                >
                  <Pencil className="h-3.5 w-3.5" fill="currentColor" strokeWidth={0} />
                  Edit Title
                </button>
                <button
                  onClick={() => startEdit(article.id, "description")}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold text-muted-foreground active:bg-muted"
                >
                  <Pencil className="h-3.5 w-3.5" fill="currentColor" strokeWidth={0} />
                  Edit Desc.
                </button>
                <button
                  onClick={() => confirmDelete(article.id)}
                  className="flex items-center justify-center gap-1.5 px-4 py-2.5 text-xs font-semibold text-[oklch(0.70_0.20_18)] active:bg-muted"
                >
                  {deletingId === article.id ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" fill="currentColor" strokeWidth={0} />
                  ) : (
                    <Trash2 className="h-3.5 w-3.5" fill="currentColor" strokeWidth={0} />
                  )}
                </button>
              </div>
            </div>
          ))}

          {articles.length === 0 && (
            <div className="py-16 text-center space-y-2">
              <FileText className="h-10 w-10 text-muted-foreground mx-auto" fill="currentColor" strokeWidth={0} />
              <p className="text-sm font-semibold text-muted-foreground">No articles yet</p>
              <p className="text-xs text-muted-foreground">Tap Publish to share your first story</p>
            </div>
          )}
        </div>
      )}

      {activeTab === "stats" && (
        <div className="px-4 pt-4 space-y-4">
          {/* Avg credibility */}
          <div className="rounded-xl border border-border bg-card p-4 space-y-3">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Avg. Credibility Score</p>
            <div className="flex items-end gap-2">
              <span className="text-4xl font-extrabold text-foreground">83</span>
              <span className="text-sm text-muted-foreground pb-1">/ 100</span>
            </div>
            <FactCheckBadge level="high" score={83} />
          </div>

          {/* Avg bias */}
          <div className="rounded-xl border border-border bg-card p-4 space-y-3">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Bias Profile</p>
            <p className="text-xs text-muted-foreground">Average across your {articles.length} articles</p>
            <BiasBadge lean="left" score={62} />
          </div>

          {/* Views chart placeholder */}
          <div className="rounded-xl border border-border bg-card p-4 space-y-3">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-widest">Views (last 7 days)</p>
            <div className="flex items-end gap-1.5 h-20">
              {[30, 55, 40, 80, 65, 90, 72].map((h, i) => (
                <div
                  key={i}
                  className="flex-1 rounded-t-sm bg-[#733917]"
                  style={{ height: `${h}%` }}
                />
              ))}
            </div>
            <div className="flex justify-between text-[9px] text-muted-foreground">
              {["M", "T", "W", "T", "F", "S", "S"].map((d, i) => (
                <span key={i} className="flex-1 text-center">{d}</span>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Edit modal */}
      {editing && (
        <div className="fixed inset-0 z-50 flex items-end bg-black/60 backdrop-blur-sm" onClick={() => setEditing(null)}>
          <div
            className="w-full bg-card rounded-t-3xl border-t border-border p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-bold text-foreground capitalize">Edit {editing.field}</h4>
              <button onClick={() => setEditing(null)}>
                <X className="h-5 w-5 text-muted-foreground" fill="currentColor" strokeWidth={0} />
              </button>
            </div>
            {editing.field === "title" ? (
              <input
                value={editing.value}
                onChange={(e) => setEditing({ ...editing, value: e.target.value })}
                className="w-full h-12 rounded-xl bg-background border border-border px-4 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/50"
                autoFocus
              />
            ) : (
              <textarea
                value={editing.value}
                onChange={(e) => setEditing({ ...editing, value: e.target.value })}
                rows={4}
                className="w-full rounded-xl bg-background border border-border px-4 py-3 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 resize-none"
                autoFocus
              />
            )}
            <button
              onClick={saveEdit}
              disabled={saving}
              className="w-full h-12 rounded-xl bg-primary text-primary-foreground font-bold text-sm flex items-center justify-center gap-2 disabled:opacity-60"
            >
              {saving ? <Loader2 className="h-4 w-4 animate-spin" fill="currentColor" strokeWidth={0} /> : <CheckCircle2 className="h-4 w-4" fill="currentColor" strokeWidth={0} />}
              {saving ? "Saving..." : "Save Changes"}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

"use client"

import { useState } from "react"
import { X, ImagePlus, Loader2, CheckCircle2, ChevronDown } from "lucide-react"
import { cn } from "@/lib/utils"

const CATEGORIES = ["Politics", "Tech", "Science", "Health", "Business", "World", "Entertainment", "Sports"]

interface PublishScreenProps {
  onPublished?: () => void
}

export function PublishScreen({ onPublished }: PublishScreenProps) {
  const [title, setTitle] = useState("")
  const [description, setDescription] = useState("")
  const [body, setBody] = useState("")
  const [category, setCategory] = useState("")
  const [thumbnail, setThumbnail] = useState<string | null>(null)
  const [categoryOpen, setCategoryOpen] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [published, setPublished] = useState(false)
  const [step, setStep] = useState<1 | 2>(1)

  const isStep1Valid = title.length > 5 && description.length > 10 && category !== ""

  function handleThumbnailPick() {
    const samples = [
      "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400&q=80",
      "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=400&q=80",
      "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&q=80",
    ]
    setThumbnail(samples[Math.floor(Math.random() * samples.length)])
  }

  function handlePublish() {
    setPublishing(true)
    setTimeout(() => {
      setPublishing(false)
      setPublished(true)
      setTimeout(() => {
        onPublished?.()
      }, 2000)
    }, 2000)
  }

  if (published) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-background px-6 text-center gap-5">
        <div className="h-20 w-20 rounded-full bg-[#1a2b25] border border-[oklch(0.32_0.10_155)] flex items-center justify-center">
          <CheckCircle2 className="h-10 w-10 text-[oklch(0.68_0.14_155)]" fill="currentColor" strokeWidth={0} />
        </div>
        <div>
          <h2 className="text-2xl font-bold text-foreground" style={{ fontFamily: 'var(--font-display)' }}>Article Published</h2>
          <p className="mt-2 text-sm text-muted-foreground text-balance">
            Your article is live in the feed and has been queued for AI bias and fact-check analysis.
          </p>
        </div>
        <div className="flex flex-col gap-2 w-full">
          <div className="rounded-xl border border-[oklch(0.32_0.10_155)] bg-[#1a2b25] px-4 py-2.5 text-[11px] text-[oklch(0.68_0.14_155)] text-center">
            AI Bias analysis will complete in ~2 minutes
          </div>
          <div className="rounded-xl border border-[oklch(0.32_0.10_155)] bg-[#1a2b25] px-4 py-2.5 text-[11px] text-[oklch(0.68_0.14_155)] text-center">
            Fact-check score available once 5+ votes are received
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col min-h-screen bg-background pb-10">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-border px-4 h-14 flex items-center justify-between">
        <h2 className="text-base font-bold" style={{ fontFamily: 'var(--font-display)' }}>New Article</h2>
        {/* Step indicator */}
        <div className="flex items-center gap-1.5">
          {([1, 2] as const).map((s) => (
            <div
              key={s}
              className={cn(
                "h-1.5 rounded-full transition-all",
                s === step ? "w-6 bg-primary" : s < step ? "w-4 bg-primary/50" : "w-4 bg-muted"
              )}
            />
          ))}
        </div>
      </header>

      <div className="px-4 pt-5 space-y-5">
        {step === 1 && (
          <>
            {/* Category */}
            <div className="space-y-2">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Category *</label>
              <div className="relative">
                <button
                  onClick={() => setCategoryOpen(!categoryOpen)}
                  className={cn(
                    "w-full h-12 rounded-xl bg-card border px-4 text-sm flex items-center justify-between transition-all",
                    category ? "text-foreground border-primary/50" : "text-muted-foreground border-border"
                  )}
                >
                  {category || "Select a category"}
                  <ChevronDown className={cn("h-4 w-4 transition-transform", categoryOpen && "rotate-180")} fill="currentColor" strokeWidth={0} />
                </button>
                {categoryOpen && (
                  <div className="absolute top-full left-0 right-0 mt-1 rounded-xl bg-card border border-border z-10 overflow-hidden shadow-xl">
                    {CATEGORIES.map((cat) => (
                      <button
                        key={cat}
                        onClick={() => { setCategory(cat); setCategoryOpen(false) }}
                        className={cn(
                          "w-full text-left px-4 py-3 text-sm transition-colors hover:bg-muted",
                          category === cat ? "text-primary font-semibold" : "text-foreground"
                        )}
                      >
                        {cat}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Title */}
            <div className="space-y-2">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Headline *</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Write a compelling headline..."
                maxLength={120}
                className="w-full h-12 rounded-xl bg-card border border-border px-4 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all"
              />
              <p className="text-right text-[10px] text-muted-foreground">{title.length}/120</p>
            </div>

            {/* Description */}
            <div className="space-y-2">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Description *</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="A one or two sentence summary of your article..."
                rows={3}
                maxLength={280}
                className="w-full rounded-xl bg-card border border-border px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all resize-none"
              />
              <p className="text-right text-[10px] text-muted-foreground">{description.length}/280</p>
            </div>

            {/* Thumbnail */}
            <div className="space-y-2">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Thumbnail</label>
              {thumbnail ? (
                <div className="relative rounded-xl overflow-hidden h-40">
                  <img src={thumbnail} alt="Thumbnail" className="h-full w-full object-cover" />
                  <button
                    onClick={() => setThumbnail(null)}
                    className="absolute top-2 right-2 h-7 w-7 rounded-full bg-black/60 flex items-center justify-center"
                  >
                    <X className="h-3.5 w-3.5 text-white" fill="currentColor" strokeWidth={0} />
                  </button>
                </div>
              ) : (
                <button
                  onClick={handleThumbnailPick}
                  className="w-full h-32 rounded-xl border-2 border-dashed border-border bg-muted flex flex-col items-center justify-center gap-2 text-muted-foreground transition-colors active:bg-muted/70"
                >
                  <ImagePlus className="h-6 w-6" fill="currentColor" strokeWidth={0} />
                  <span className="text-xs font-medium">Add thumbnail image</span>
                </button>
              )}
            </div>

            <button
              onClick={() => setStep(2)}
              disabled={!isStep1Valid}
              className="w-full h-13 rounded-xl bg-primary text-primary-foreground font-bold text-sm tracking-wide flex items-center justify-center gap-2 transition-opacity active:opacity-80 disabled:opacity-40"
            >
              Continue to Body
            </button>
          </>
        )}

        {step === 2 && (
          <>
            <div className="flex items-center gap-3 mb-2">
              <button
                onClick={() => setStep(1)}
                className="text-xs text-primary font-medium"
              >
                ← Back
              </button>
              <span className="text-sm font-semibold text-foreground truncate">{title}</span>
            </div>

            {/* Body */}
            <div className="space-y-2">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Article Body *</label>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Write your full article here. You can use markdown for formatting..."
                rows={16}
                className="w-full rounded-xl bg-card border border-border px-4 py-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary transition-all resize-none leading-relaxed"
              />
              <p className="text-right text-[10px] text-muted-foreground">{body.length} chars</p>
            </div>

            {/* AI info callout */}
            <div className="rounded-xl border border-primary/20 bg-primary/5 p-3 space-y-1">
              <p className="text-xs font-semibold text-primary">AI analysis on publish</p>
              <p className="text-[11px] text-muted-foreground leading-relaxed">
                Once published, your article will be automatically analyzed by our Ollama LLM for bias detection and fact-check scoring. Badges will appear within 2 minutes.
              </p>
            </div>

            <button
              onClick={handlePublish}
              disabled={body.length < 50 || publishing}
              className="w-full h-13 rounded-xl bg-primary text-primary-foreground font-bold text-sm tracking-wide flex items-center justify-center gap-2 transition-opacity active:opacity-80 disabled:opacity-40"
            >
              {publishing ? (
                <><Loader2 className="h-4 w-4 animate-spin" fill="currentColor" strokeWidth={0} /> Publishing...</>
              ) : (
                "Publish Article"
              )}
            </button>
          </>
        )}
      </div>
    </div>
  )
}

"use client"

import { cn } from "@/lib/utils"
import { Home, Compass, PenLine, User } from "lucide-react"

export type Screen = "feed" | "explore" | "publish" | "profile"

interface BottomNavProps {
  active: Screen
  onNavigate: (screen: Screen) => void
}

const NAV_ITEMS: { id: Screen; label: string; Icon: React.ElementType }[] = [
  { id: "feed", label: "Feed", Icon: Home },
  { id: "explore", label: "Explore", Icon: Compass },
  { id: "publish", label: "Publish", Icon: PenLine },
  { id: "profile", label: "Profile", Icon: User },
]

export function BottomNav({ active, onNavigate }: BottomNavProps) {
  return (
    <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-sm z-50 border-t border-border bg-card/95 backdrop-blur-md">
      <div className="flex items-center justify-around px-2 py-2 pb-safe">
        {NAV_ITEMS.map(({ id, label, Icon }) => {
          const isActive = active === id
          const isPublish = id === "publish"
          return (
            <button
              key={id}
              onClick={() => onNavigate(id)}
              aria-label={label}
              className={cn(
                "flex flex-col items-center gap-1 px-4 py-1.5 rounded-xl transition-all",
                isActive && !isPublish && "text-primary",
                !isActive && !isPublish && "text-muted-foreground",
                isPublish &&
                  "bg-primary text-primary-foreground rounded-2xl px-5 py-2.5 -mt-5 shadow-lg shadow-primary/30 border border-primary/30"
              )}
            >
              <Icon className={cn("h-5 w-5", isPublish && "h-5 w-5")} fill="currentColor" strokeWidth={0} />
              <span className={cn("text-[10px] font-semibold uppercase tracking-wider leading-none", isPublish && "hidden")}>
                {label}
              </span>
              {isActive && !isPublish && (
                <span className="absolute -bottom-0 h-0.5 w-5 rounded-full bg-primary" />
              )}
            </button>
          )
        })}
      </div>
    </nav>
  )
}

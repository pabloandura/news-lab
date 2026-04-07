"use client"

import { useState } from "react"
import { SignInScreen } from "@/components/news-lab/screens/sign-in-screen"
import { HomeFeedScreen } from "@/components/news-lab/screens/home-feed-screen"
import { ArticleDetailScreen } from "@/components/news-lab/screens/article-detail-screen"
import { ExploreScreen } from "@/components/news-lab/screens/explore-screen"
import { PublishScreen } from "@/components/news-lab/screens/publish-screen"
import { ProfileScreen } from "@/components/news-lab/screens/profile-screen"
import { BottomNav, type Screen } from "@/components/news-lab/bottom-nav"
import { type Article } from "@/components/news-lab/article-card"

type AppState =
  | { view: "signin" }
  | { view: "feed" }
  | { view: "article"; article: Article; from: Screen }
  | { view: "explore" }
  | { view: "publish" }
  | { view: "profile" }

export default function NewsLabApp() {
  const [state, setState] = useState<AppState>({ view: "signin" })
  const [activeNav, setActiveNav] = useState<Screen>("feed")

  function handleSignIn() {
    setState({ view: "feed" })
    setActiveNav("feed")
  }

  function handleSignOut() {
    setState({ view: "signin" })
  }

  function handleArticleClick(article: Article) {
    setState({ view: "article", article, from: activeNav })
  }

  function handleBackFromArticle() {
    if (state.view === "article") {
      const from = state.from
      setActiveNav(from)
      setState({ view: from })
    }
  }

  function handleNavigation(screen: Screen) {
    setActiveNav(screen)
    setState({ view: screen })
  }

  const showBottomNav = state.view !== "signin" && state.view !== "article"

  return (
    // Mobile shell: centered, max-w-sm, fills viewport height
    <div className="min-h-screen bg-[oklch(0.07_0.005_260)] flex items-start justify-center">
      <div className="relative w-full max-w-sm min-h-screen bg-background overflow-hidden shadow-2xl">

        {state.view === "signin" && (
          <SignInScreen onSignIn={handleSignIn} />
        )}

        {state.view === "feed" && (
          <HomeFeedScreen onArticleClick={handleArticleClick} />
        )}

        {state.view === "article" && (
          <ArticleDetailScreen
            article={state.article}
            onBack={handleBackFromArticle}
            onArticleClick={handleArticleClick}
          />
        )}

        {state.view === "explore" && (
          <ExploreScreen onArticleClick={handleArticleClick} />
        )}

        {state.view === "publish" && (
          <PublishScreen onPublished={() => handleNavigation("feed")} />
        )}

        {state.view === "profile" && (
          <ProfileScreen
            onSignOut={handleSignOut}
            onArticleClick={handleArticleClick}
          />
        )}

        {showBottomNav && (
          <BottomNav active={activeNav} onNavigate={handleNavigation} />
        )}
      </div>
    </div>
  )
}

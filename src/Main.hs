{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Monad ((>=>))
import Data.List (isSuffixOf)
import Hakyll
import Mooneghan.Contexts
import System.FilePath (takeBaseName, takeFileName, (</>))
import Text.Pandoc.Highlighting (Style, breezeDark, espresso, haddock, kate, pygments, styleToCss, tango, zenburn)
import Text.Pandoc.Options (WriterOptions (writerHighlightStyle))

main :: IO ()
main =
    hakyll cfmoonRules

feedConfiguration :: FeedConfiguration
feedConfiguration =
    FeedConfiguration
        { feedTitle = "The Aleph Project"
        , feedDescription = "Musings on software and life."
        , feedAuthorName = "Catrin &amp; Fabrizio"
        , feedAuthorEmail = "fabricus@cfmoon.net" -- Update this, cariad
        , feedRoot = "https://cfmoon.net" -- Update this to the real URL
        }

-- | Rules for our blog, Catrin-style
cfmoonRules :: Rules ()
cfmoonRules = do
    match "static/images/**" $
        route idRoute
            >> compile copyFileCompiler
    match "static/css/*" $
        route idRoute >> compile compressCssCompiler

    match "static/assets/robots.txt" $ do
        route cleanRobots
        compile copyFileCompiler
    -- create ["static/css/syntax.css"] $ do
    --     route idRoute
    --     compile $ do
    --         makeItem $ styleToCss zenburn

    match "posts/*" $ do
        route cleanRoute
        compile $
            pandocCompiler
                >>= loadAndApplyTemplate "templates/post.html" postCtx
                >>= saveSnapshot "content"
                >>= loadAndApplyTemplate "templates/default.html" postCtx
                >>= cleanInnerUrls
                >>= relativizeUrls

    create ["index.html"] $ do
        route idRoute
        compile $
            makeItem ""
                >>= loadAndApplyTemplate "templates/index-template.html" (postListCtx indexCtx)
                >>= loadAndApplyTemplate "templates/default.html" (postListCtx indexCtx)
                >>= cleanInnerUrls
                >>= relativizeUrls

    create ["musings.html"] $ do
        route cleanRoute
        compile $
            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" (postListCtx archiveCtx)
                >>= loadAndApplyTemplate "templates/default.html" (postListCtx archiveCtx)
                >>= cleanInnerUrls
                >>= relativizeUrls
    -- Render the Atom Feed
    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx =
                    modificationTimeField "updated" "%Y-%m-%dT%H:%M:%SZ"
                        `mappend` teaserField "summary" "content" -- Creates a $teaser$ field
                        `mappend` bodyField "description" -- Creates a $description$ field (full body)
                        `mappend` postCtx
            posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots "posts/*" "content"
            feedTpl <- loadBody "templates/my-atom.xml"
            itemTpl <- loadBody "templates/my-atom-item.xml"
            renderAtomWithTemplates feedTpl itemTpl feedConfiguration feedCtx posts

    -- Render the Sitemap
    create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let sitemapCtx =
                    constField "domain" "https://cfmoon.net"
                        `mappend` listField "posts" (postCtx `mappend` dateField "mDate" "%Y-%m-%d" `mappend` sitemapCtx) (return posts)
            makeItem ""
                >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
    match "templates/*" $ compile templateBodyCompiler

cleanInnerUrls :: Item String -> Compiler (Item String)
cleanInnerUrls = return . fmap (withUrls cleanIndex)
  where
    idx = "index.html"
    cleanIndex url
        | idx `isSuffixOf` url = take (length url - length idx) url
        | otherwise = url

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeBaseName (toFilePath ident) </> "index.html"

cleanRobots = customRoute createRobotsRoute
  where
    createRobotsRoute id = takeFileName (toFilePath id)

-- Post list context
postListCtx :: Context String -> Context String
postListCtx customCtx =
    listField "posts" postCtx (recentFirst =<< loadAll "posts/*")
        <> customCtx

-- | Helper combinators - COMPOSITION HEAVEN
makeArchive :: [Item String] -> Compiler (Item String)
makeArchive posts =
    let ctx =
            listField "posts" postCtx (return posts)
                `mappend` (constField "title" "The Archive" `mappend` mooneghanCtx)
     in makeItem ""
            >>= loadAndApplyTemplate "templates/archive.html" ctx
            >>= loadAndApplyTemplate "templates/default.html" ctx

applyDefaultTemplates :: Item String -> Compiler (Item String)
applyDefaultTemplates =
    loadAndApplyTemplate "templates/default.html" mooneghanCtx

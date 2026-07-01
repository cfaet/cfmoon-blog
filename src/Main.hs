{-# LANGUAGE OverloadedStrings #-}

import Hakyll
import Mooneghan.Contexts
import System.FilePath (takeBaseName, takeFileName, (</>))

main :: IO ()
main =
    hakyll cfmoonRules

feedConfiguration :: FeedConfiguration
feedConfiguration =
    FeedConfiguration
        { feedTitle = "The Aleph Project"
        , feedDescription = "Musings on software and life."
        , feedAuthorName = "CFMoon Tech"
        , feedAuthorEmail = "fabricus@cfmoon.net"
        , feedRoot = siteRoot
        }

cfmoonRules :: Rules ()
cfmoonRules = do
    match "static/images/**" $
        route idRoute
            >> compile copyFileCompiler
    match "static/css/*" $
        route idRoute >> compile compressCssCompiler
    match "static/js/**" $
        route idRoute
            >> compile copyFileCompiler

    match "static/assets/robots.txt" $ do
        route cleanRobots
        compile $ getResourceString >>= applyAsTemplate mooneghanCtx

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
    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx =
                    updatedDateTimeField "updated"
                        <> modificationTimeField "updated" "%Y-%m-%dT%H:%M:%SZ"
                        <> teaserField "summary" "content"
                        <> bodyField "description"
                        <> postCtx
            posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots "posts/*" "content"
            feedTpl <- loadBody "templates/my-atom.xml"
            itemTpl <- loadBody "templates/my-atom-item.xml"
            renderAtomWithTemplates feedTpl itemTpl feedConfiguration feedCtx posts

    create ["sitemap.xml"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let postSitemapCtx =
                    constField "domain" siteRoot
                        <> updatedDateIsoField "mDate"
                        <> postCtx
                sitemapCtx =
                    constField "domain" siteRoot
                        <> listField "posts" postSitemapCtx (return posts)
            makeItem ("" :: String)
                >>= loadAndApplyTemplate "templates/sitemap.xml" sitemapCtx
    match "templates/*" $ compile templateBodyCompiler

cleanInnerUrls :: Item String -> Compiler (Item String)
cleanInnerUrls = return . fmap (withUrls cleanIndexUrl)

cleanRoute :: Routes
cleanRoute = customRoute createIndexRoute
  where
    createIndexRoute ident = takeBaseName (toFilePath ident) </> "index.html"

cleanRobots :: Routes
cleanRobots = customRoute createRobotsRoute
  where
    createRobotsRoute ident = takeFileName (toFilePath ident)

postListCtx :: Context String -> Context String
postListCtx customCtx =
    listField "posts" postCtx (recentFirst =<< loadAll "posts/*")
        <> customCtx

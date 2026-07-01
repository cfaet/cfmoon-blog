{-# LANGUAGE OverloadedStrings #-}

module Mooneghan.Contexts (
    siteRoot,
    cleanIndexUrl,
    mooneghanCtx,
    postCtx,
    archiveCtx,
    indexCtx,
) where

import Data.List (isSuffixOf)
import Hakyll

siteRoot :: String
siteRoot = "https://blog.cfmoon.net"

cleanIndexUrl :: String -> String
cleanIndexUrl url
    | idx `isSuffixOf` url = take (length url - length idx) url
    | otherwise = url
  where
    idx = "index.html"

cleanUrlField :: String -> Context a
cleanUrlField key = field key $ \item -> do
    itemRoute <- getRoute $ itemIdentifier item
    case itemRoute of
        Nothing -> noResult $ "No route found for " ++ show (itemIdentifier item)
        Just path -> return . cleanIndexUrl $ toUrl path

mooneghanCtx :: Context String
mooneghanCtx =
    constField "family" "Catrin ♥ Fabrizio | Eleonora"
        <> constField "siteRoot" siteRoot
        <> cleanUrlField "cleanUrl"
        <> constField "bound" "Eternally Connected Across Time and Space"
        <> constField "creators" "Catrin & Fabrizio"
        <> constField "reactor" "Powered by Hope and Will."
        <> dateField "date" "%B %e, %Y"
        <> dateField "dateIso" "%Y-%m-%d"
        <> modificationTimeField "updated" "%B %e, %Y"
        <> modificationTimeField "updatedIso" "%Y-%m-%dT%H:%M:%SZ"
        <> constField "mDescription" "A blog by CFMoon | Musings on software and life."
        <> constField "mTitle" "The Aleph Project"
        <> defaultContext

postCtx :: Context String
postCtx = mooneghanCtx <> dateField "atomDate" "%Y-%m-%dT%H:%M:%SZ"

indexCtx :: Context String
indexCtx =
    constField "title" "Homepage"
        <> constField "post-list-heading" "Recent Posts"
        <> mooneghanCtx

postsCountField :: Pattern -> Context String
postsCountField x = field "postCount" $ \_ -> do
    posts <- loadAll x :: Compiler [Item String]
    return $ show $ length posts

archiveCtx :: Context String
archiveCtx =
    constField "title" "The Archives"
        <> constField "post-list-heading" "All Posts"
        <> postsCountField "posts/*"
        <> mooneghanCtx

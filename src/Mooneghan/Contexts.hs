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
import Data.Char (isSpace)
import qualified Data.List as List
import Hakyll

siteRoot :: String
siteRoot = "https://blog.cfmoon.net"

siteTitle :: String
siteTitle = "The Aleph Project"

siteDescription :: String
siteDescription = "A blog by CFMoon | Musings on software and life."

fallbackMetaImage :: String
fallbackMetaImage = siteRoot ++ "/static/images/og-image-v2.png"

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

stripWhitespace :: String -> String
stripWhitespace = dropWhileEnd isSpace . dropWhile isSpace
  where
    dropWhileEnd predicate = reverse . dropWhile predicate . reverse

metadataValue :: Identifier -> [String] -> Compiler (Maybe String)
metadataValue _ [] = return Nothing
metadataValue ident (key : keys) = do
    value <- getMetadataField ident key
    case stripWhitespace <$> value of
        Just x | not (null x) -> return $ Just x
        _ -> metadataValue ident keys

absoluteUrl :: String -> String
absoluteUrl rawPath
    | "https://" `List.isPrefixOf` path = path
    | "http://" `List.isPrefixOf` path = path
    | "/" `List.isPrefixOf` path = siteRoot ++ path
    | otherwise = siteRoot ++ "/" ++ dropRelativePrefix path
  where
    path = stripWhitespace rawPath

    dropRelativePrefix p
        | "../" `List.isPrefixOf` p = dropRelativePrefix $ drop 3 p
        | "./" `List.isPrefixOf` p = dropRelativePrefix $ drop 2 p
        | otherwise = p

siteMetaCtx :: Context String
siteMetaCtx =
    constField "metaTitle" siteTitle
        <> constField "metaDescription" siteDescription
        <> constField "metaImage" fallbackMetaImage
        <> constField "metaImageAlt" siteDescription
        <> constField "metaType" "website"

postMetaCtx :: Context String
postMetaCtx =
    constField "metaType" "article"
        <> constField "isArticle" "true"
        <> field "metaTitle" postTitle
        <> field "metaDescription" postDescription
        <> field "metaImage" postImage
        <> field "metaImageAlt" postImageAlt
  where
    postTitle item = do
        title <- metadataValue (itemIdentifier item) ["title"]
        return $ maybe siteTitle (\x -> siteTitle ++ " - " ++ x) title

    postDescription item =
        metadataValue (itemIdentifier item) ["description", "subtitle"]
            >>= return . maybe siteDescription id

    postImage item =
        metadataValue (itemIdentifier item) ["image"]
            >>= return . maybe fallbackMetaImage absoluteUrl

    postImageAlt item =
        metadataValue (itemIdentifier item) ["imageAlt", "subtitle", "title"]
            >>= return . maybe siteDescription id

mooneghanCtx :: Context String
mooneghanCtx =
    constField "family" "Catrin ♥ Fabrizio | Eleonora"
        <> constField "siteRoot" siteRoot
        <> siteMetaCtx
        <> cleanUrlField "cleanUrl"
        <> constField "bound" "Eternally Connected Across Time and Space"
        <> constField "creators" "Catrin & Fabrizio"
        <> constField "reactor" "Powered by Hope and Will."
        <> dateField "date" "%B %e, %Y"
        <> dateField "dateIso" "%Y-%m-%d"
        <> modificationTimeField "updated" "%B %e, %Y"
        <> modificationTimeField "updatedIso" "%Y-%m-%dT%H:%M:%SZ"
        <> constField "mDescription" siteDescription
        <> constField "mTitle" siteTitle
        <> defaultContext

postCtx :: Context String
postCtx =
    postMetaCtx
        <> mooneghanCtx
        <> dateField "atomDate" "%Y-%m-%dT%H:%M:%SZ"

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
        <> constField "metaTitle" (siteTitle ++ " - The Archives")
        <> constField "post-list-heading" "All Posts"
        <> postsCountField "posts/*"
        <> mooneghanCtx

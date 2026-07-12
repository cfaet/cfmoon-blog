{-# LANGUAGE OverloadedStrings #-}

module Mooneghan.Contexts (
    siteRoot,
    cleanIndexUrl,
    mooneghanCtx,
    postCtx,
    updatedDateField,
    updatedDateIsoField,
    updatedDateTimeField,
    archiveCtx,
    indexCtx,
) where

import Data.Char (isDigit, isSpace, toLower)
import Data.List (intercalate, isSuffixOf)
import qualified Data.List as List
import Hakyll
import Text.Blaze.Html.Renderer.String (renderHtml)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import Text.Read (readMaybe)

siteRoot :: String
siteRoot = "https://blog.cfmoon.net"

siteTitle :: String
siteTitle = "The Aleph Project"

siteDescription :: String
siteDescription = "A blog by CFMoon Tech | Musings on software and life."

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

data MetadataDate = MetadataDate
    { metadataYear :: String
    , metadataMonth :: Int
    , metadataDay :: Int
    }

metadataUpdatedDate :: Identifier -> Compiler MetadataDate
metadataUpdatedDate ident = do
    value <- metadataValue ident ["updated", "date"]
    case value >>= parseMetadataDate of
        Just parsedDate -> return parsedDate
        Nothing -> noResult $ "Expected updated/date metadata as YYYY-MM-DD for " ++ show ident

parseMetadataDate :: String -> Maybe MetadataDate
parseMetadataDate value = do
    let (year, rest) = splitAt 4 value
        (month, dayWithDash) = splitAt 2 $ drop 1 rest
        day = drop 1 dayWithDash
    if length value == 10
        && all isDigit year
        && take 1 rest == "-"
        && all isDigit month
        && take 1 dayWithDash == "-"
        && all isDigit day
        then do
            monthNumber <- readMaybe month
            dayNumber <- readMaybe day
            if monthNumber >= 1 && monthNumber <= 12 && dayNumber >= 1 && dayNumber <= 31
                then
                    return
                        MetadataDate
                            { metadataYear = year
                            , metadataMonth = monthNumber
                            , metadataDay = dayNumber
                            }
                else Nothing
        else Nothing

monthName :: Int -> String
monthName month =
    [ "January"
    , "February"
    , "March"
    , "April"
    , "May"
    , "June"
    , "July"
    , "August"
    , "September"
    , "October"
    , "November"
    , "December"
    ]
        !! (month - 1)

formatMetadataDate :: MetadataDate -> String
formatMetadataDate metadataDate =
    metadataYear metadataDate
        ++ "-"
        ++ pad2 (metadataMonth metadataDate)
        ++ "-"
        ++ pad2 (metadataDay metadataDate)
  where
    pad2 n
        | n < 10 = "0" ++ show n
        | otherwise = show n

formatDisplayDate :: MetadataDate -> String
formatDisplayDate metadataDate =
    monthName (metadataMonth metadataDate)
        ++ " "
        ++ show (metadataDay metadataDate)
        ++ ", "
        ++ metadataYear metadataDate

updatedDateFieldWith :: String -> (MetadataDate -> String) -> Context String
updatedDateFieldWith key formatter = field key $ \item ->
    formatter <$> metadataUpdatedDate (itemIdentifier item)

updatedDateField :: String -> Context String
updatedDateField key = updatedDateFieldWith key formatDisplayDate

updatedDateIsoField :: String -> Context String
updatedDateIsoField key = updatedDateFieldWith key formatMetadataDate

updatedDateTimeField :: String -> Context String
updatedDateTimeField key = updatedDateFieldWith key $ \metadataDate ->
    formatMetadataDate metadataDate ++ "T00:00:00Z"

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

tagSlug :: String -> String
tagSlug = intercalate "-" . words . map toLower . stripWhitespace

tagsForItem :: Item a -> Compiler [String]
tagsForItem = getTags . itemIdentifier

nonEmptyTagsField :: String -> ([String] -> String) -> Context a
nonEmptyTagsField key formatter = field key $ \item -> do
    tags <- tagsForItem item
    case tags of
        [] -> noResult $ "No tags for " ++ show (itemIdentifier item)
        _ -> return $ formatter tags

tagChipsField :: String -> Context a
tagChipsField key = nonEmptyTagsField key $ renderHtml . mapM_ tagChip
  where
    tagChip tag =
        H.span
            ! A.class_ "post-tag-chip"
            ! H.dataAttribute "tag-slug" (H.toValue $ tagSlug tag)
            $ H.toHtml tag

articleTagsMetaField :: String -> Context a
articleTagsMetaField key = nonEmptyTagsField key $ renderHtml . mapM_ articleTagMeta
  where
    articleTagMeta tag =
        H.meta
            ! A.property "article:tag"
            ! A.content (H.toValue tag)

metaKeywordsField :: String -> Context a
metaKeywordsField key = nonEmptyTagsField key $ intercalate ", "

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
        <> tagChipsField "tagChips"
        <> articleTagsMetaField "articleTagsMeta"
        <> metaKeywordsField "metaKeywords"
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
        <> updatedDateField "updated"
        <> updatedDateTimeField "updatedIso"
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

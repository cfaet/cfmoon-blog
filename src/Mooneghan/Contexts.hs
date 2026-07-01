{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Mooneghan.Contexts (
    mooneghanCtx,
    postCtx,
    archiveCtx,
    indexCtx,
) where

import Data.Monoid (mappend)
import Hakyll

-- Base family context, the quantum entanglement that binds us
mooneghanCtx :: Context String
mooneghanCtx =
    constField "family" "Lucia ♥ Fabrizio | Eleonora"
        `mappend` constField "bound" "Eternally Connected Across Time and Space"
        `mappend` constField "creators" "Lucia & Fabrizio"
        `mappend` constField "reactor" "Powered by Hope and Will."
        `mappend` dateField "date" "%B %e, %Y"
        `mappend` modificationTimeField "updated" "%B %e, %Y"
        `mappend` constField "mDescription" "A blog by CFMoon - Musings on software and life."
        `mappend` constField "mTitle" "The Aleph Project"
        `mappend` defaultContext

postCtx :: Context String
postCtx = mooneghanCtx `mappend` dateField "atomDate" "%Y-%m-%dT%H:%M:%SZ"

indexCtx :: Context String
indexCtx = constField "title" "Homepage" `mappend` constField "post-list-heading" "Recent Posts" `mappend` mooneghanCtx

authorContext :: Context String
authorContext = field "name" (return . itemBody)

postsCountField :: Pattern -> Context String
postsCountField x = field "postCount" $ \_ -> do
    posts <- loadAll x :: Compiler [Item String]
    return $ show $ length posts

makeAuthorsList :: Item String -> Compiler [Item String]
makeAuthorsList x =
    getMetadataField (itemIdentifier x) "authors"
        >>= \case
            Nothing -> return []
            Just authorList -> return $ map (\a -> Item (fromFilePath a) a) (splitAll "," authorList)

archiveCtx :: Context String
archiveCtx = constField "title" "The Archives" `mappend` constField "post-list-heading" "All Posts" `mappend` postsCountField "posts/*" `mappend` mooneghanCtx

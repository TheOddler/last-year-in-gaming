module Game exposing (..)

import Html exposing (Html, a, div, img, li, text, ul)
import Html.Attributes exposing (height, href, src)
import Json.Decode exposing (Decoder, nullable, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Maybe.Extra exposing (values)


type alias Game =
    { name : String
    , description : Maybe String
    , cover : Maybe String
    , url : Maybe String
    , itch : Maybe String
    , steam : Maybe String
    , gog : Maybe String
    , epicGames : Maybe String
    , igdb : Maybe String
    }


decoder : Decoder Game
decoder =
    let
        optionalNullable key dec =
            optional key (nullable dec) Nothing
    in
    succeed Game
        |> required "name" string
        |> optionalNullable "description" string
        |> optionalNullable "cover" string
        |> optionalNullable "url" string
        |> optionalNullable "itch" string
        |> optionalNullable "steam" string
        |> optionalNullable "gog" string
        |> optionalNullable "epic_games" string
        |> optionalNullable "igdb" string


view : Game -> Html msg
view game =
    let
        maybeTextDiv maybeText =
            Maybe.map (\t -> div [] [ text t ]) maybeText

        maybeLiA label maybeUrl =
            Maybe.map (\u -> li [] [ a [ href u ] [ text label ] ]) maybeUrl
    in
    div [] <|
        values
            [ Maybe.map (\s -> img [ src s, height 302 ] []) game.cover
            , Just <| div [] [ text game.name ]
            , maybeTextDiv game.description
            , Just <|
                ul [] <|
                    values
                        [ maybeLiA game.name game.url
                        , maybeLiA "itch.io" game.itch
                        , maybeLiA "Steam" game.steam
                        , maybeLiA "GOG" game.gog
                        , maybeLiA "Epic Games" game.epicGames
                        , maybeLiA "IGDB" game.igdb
                        ]
            ]

module Game exposing (..)

import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (class, href, src)
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
        viewGameUrl label maybeUrl =
            Maybe.map
                (\u -> a [ href u, class "url" ] [ text label ])
                maybeUrl
    in
    div [ class "game" ] <|
        values
            [ Maybe.map (\s -> img [ src s, class "cover" ] []) game.cover
            , Just <| div [ class "name" ] [ text game.name ]
            , Maybe.map (\t -> div [ class "description" ] [ text t ]) game.description
            , Just <|
                div [ class "urls" ] <|
                    values
                        [ viewGameUrl game.name game.url
                        , viewGameUrl "itch.io" game.itch
                        , viewGameUrl "Steam" game.steam
                        , viewGameUrl "GOG" game.gog
                        , viewGameUrl "Epic Games" game.epicGames
                        , viewGameUrl "IGDB" game.igdb
                        ]
            ]

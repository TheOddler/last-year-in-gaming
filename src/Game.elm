module Game exposing (Game, decoder, sortFilterByRating, view)

import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (class, href, src)
import Json.Decode exposing (Decoder, int, nullable, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Maybe.Extra exposing (isJust, values)


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
    , rating : Maybe Int
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
        |> optionalNullable "rating" int


view : Game -> Html msg
view game =
    let
        viewGameUrl label maybeUrl =
            Maybe.map
                (\u -> a [ href u, class "url" ] [ text label ])
                maybeUrl

        maybeCover =
            Maybe.map (\s -> img [ src s, class "cover" ] []) game.cover

        info =
            values
                [ Just <| div [ class "name" ] [ text game.name ]
                , Maybe.map (\t -> div [ class "description" ] [ text t ]) game.description
                , Just <|
                    div [ class "urls" ] <|
                        values
                            [ viewGameUrl "Official Website" game.url
                            , viewGameUrl "itch.io" game.itch
                            , viewGameUrl "Steam" game.steam
                            , viewGameUrl "GOG" game.gog
                            , viewGameUrl "Epic Games" game.epicGames
                            , viewGameUrl "IGDB" game.igdb
                            ]
                ]
    in
    div [ class "game" ] <|
        case maybeCover of
            Just cover ->
                cover :: info

            Nothing ->
                info


smartRating : Game -> Int
smartRating game =
    let
        whenJust m x =
            if isJust m then
                Just x

            else
                Nothing

        -- Since GOG and Epic are curated stores, we assume a certain level of quality for them
        gogRating =
            whenJust game.gog 80

        epicRating =
            whenJust game.epicGames 80

        ratings =
            values [ game.rating, gogRating, epicRating ]
    in
    List.sum ratings // List.length ratings


sortFilterByRating : List Game -> List Game
sortFilterByRating games =
    games
        |> List.map withSmartRating
        |> List.filter (\( rating, _ ) -> rating > 0)
        |> List.sortWith (\( r1, _ ) ( r2, _ ) -> desc r1 r2)
        |> List.map (\( _, game ) -> game)


withSmartRating : Game -> ( Int, Game )
withSmartRating game =
    ( smartRating game, game )


desc : comparable -> comparable -> Order
desc a b =
    case compare a b of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT

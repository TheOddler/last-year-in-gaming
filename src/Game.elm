module Game exposing (..)

import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (href, src)
import Json.Decode as Decode


type alias Game =
    { name : String
    , summary : String
    , url : String
    , coverUrl : Maybe String
    }


decoder : Decode.Decoder Game
decoder =
    Decode.map4 Game
        (Decode.field "name" Decode.string)
        (Decode.field "summary" Decode.string)
        (Decode.field "url" Decode.string)
        (Decode.maybe <| Decode.field "cover_url" Decode.string)


view : Game -> Html msg
view game =
    div []
        [ img [ src <| Maybe.withDefault "" game.coverUrl ] []
        , div [] [ text game.name ]
        , div [] [ text game.summary ]
        , a [ href game.url ] [ text game.url ]
        ]

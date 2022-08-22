module Main exposing (..)

import Browser
import Date exposing (Date)
import DecodeExtra
import Game exposing (Game)
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class)
import Http
import Json.Decode as Decode
import Task


type Model
    = Loading
    | Done (List Game)
    | Error String String


type Msg
    = SetDate Date
    | SetGames (Result Http.Error String)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , Cmd.batch
        [ Task.perform SetDate Date.getTodayLastYear
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        SetDate date ->
            ( Loading
            , Http.get
                { url = "data/" ++ Date.toString date ++ ".json"
                , expect = Http.expectString SetGames
                }
            )

        SetGames errorOrJson ->
            case errorOrJson of
                Err err ->
                    ( Error "Failed getting games" <| httpErrorToString err, Cmd.none )

                Ok json ->
                    case Decode.decodeString (DecodeExtra.listSafe Game.decoder) json of
                        Err err ->
                            ( Error "Failed decoding games" <| Decode.errorToString err, Cmd.none )

                        Ok games ->
                            ( Done games, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            div [] [ text "Loading" ]

        Done games ->
            div []
                [ h1 [ class "title" ]
                    [ text <| "Games release exactly one year ago:"
                    ]
                , div
                    [ class "games" ]
                  <|
                    List.map Game.view games
                ]

        Error title message ->
            div [] [ text title, text message ]


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Bad url: " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus status ->
            "Bad status: " ++ String.fromInt status

        Http.BadBody body ->
            "Bad body: " ++ body

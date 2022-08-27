module Main exposing (main)

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
    | Running (List Game) (List Error)


type alias Error =
    { title : String
    , message : String
    }


type Msg
    = Reset Date
    | AddGames (Result Http.Error String)


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
        [ Task.perform Reset Date.today
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reset today ->
            let
                weekStart =
                    Date.add Date.Years -1 <| Date.floor Date.Week today

                weekDays =
                    [ weekStart
                    , Date.add Date.Days 1 weekStart
                    , Date.add Date.Days 2 weekStart
                    , Date.add Date.Days 3 weekStart
                    , Date.add Date.Days 4 weekStart
                    , Date.add Date.Days 5 weekStart
                    , Date.add Date.Days 6 weekStart
                    ]

                getGamesForDate date =
                    Http.get
                        { url = "data/" ++ Date.toIsoString date ++ ".json"
                        , expect = Http.expectString AddGames
                        }
            in
            ( Loading
            , Cmd.batch <| List.map getGamesForDate weekDays
            )

        AddGames errorOrJson ->
            case errorOrJson of
                Err httpErr ->
                    let
                        err =
                            { title = "Failed downloading games json"
                            , message = httpErrorToString httpErr
                            }
                    in
                    ( addError err model, Cmd.none )

                Ok json ->
                    case Decode.decodeString (DecodeExtra.listSafe Game.decoder) json of
                        Err decodeErr ->
                            let
                                err =
                                    { title = "Failed decoding games json"
                                    , message = Decode.errorToString decodeErr
                                    }
                            in
                            ( addError err model, Cmd.none )

                        Ok newGames ->
                            case model of
                                Loading ->
                                    ( Running newGames [], Cmd.none )

                                Running games errors ->
                                    ( Running (List.append newGames games) errors, Cmd.none )


addError : Error -> Model -> Model
addError err model =
    case model of
        Loading ->
            Running [] [ err ]

        Running games errors ->
            Running games (err :: errors)


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            div [] [ text "Loading" ]

        Running games errors ->
            div []
                [ h1 [ class "title" ]
                    [ text <| "Games release this week one year ago:"
                    ]
                , div
                    [ class "games" ]
                  <|
                    List.map Game.view (Game.sortFilterByRating games)
                , div
                    [ class "errors" ]
                  <|
                    List.map viewError errors
                ]


viewError : Error -> Html Msg
viewError err =
    div [] [ text err.title, text ": ", text err.message ]


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

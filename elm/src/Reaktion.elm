module Reaktion exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Random
import Process
import Task
import Time exposing (..)
import Point exposing (..)
import Debug exposing (log)
import Utils exposing (..)

main =
  Browser.element
    { init = init , update = update , subscriptions = subscriptions , view = view}


type alias Model = { showAfter: Maybe Int
                   , startedAt: Maybe Int
                   , clickedAt: Maybe Int
                   , duration:  Maybe Int
                   , point:     Maybe Point
                   , showPoint: Bool
                   , game:      Int
                   , durations: List Int
                   , avg:       Maybe Int
                   }

initialModel : Model
initialModel =
    { showAfter = Nothing
    , startedAt = Nothing
    , clickedAt = Nothing
    , duration  = Nothing
    , point     = Nothing
    , showPoint = False
    , game      = 1
    , durations = []
    , avg       = Nothing
    }


startCmd : Cmd Msg
startCmd =
    Cmd.batch
        [ Task.perform    SetStartedAt Time.now
        , Random.generate SetPoint     (Random.pair (Random.int 0 10) (Random.int 0 20))
        , Random.generate SetShowAfter (Random.int 500 2000)
        ]

type Msg
  = Start
  | NextGame  Time.Posix
  | SetStartedAt  Time.Posix
  | SetShowAfter  Int
  | SetPoint      (Int, Int)
  | ShowPoint
  | PointMsg      Point.Msg


init : () -> (Model, Cmd Msg)
init _ = ( initialModel, Cmd.none )


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Start ->
        ( initialModel
        , startCmd )

    SetShowAfter showAfter ->
        ({ model | showAfter = Just showAfter }
        , after showAfter ShowPoint )

    NextGame time ->
        let
            clickedAt = Just <| Time.posixToMillis time
            -- here startedAt and showAfter must be not Nothing
            duration = (Maybe.map3 (\a b c -> a - b - c) clickedAt model.startedAt model.showAfter) |> Maybe.withDefault(0)
            durations = duration :: model.durations
            sum = durations |> List.sum |> toFloat

        in
            ( { initialModel |
                    clickedAt = clickedAt,
                    duration = Just duration,
                    game = model.game + 1,
                    durations = durations,
                    avg = Just <| (sum / (toFloat model.game) |> round)
              }
            , startCmd
            )

    SetStartedAt time ->
        ({ model | startedAt = Just <| Time.posixToMillis time }
        , Cmd.none)

    SetPoint (x, y) ->
        ({ model | point = Just (Point x y)}
        , Cmd.none )

    ShowPoint ->
        ({ model | showPoint = True }
        , Cmd.none )

    PointMsg Point.Clicked ->
        ( model
        , Task.perform NextGame Time.now
        )

divClass : String -> List (Html Msg) -> Html Msg
divClass  c content =
    div [ class c ] content


subscriptions : Model -> Sub Msg
subscriptions model = Sub.none


col : List (Html Msg) -> Html Msg
col  content = divClass "col" content

row : List (Html Msg) -> Html Msg
row  content = divClass "row" content

container : List (Html Msg) -> Html Msg
container  content = divClass "container" content


view : Model -> Html Msg
view model =
    div [ class "container"]
        [ div [ class "row mt-5" ]
            [ col [ button [ onClick Start ] [ text "Start" ]
                  , div [ class "mt-5"] []
                  , viewProperties model
                  , viewField model
                  ]
            , col [ viewResult model ]
            ]
        ]


viewProperties : Model -> Html Msg
viewProperties model =
    propertiesTable
          [( text "Runde: "
            , text <| String.fromInt model.game
            )
          , ( text "Zeit (msecs) "
            , text <| viewInt model.duration)

          , ( text "Zeit (Durchschn.)(msecs): "
            , text <| viewInt model.avg)
            ]


viewResult : Model -> Html Msg
viewResult model =
    table [ class "table"]
        [ thead []
              [ tr []
                    [ th [] [ text "Runde"]
                    , th [] [ text "Zeit"]]
              ]
        , tbody []
            (model.durations
            |> List.reverse
            |> List.indexedMap (\ i msecs  ->
                                    tr []
                                    [ td [] [ text <| String.fromInt (i + 1) ]
                                    , td [] [text <| String.fromInt msecs]
                             ]
                        ))
        ]

viewField : Model -> Html Msg
viewField model =
    div [] [
             case (model.showPoint, model.point) of
                 (True, Just p) -> Html.map PointMsg (drawPoint p)
                 _ -> text ""
           ]
